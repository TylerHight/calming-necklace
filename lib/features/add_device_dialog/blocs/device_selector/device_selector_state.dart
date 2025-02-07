import 'package:equatable/equatable.dart';
import 'package:calming_necklace/core/data/models/ble_device.dart';

class DeviceSelectorState extends Equatable {
  final List<BleDevice> devices;
  final BleDevice? selectedDevice;
  final bool isScanning;
  final bool isInitialLoading;
  final String? error;

  const DeviceSelectorState({
    this.devices = const [],
    this.isScanning = false,
    this.selectedDevice,
    this.error,
    this.isInitialLoading = true,
  });

  DeviceSelectorState copyWith({
    List<BleDevice>? devices,
    BleDevice? selectedDevice,
    bool? isScanning,
    String? error,
    bool? isInitialLoading,
  }) {
    return DeviceSelectorState(
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      isScanning: isScanning ?? this.isScanning,
      error: error ?? this.error,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }

  @override
  List<Object?> get props => [devices, selectedDevice, isScanning, isInitialLoading, error];
}
