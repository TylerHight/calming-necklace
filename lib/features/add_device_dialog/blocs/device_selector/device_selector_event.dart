import 'package:equatable/equatable.dart';
import '../../../../core/data/models/ble_device.dart';

abstract class DeviceSelectorEvent extends Equatable {
  const DeviceSelectorEvent();

  @override
  List<Object?> get props => [];
}

class StartScanning extends DeviceSelectorEvent {}

class StopScanning extends DeviceSelectorEvent {}

class DevicesUpdated extends DeviceSelectorEvent {
  final List<BleDevice> devices;

  const DevicesUpdated(this.devices);

  @override
  List<Object?> get props => [devices];
}

class SelectDevice extends DeviceSelectorEvent {
  final BleDevice? device;

  const SelectDevice(this.device);

  @override
  List<Object?> get props => [device];
}
