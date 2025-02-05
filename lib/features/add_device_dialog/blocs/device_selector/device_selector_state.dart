import 'package:equatable/equatable.dart';
import 'package:calming_necklace/core/data/models/ble_device.dart';

class DeviceSelectorState extends Equatable {
  final List<BleDevice> devices;
  final BleDevice? selectedDevice;
  final bool isScanning;
  final String? error;

  const DeviceSelectorState({
    this.devices = const [],
    this.isScanning = false,
    this.selectedDevice,
    this.error,
  });

  DeviceSelectorState copyWith({
    List<BleDevice>? devices,
    BleDevice? selectedDevice,
    bool? isScanning,
    String? error,
  }) {
    return DeviceSelectorState(
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      isScanning: isScanning ?? this.isScanning,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [devices, selectedDevice, isScanning, error];
}