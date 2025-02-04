import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/models/ble_device.dart';
import '../../../../core/data/repositories/ble_repository.dart';
import '../../../../core/services/logging_service.dart';
import 'device_selector_event.dart';
import 'device_selector_state.dart';
import 'package:equatable/equatable.dart';

class DeviceSelectorBloc extends Bloc<DeviceSelectorEvent, DeviceSelectorState> {
  final BleRepository _bleRepository;
  final LoggingService _logger = LoggingService();
  StreamSubscription? _deviceSubscription;

  DeviceSelectorBloc({required BleRepository bleRepository})
      : _bleRepository = bleRepository,
        super(const DeviceSelectorState()) {
    on<StartScanning>(_onStartScanning);
    on<StopScanning>(_onStopScanning);
    on<DevicesUpdated>(_onDevicesUpdated);
    on<SelectDevice>(_onSelectDevice);
  }

  Future<void> _onStartScanning(StartScanning event, Emitter<DeviceSelectorState> emit) async {
    try {
      emit(state.copyWith(isScanning: true, error: null));
      _deviceSubscription?.cancel();
      await _bleRepository.startScanning();
      
      _deviceSubscription = _bleRepository.devices.listen(
        (devices) => add(DevicesUpdated(devices)),
      );

      // Auto-stop scanning after 10 seconds
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
      emit(state.copyWith(isScanning: false));
    } catch (e) {
      _logger.logError('Error stopping BLE scan: $e');
      emit(state.copyWith(
        isScanning: false,
        error: 'Failed to stop scanning: $e',
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
  }

  @override
  Future<void> close() {
    _deviceSubscription?.cancel();
    return super.close();
  }
}
