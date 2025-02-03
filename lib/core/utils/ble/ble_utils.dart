import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/constants/ble_constants.dart';

class BleUtils {
  static final BleUtils _instance = BleUtils._internal();
  factory BleUtils() => _instance;
  BleUtils._internal();

  Future<bool> isBluetoothEnabled() async {
    if (!await FlutterBluePlus.isSupported) {
      return false;
    }
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Future<void> enableBluetooth() async {
    if (await FlutterBluePlus.isSupported) {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }
    }
  }

  Future<List<BluetoothDevice>> startScan({
    Duration timeout = const Duration(seconds: 4),
    List<Guid>? withServices,
    bool Function(BluetoothDevice)? filter,
  }) async {
    try {
      if (!await isBluetoothEnabled()) {
        await enableBluetooth();
      }

      await FlutterBluePlus.stopScan();

      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: withServices ?? [],
        androidScanMode: AndroidScanMode.lowLatency,
      );

      final results = await FlutterBluePlus.scanResults.first;
      final devices = results
          .where((r) => r.device.platformName.startsWith(BleConstants.DEVICE_NAME_PREFIX))
          .where((r) => r.rssi >= BleConstants.MIN_RSSI_THRESHOLD)
          .map((r) => r.device)
          .toList();

      if (filter != null) {
        return devices.where(filter).toList();
      }
      return devices;
    } catch (e) {
      throw Exception('Scan failed: $e');
    } finally {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<bool> checkDeviceConnected(BluetoothDevice device) async {
    try {
      final state = await device.connectionState.first;
      return state == BluetoothConnectionState.connected;
    } catch (e) {
      return false;
    }
  }

  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      return services;
    } catch (e) {
      throw Exception('Failed to discover services: $e');
    }
  }

  String getDeviceIdentifier(BluetoothDevice device) {
    return device.remoteId.str;
  }

  static String normalizeUUID(String uuid) {
    uuid = uuid.toLowerCase().replaceAll('-', '');
    if (uuid.length == 4) {
      return "0000$uuid-0000-1000-8000-00805f9b34fb";
    }
    return uuid;
  }

  static bool isValidServiceUuid(String uuid) {
    try {
      Guid(normalizeUUID(uuid));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Stream<List<int>>> setupNotifications(
      BluetoothDevice device,
      String serviceUuid,
      String characteristicUuid,
      ) async {
    final characteristic = await findCharacteristic(
      device,
      serviceUuid,
      characteristicUuid,
    );

    if (characteristic == null) {
      throw Exception('Characteristic not found');
    }

    await characteristic.setNotifyValue(true);
    return characteristic.lastValueStream;
  }

  Future<BluetoothCharacteristic?> findCharacteristic(
      BluetoothDevice device,
      String serviceUuid,
      String characteristicUuid,
      ) async {
    final services = await discoverServices(device);

    for (final service in services) {
      if (service.uuid.toString().toLowerCase() ==
          normalizeUUID(serviceUuid).toLowerCase()) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              normalizeUUID(characteristicUuid).toLowerCase()) {
            return characteristic;
          }
        }
      }
    }
    return null;
  }
}
