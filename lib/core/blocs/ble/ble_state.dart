// lib/core/blocs/ble/ble_state.dart
import '../../data/models/ble_device.dart';

class BleState {
  final bool isScanning;
  final String deviceState;
  final Map<String, bool> deviceConnectionStates;
  final int? rssi;

  BleState({
    this.isScanning = false,
    this.deviceState = '',
    this.deviceConnectionStates = const {},
    this.rssi,
  });

  factory BleState.initial() {
    return BleState(
      isScanning: false,
      deviceState: '',
      deviceConnectionStates: const {},
      rssi: 0,
    );
  }

  BleState copyWith({
    bool? isScanning,
    String? deviceState,
    Map<String, bool>? deviceConnectionStates,
    int? rssi,
  }) {
    return BleState(
      isScanning: isScanning ?? this.isScanning,
      deviceState: deviceState ?? this.deviceState,
      deviceConnectionStates: deviceConnectionStates ?? this.deviceConnectionStates,
      rssi: rssi ?? this.rssi,
    );
  }
}