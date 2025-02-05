// lib/core/blocs/ble/ble_state.dart
import '../../data/models/ble_device.dart';

class BleState {
  final bool isScanning;
  final List<BleDevice> devices;
  final BleDevice? selectedDevice;
  final int rssi;

  BleState({
    required this.isScanning,
    required this.devices,
    this.selectedDevice,
    required this.rssi,
  });

  factory BleState.initial() {
    return BleState(
      isScanning: false,
      devices: [],
      selectedDevice: null,
      rssi: 0,
    );
  }

  BleState copyWith({
    bool? isScanning,
    List<BleDevice>? devices,
    BleDevice? selectedDevice,
    int? rssi,
  }) {
    return BleState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      rssi: rssi ?? this.rssi,
    );
  }
}