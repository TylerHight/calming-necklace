import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device.dart';
import '../../services/logging_service.dart';

class BleRepository {
  static final BleRepository _instance = BleRepository._internal();
  factory BleRepository() => _instance;

  final LoggingService _logger = LoggingService();
  final StreamController<List<BleDevice>> _devicesController = StreamController<List<BleDevice>>.broadcast();

  Stream<List<BleDevice>> get devices => _devicesController.stream;
  List<BleDevice> _discoveredDevices = [];

  BleRepository._internal();

  Future<void> startScanning() async {
    try {
      _logger.logDebug('Starting Bluetooth Low Energy scan');
      _discoveredDevices.clear();

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult scanResult in results) {
          final device = BleDevice(
            id: scanResult.device.id.id,
            name: scanResult.device.name.isEmpty ? 'Unknown Device' : scanResult.device.name,
            address: scanResult.device.id.id,
            rssi: scanResult.rssi,
            deviceType: _determineDeviceType(scanResult.device.name),
          );

          if (!_discoveredDevices.any((discoveredDevice) => discoveredDevice.id == device.id)) {
            _discoveredDevices.add(device);
            _devicesController.add(_discoveredDevices);
          }
        }
      });
    } catch (exception) {
      _logger.logError('Error scanning for Bluetooth Low Energy devices: $exception');
      rethrow;
    }
  }

  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
      _logger.logDebug('Stopped Bluetooth Low Energy scan');
    } catch (exception) {
      _logger.logError('Error stopping Bluetooth Low Energy scan: $exception');
      rethrow;
    }
  }

  BleDeviceType _determineDeviceType(String name) {
    // Add logic to determine device type based on name or other characteristics
    if (name.toLowerCase().contains('necklace')) {
      return BleDeviceType.necklace;
    }
    return BleDeviceType.heartRateMonitor;
  }

  void dispose() {
    _devicesController.close();
  }
}
