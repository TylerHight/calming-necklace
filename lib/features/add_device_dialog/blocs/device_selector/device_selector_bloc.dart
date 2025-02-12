import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/models/ble_device.dart';
import '../../../../core/data/repositories/ble_repository.dart';
import '../../../../core/services/logging_service.dart';
import 'device_selector_event.dart';
import 'device_selector_state.dart';
import '../../../../core/blocs/ble/ble_bloc.dart';
import '../../../../core/blocs/ble/ble_event.dart';

class DeviceSelectorBloc extends Bloc<DeviceSelectorEvent, DeviceSelectorState> {
  final BleRepository _bleRepository;
  final BleBloc _bleBloc;
  final LoggingService _logger = LoggingService.instance;
  StreamSubscription? _deviceSubscription;

  DeviceSelectorBloc({required BleRepository bleRepository, required BleBloc bleBloc})
      : _bleRepository = bleRepository,
        _bleBloc = bleBloc,
        super(const DeviceSelectorState()) {
    on<StartScanning>(_onStartScanning);
    on<StopScanning>(_onStopScanning);
    on<DevicesUpdated>(_onDevicesUpdated);
    on<SelectDevice>(_onSelectDevice);
  }

  Future<void> _onStartScanning(StartScanning event, Emitter<DeviceSelectorState> emit) async {
    try {
      emit(state.copyWith(isScanning: true, error: null, isInitialLoading: false));
      _deviceSubscription?.cancel();
      _logger.logDebug('Starting BLE scan for devices');
      await _bleRepository.startScanning();
      
      _deviceSubscription = _bleRepository.devices.listen(
        (devices) => add(DevicesUpdated(devices)),
      );

      // Auto-stop scanning after 10 seconds
      _logger.logDebug('Setting up auto-stop timer for scan');
      await Future.delayed(const Duration(seconds: 10));
      if (!isClosed) {
        add(StopScanning());
      }
    } catch (e) {
      _logger.logError('Error starting BLE scan: $e');
      emit(state.copyWith(
        isScanning: false,
        error: 'Failed to start scanning: $e',
      ));
    }
  }

  Future<void> _onStopScanning(StopScanning event, Emitter<DeviceSelectorState> emit) async {
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

  void _onDevicesUpdated(DevicesUpdated event, Emitter<DeviceSelectorState> emit) {
    emit(state.copyWith(
      devices: event.devices,
      error: null,
    ));
  }

  void _onSelectDevice(SelectDevice event, Emitter<DeviceSelectorState> emit) {
    emit(state.copyWith(selectedDevice: event.device));
    // Attempt to connect immediately when device is selected
    _bleBloc.add(BleConnectRequest(event.device));
  }

  @override
  Future<void> close() {
    _deviceSubscription?.cancel();
    return super.close();
  }
}
