// lib/core/blocs/ble/ble_event.dart
import '../../data/models/ble_device.dart';

abstract class BleEvent {}

class StartScanning extends BleEvent {}

class StopScanning extends BleEvent {}

class SelectDevice extends BleEvent {
  final BleDevice device;
  SelectDevice(this.device);
}