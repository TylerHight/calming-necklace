import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/models/ble_device.dart';

abstract class DeviceSelectorEvent extends Equatable {
  const DeviceSelectorEvent();

  @override
  List<Object> get props => [];
}

class SelectDeviceEvent extends DeviceSelectorEvent {
  final BleDevice device;

  const SelectDeviceEvent(this.device);

  @override
  List<Object> get props => [device];
}

abstract class DeviceSelectorState extends Equatable {
  const DeviceSelectorState();

  @override
  List<Object> get props => [];
}

class DeviceSelectorInitial extends DeviceSelectorState {}

class DeviceSelected extends DeviceSelectorState {
  final BleDevice device;

  const DeviceSelected(this.device);

  @override
  List<Object> get props => [device];
}
