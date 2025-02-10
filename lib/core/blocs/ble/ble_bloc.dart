import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/ble/ble_service.dart';
import 'ble_event.dart';
import 'ble_state.dart';

class BleBloc extends Bloc<BleEvent, BleState> {
  final BleService _bleService;
  StreamSubscription<String>? _deviceStateSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;
  StreamSubscription<int>? _rssiSubscription;
  StreamSubscription<int>? _reconnectionAttemptsSubscription;

  BleBloc({required BleService bleService})
      : _bleService = bleService,
        super(BleState.initial()) {
    on<BleConnectRequest>(_onConnectRequest);
    on<BleDisconnectRequest>(_onDisconnectRequest);
    on<BleConnectionStatusChanged>((event, emit) => _onConnectionStatusChanged(event.isConnected));
    on<BleRssiUpdated>((event, emit) => _onRssiUpdate(event.rssi));
    on<BleReconnectionAttempt>((event, emit) => _onReconnectionAttempt(event.attempt));

    _deviceStateSubscription = _bleService.deviceStateStream.listen(_onDeviceStateChanged);
    _connectionStatusSubscription = _bleService.connectionStatusStream.listen(_onConnectionStatusChanged);
    _reconnectionAttemptsSubscription = _bleService.reconnectionAttemptsStream.listen(_onReconnectionAttempt);
    _rssiSubscription = _bleService.rssiStream.listen(_onRssiUpdate);
  }

  Future<void> _onConnectRequest(BleConnectRequest event, Emitter<BleState> emit) async {
    if (state.isConnecting) return;

    emit(state.copyWith(isConnecting: true, error: null));
    try {
      final deviceId = event.device.id;
      final connected = await _bleService.connectToDevice(event.device.device!);

      if (connected) {
        final updatedStates = Map<String, bool>.from(state.deviceConnectionStates);
        updatedStates[deviceId] = true;
        emit(state.copyWith(
          deviceConnectionStates: updatedStates,
          isConnecting: false,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          isConnecting: false,
          error: 'Failed to connect to device',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isConnecting: false,
        error: 'Connection error: ${e.toString()}',
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

  @override
  Future<void> close() {
    _deviceStateSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _reconnectionAttemptsSubscription?.cancel();
    _rssiSubscription?.cancel();
    return super.close();
  }
}
