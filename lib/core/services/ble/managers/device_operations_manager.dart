// lib/core/services/ble/managers/device_operations_manager.dart

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble_types.dart';
import '../ble_commands.dart';
import '../../../data/constants/ble_constants.dart';

class DeviceOperationsManager {
  final ErrorCallback onError;
  final BluetoothCharacteristic? _switchCharacteristic;

  DeviceOperationsManager({
    required this.onError,
    BluetoothCharacteristic? switchCharacteristic,
  }) : _switchCharacteristic = switchCharacteristic;

  Future<void> setLedColor(int colorCommand) async {
    if (!_isValidCommand(colorCommand)) {
      throw BleException('Invalid LED command');
    }
    await _writeCommand(colorCommand);
  }

  bool _isValidCommand(int command) {
    return BleCommand.values.any((cmd) => cmd.value == command);
  }

  Future<void> updateEmission1Duration(String deviceId, Duration duration) async {
    await _writeCommand(BleCommand.emission1Duration.value, duration.inSeconds);
  }

  Future<void> updateInterval1(String deviceId, Duration interval) async {
    await _writeCommand(BleCommand.interval1.value, interval.inSeconds);
  }

  Future<void> updatePeriodicEmission1(String deviceId, bool enabled) async {
    await _writeCommand(BleCommand.periodic1.value, enabled ? 1 : 0);
  }

  Future<void> _writeCommand(int command, [int? value]) async {
    if (_switchCharacteristic == null) {
      throw BleException(BleConstants.ERR_CHARACTERISTIC_NOT_FOUND);
    }

    final data = value != null ? [command, value] : [command];
    await _switchCharacteristic!.write(data);
  }

  void cleanup() {
    // Add any cleanup code here if needed
  }

  void dispose() {
    cleanup();
  }
}
