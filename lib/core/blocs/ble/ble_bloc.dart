import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/ble_device.dart';
import '../../data/repositories/ble_repository.dart';
import '../../services/ble/ble_service.dart';
import '../../services/logging_service.dart';
import 'ble_event.dart';
import 'ble_state.dart';

class BleBloc extends Bloc<BleEvent, BleState> {
  final BleService _bleService;
  final BleRepository _bleRepository;
  final LoggingService _logger = LoggingService.instance;
  StreamSubscription<String>? _deviceStateSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;
  StreamSubscription<int>? _rssiSubscription;
  StreamSubscription<int>? _reconnectionAttemptsSubscription;
  StreamSubscription<List<BleDevice>>? _deviceSubscription;

  BleBloc({required BleService bleService, required BleRepository bleRepository})
      : _bleService = bleService,
        _bleRepository = bleRepository,
        super(BleState.initial()) {
    on<BleConnectRequest>(_onConnectRequest);
    on<BleDisconnectRequest>(_onDisconnectRequest);
    on<BleConnectionStatusChanged>((event, emit) => _onConnectionStatusChanged(event.isConnected));
    on<BleRssiUpdated>((event, emit) => _onRssiUpdate(event.rssi));
    on<BleReconnectionAttempt>((event, emit) => _onReconnectionAttempt(event.attempt));
    on<BleLedControlRequest>(_onLedControlRequest);
    on<BleStartScanning>(_onStartScanning);
    on<BleStopScanning>(_onStopScanning);

    _deviceStateSubscription = _bleService.deviceStateStream.listen(_onDeviceStateChanged);
    _connectionStatusSubscription = _bleService.connectionStatusStream.listen(_onConnectionStatusChanged);
    _reconnectionAttemptsSubscription = _bleService.reconnectionAttemptsStream.listen(_onReconnectionAttempt);
    _rssiSubscription = _bleService.rssiStream.listen(_onRssiUpdate);
  }

  Future<void> _onStartScanning(BleStartScanning event, Emitter<BleState> emit) async {
    try {
      _logger.logBleInfo('Starting BLE scan for devices');
      emit(state.copyWith(isScanning: true, error: null));

      await _bleRepository.startScanning();

      _deviceSubscription = _bleRepository.devices.listen(
            (devices) {
          for (final device in devices) {
            if (device.device != null) {
              _tryConnectDevice(device, emit);
            }
          }
          emit(state.copyWith(devices: devices));
        },
      );

      // Auto-stop scanning after 10 seconds
      _logger.logDebug('Setting up auto-stop timer for scan');
      await Future.delayed(const Duration(seconds: 10));
      if (!isClosed) {
        await _bleRepository.stopScanning();
        emit(state.copyWith(isScanning: false));
      }
    } catch (e) {
      _logger.logBleError('Error starting BLE scan', e);
      emit(state.copyWith(
        isScanning: false,
        error: 'Failed to start scanning: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStopScanning(BleStopScanning event, Emitter<BleState> emit) async {
    try {
      await _bleRepository.stopScanning();
      _deviceSubscription?.cancel();
      _logger.logDebug('Stopped BLE scan');
      emit(state.copyWith(isScanning: false));
    } catch (e) {
      _logger.logError('Error stopping BLE scan: $e');
      emit(state.copyWith(
        isScanning: false,
        error: 'Failed to stop scanning. Please try again.',
      ));
    }
  }

  Future<void> _onConnectRequest(BleConnectRequest event, Emitter<BleState> emit) async {
    if (state.isConnecting) return;

    emit(state.copyWith(isConnecting: true, error: null, selectedDevice: event.device));
    try {
      final deviceId = event.device.id;
      _logger.logBleInfo('Attempting to connect and initialize device: $deviceId');
      await _bleService.connectAndInitializeDevice(event.device.device!);
      final updatedStates = Map<String, bool>.from(state.deviceConnectionStates);
      updatedStates[deviceId] = true;
      _logger.logBleInfo('Successfully connected and initialized device: $deviceId');
      emit(state.copyWith(
        deviceConnectionStates: updatedStates,
        isConnecting: false,
        error: null,
      ));
    } catch (e) {
      _logger.logBleError('Connection and initialization error for device: ${event.device.id}', e);
      emit(state.copyWith(
        isConnecting: false,
        error: 'Connection and initialization error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDisconnectRequest(BleDisconnectRequest event, Emitter<BleState> emit) async {
    try {
      await _bleService.disconnectFromDevice();
      final updatedStates = Map<String, bool>.from(state.deviceConnectionStates);
      updatedStates[event.deviceId] = false;
      emit(state.copyWith(deviceConnectionStates: updatedStates));
    } catch (e) {
      _logger.logBleError('Disconnect error: ${e.toString()}', e);
      emit(state.copyWith(error: 'Disconnect error: ${e.toString()}'));
    }
  }

  void _onDeviceStateChanged(String state) {
    emit(this.state.copyWith(
      deviceState: state,
    ));
  }

  void _onConnectionStatusChanged(bool isConnected) {
    if (_bleService.connectedDevice != null) {
      final deviceId = _bleService.connectedDevice!.id.toString();
      final updatedStates = Map<String, bool>.from(state.deviceConnectionStates);
      updatedStates[deviceId] = isConnected;
      emit(state.copyWith(deviceConnectionStates: updatedStates));
    }
  }

  void _onReconnectionAttempt(int attempts) {
    if (_bleService.connectedDevice != null) {
      final deviceId = _bleService.connectedDevice!.id.toString();
      final updatedAttempts = Map<String, int>.from(state.reconnectionAttempts);
      updatedAttempts[deviceId] = attempts;
      emit(state.copyWith(reconnectionAttempts: updatedAttempts));
    }
  }

  void _onRssiUpdate(int rssi) {
    emit(state.copyWith(rssi: rssi));
  }

  Future<void> _onLedControlRequest(BleLedControlRequest event, Emitter<BleState> emit) async {
    try {
      _logger.logBleInfo('LED control request: ${event.turnOn ? 'ON' : 'OFF'}');
      if (!await _bleService.isDeviceConnected(event.deviceId)) throw Exception('Device not connected');
      await _bleService.setLedState(event.turnOn);
      emit(state.copyWith(
        error: null,
        lastCommand: event.turnOn ? 'LED ON' : 'LED OFF',
      ));
    } catch (e) {
      _logger.logBleError('LED control error', e);
      emit(state.copyWith(
        error: 'LED control error: ${e.toString()}',
      ));
    }
  }

  Future<bool> toggleLight(String deviceId, bool turnOn) async {
    try {
      _logger.logBleInfo('LED control request: ${turnOn ? 'ON' : 'OFF'}');
      if (!await _bleService.isDeviceConnected(deviceId)) throw Exception('Device not connected');
      add(BleLedControlRequest(deviceId: deviceId, turnOn: turnOn));
      
      await _bleService.setLedState(turnOn);
      emit(state.copyWith(
        error: null,
        lastCommand: turnOn ? 'LED ON' : 'LED OFF',
      ));
      return true;
    } catch (e) {
      _logger.logBleError('LED control error', e);
      emit(state.copyWith(
        error: 'LED control error: ${e.toString()}',
      ));
      return false;
    }
  }

  Future<void> _tryConnectDevice(BleDevice device, Emitter<BleState> emit) async {
    try {
      if (device.device != null && !state.deviceConnectionStates.containsKey(device.id)) {
        _logger.logBleInfo('Attempting to connect to discovered device: ${device.id}');
        await _bleService.connectAndInitializeDevice(device.device!);
        
        final updatedStates = Map<String, bool>.from(state.deviceConnectionStates);
        updatedStates[device.id] = true;
        emit(state.copyWith(deviceConnectionStates: updatedStates));
      }
    } catch (e) {
      _logger.logBleError('Failed to connect to discovered device: ${device.id}', e);
      // Don't emit error state here to allow scanning to continue
    }
  }

  @override
  Future<void> close() {
    _deviceStateSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _reconnectionAttemptsSubscription?.cancel();
    _rssiSubscription?.cancel();
    return super.close();
  }
}
