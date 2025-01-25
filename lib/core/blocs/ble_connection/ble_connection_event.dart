import 'package:equatable/equatable.dart';

abstract class BleConnectionEvent extends Equatable {
  const BleConnectionEvent();

  @override
  List<Object> get props => [];
}

class ScanForDevices extends BleConnectionEvent {}

class ConnectToDevice extends BleConnectionEvent {
  final String deviceId;

  const ConnectToDevice(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class DisconnectFromDevice extends BleConnectionEvent {
  final String deviceId;

  const DisconnectFromDevice(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}