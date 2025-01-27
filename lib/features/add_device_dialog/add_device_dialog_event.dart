part of 'add_device_dialog_bloc.dart';

abstract class AddDeviceDialogEvent extends Equatable {
  const AddDeviceDialogEvent();

  @override
  List<Object> get props => [];
}

class SubmitAddDeviceEvent extends AddDeviceDialogEvent {
  final String name;
  final String bleDevice;

  const SubmitAddDeviceEvent(this.name, this.bleDevice);

  @override
  List<Object> get props => [name, bleDevice];
}