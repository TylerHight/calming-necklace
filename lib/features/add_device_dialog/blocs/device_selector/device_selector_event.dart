part of 'device_selector_bloc.dart';

abstract class DeviceSelectorEvent extends Equatable {
  const DeviceSelectorEvent();

  @override
  List<Object> get props => [];
}

class DeviceSelectorSelectDeviceEvent extends DeviceSelectorEvent {
  final BleDevice device;

  const DeviceSelectorSelectDeviceEvent(this.device);

  @override
  List<Object> get props => [device];
}
