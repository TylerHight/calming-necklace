import 'package:equatable/equatable.dart';

abstract class BleConnectionState extends Equatable {
  const BleConnectionState();

  @override
  List<Object> get props => [];
}

class BleConnectionInitial extends BleConnectionState {}

class BleScanning extends BleConnectionState {}

class BleConnected extends BleConnectionState {
  final String deviceId;

  const BleConnected(this.deviceId);

  @override
  List<Object> get props => [deviceId];
}

class BleDisconnected extends BleConnectionState {}