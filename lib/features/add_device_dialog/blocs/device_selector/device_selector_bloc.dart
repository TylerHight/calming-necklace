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
    on<DevicesUpdated>(_onDevicesUpdated);
    on<SelectDevice>(_onSelectDevice);
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
