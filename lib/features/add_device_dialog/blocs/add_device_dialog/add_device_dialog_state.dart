import 'package:equatable/equatable.dart';
import '../../../../../core/data/models/ble_device.dart';

abstract class AddDeviceDialogState extends Equatable {
  const AddDeviceDialogState();

  @override
  List<Object> get props => [];
}

class AddDeviceDialogInitial extends AddDeviceDialogState {}

class AddDeviceDialogLoading extends AddDeviceDialogState {}

class AddDeviceDialogSuccess extends AddDeviceDialogState {}

class AddDeviceDialogError extends AddDeviceDialogState {
  final String error;

  const AddDeviceDialogError(this.error);

  @override
  List<Object> get props => [error];
}

class ConnectionInProgress extends AddDeviceDialogState {
  final String deviceName;

  const ConnectionInProgress(this.deviceName);

  @override
  List<Object> get props => [deviceName];
}

class ScanningForDevices extends AddDeviceDialogState {}

class DevicesFound extends AddDeviceDialogState {
  final List<BleDevice> devices;
  const DevicesFound(this.devices);
  
  @override
  List<Object> get props => [devices];
}

class DeviceSelected extends AddDeviceDialogState {
  final BleDevice device;
  const DeviceSelected(this.device);
  
  @override
  List<Object> get props => [device];
}
