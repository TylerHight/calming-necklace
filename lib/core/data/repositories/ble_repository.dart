import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device.dart';
import '../../services/logging_service.dart';

class BleRepository {
  static final BleRepository _instance = BleRepository._internal();
  factory BleRepository() => _instance;

  final LoggingService _logger = LoggingService();
  final StreamController<List<BleDevice>> _devicesController = StreamController<List<BleDevice>>.broadcast();
  StreamSubscription<List<BleDevice>>? _deviceSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Stream<List<BleDevice>> get devices => _devicesController.stream;
  List<BleDevice> _discoveredDevices = [];

  BleRepository._internal();

  Future<void> clearDevices() async {
    _discoveredDevices.clear();
    _devicesController.add([]);
    _logger.logDebug('Cleared discovered devices');
  }

  Future<void> startScanning() async {
    try {
      _logger.logDebug('Starting Bluetooth Low Energy scan');
      await FlutterBluePlus.turnOn();
      await clearDevices();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      // Cancel any existing subscription
      _scanSubscription?.cancel();
      
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final ScanResult scanResult in results) {
          if (scanResult.device.name.isNotEmpty) {  // Only filter out unnamed devices
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
    final lowercaseName = name.toLowerCase();
    if (lowercaseName.contains('necklace') || 
        lowercaseName.contains('cn_') || 
        lowercaseName.contains('calm')) {
      return BleDeviceType.necklace;
    }
    return BleDeviceType.heartRateMonitor;
  }

  void dispose() {
    _devicesController.close();
    _scanSubscription?.cancel();
    _deviceSubscription?.cancel();
    FlutterBluePlus.stopScan();
  }
}
