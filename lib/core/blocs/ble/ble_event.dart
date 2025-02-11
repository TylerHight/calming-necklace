import 'package:equatable/equatable.dart';
import '../../../core/data/models/ble_device.dart';

abstract class BleEvent extends Equatable {
  const BleEvent();

  @override
  List<Object?> get props => [];
}

class BleConnectRequest extends BleEvent {
  final BleDevice device;
  const BleConnectRequest(this.device);

  @override
  List<Object?> get props => [device];
}

class BleDisconnectRequest extends BleEvent {
  final String deviceId;
  const BleDisconnectRequest(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class BleConnectionStatusChanged extends BleEvent {
  final bool isConnected;
  final String deviceId;
  const BleConnectionStatusChanged(this.isConnected, this.deviceId);

  @override
  List<Object?> get props => [isConnected, deviceId];
}

class BleRssiUpdated extends BleEvent {
  final int rssi;
  final String deviceId;
  const BleRssiUpdated(this.rssi, this.deviceId);

  @override
  List<Object?> get props => [rssi, deviceId];
}

class BleReconnectionAttempt extends BleEvent {
  final int attempt;
  final String deviceId;
  const BleReconnectionAttempt(this.attempt, this.deviceId);

  @override
  List<Object?> get props => [attempt, deviceId];
}

class BleLedControlRequest extends BleEvent {
  final String deviceId;
  final bool turnOn;

  const BleLedControlRequest({
    required this.deviceId,
    required this.turnOn,
  });

  @override
  List<Object?> get props => [deviceId, turnOn];
}