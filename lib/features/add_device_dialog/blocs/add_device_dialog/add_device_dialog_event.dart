import 'package:equatable/equatable.dart';
import '../../../../core/data/models/ble_device.dart';

abstract class AddDeviceDialogEvent extends Equatable {
  const AddDeviceDialogEvent();

  @override
  List<Object?> get props => [];
}

class SubmitAddDeviceEvent extends AddDeviceDialogEvent {
  final String name;
  final BleDevice? device;

  const SubmitAddDeviceEvent(this.name, this.device);

  @override
  List<Object?> get props => [name, device];
}

class StartScanningEvent extends AddDeviceDialogEvent {}

class StopScanningEvent extends AddDeviceDialogEvent {}

class SelectDeviceEvent extends AddDeviceDialogEvent {
  final BleDevice device;
  const SelectDeviceEvent(this.device);

  @override
  List<Object?> get props => [device];
}
