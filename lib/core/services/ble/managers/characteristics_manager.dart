// lib/core/services/ble/managers/characteristics_manager.dart

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble_types.dart';
import '../../../data/constants/ble_constants.dart';

class BleCharacteristicsManager {
  final ErrorCallback onError;
  final Map<String, BluetoothCharacteristic> _characteristics = {};
  bool _isInitialized = false;

  BleCharacteristicsManager({required this.onError});

  Future<void> discoverCharacteristics(BluetoothDevice device) async {
    try {
      _characteristics.clear();
      _isInitialized = false;

      final services = await device.discoverServices();
      _logServiceDiscovery(services);

      await _validateAndStoreCharacteristics(services);
      _isInitialized = true;
    } catch (e) {
      _handleDiscoveryError(e);
    }
  }

  Future<void> _validateAndStoreCharacteristics(List<BluetoothService> services) async {
    // Find required services
    final ledService = _findService(services, BleConstants.LED_SERVICE_UUID);
    final settingsService = _findService(services, BleConstants.SETTINGS_SERVICE_UUID);

    // Store required characteristics
    await _storeRequiredCharacteristics(ledService);
    await _storeOptionalCharacteristics(settingsService);
  }

  BluetoothService _findService(List<BluetoothService> services, String uuid) {
    return services.firstWhere(
          (s) => s.uuid.toString().toLowerCase() == uuid.toLowerCase(),
      orElse: () => throw BleException('${BleConstants.ERR_SERVICE_NOT_FOUND}: $uuid'),
    );
  }

  Future<void> _storeRequiredCharacteristics(BluetoothService service) async {
    // Store switch characteristic
    final switchChar = await _findAndConfigureCharacteristic(
      service,
      BleConstants.SWITCH_CHARACTERISTIC_UUID,
      required: true,
    );
    if (switchChar != null) {
      _characteristics[BleConstants.SWITCH_CHARACTERISTIC_UUID.toLowerCase()] = switchChar;
    }

    // Store keep-alive characteristic
    final keepAliveChar = await _findAndConfigureCharacteristic(
      service,
      BleConstants.KEEPALIVE_CHARACTERISTIC_UUID,
      required: true,
    );
    if (keepAliveChar != null) {
      _characteristics[BleConstants.KEEPALIVE_CHARACTERISTIC_UUID.toLowerCase()] = keepAliveChar;
    }
  }

  Future<void> _storeOptionalCharacteristics(BluetoothService service) async {
    final charConfigs = [
      (BleConstants.EMISSION1_CHARACTERISTIC_UUID, false),
      (BleConstants.INTERVAL1_CHARACTERISTIC_UUID, false),
      (BleConstants.PERIODIC1_CHARACTERISTIC_UUID, false),
    ];

    for (final config in charConfigs) {
      final char = await _findAndConfigureCharacteristic(
        service,
        config.$1,
        required: config.$2,
      );
      if (char != null) {
        _characteristics[config.$1.toLowerCase()] = char;
      }
    }
  }

  Future<BluetoothCharacteristic?> _findAndConfigureCharacteristic(
      BluetoothService service,
      String uuid,
      {required bool required}
      ) async {
    try {
      final characteristics = service.characteristics.where(
              (c) => c.uuid.toString().toLowerCase() == uuid.toLowerCase()
      ).toList();

      if (characteristics.isEmpty) {
        if (required) {
          throw BleException('${BleConstants.ERR_CHARACTERISTIC_NOT_FOUND}: $uuid');
        }
        return null;
      }

      final char = characteristics.first;
      if (char.properties.notify) {
        await char.setNotifyValue(true);
      }

      return char;
    } catch (e) {
      if (required) {
        onError('${BleConstants.ERR_CHARACTERISTIC_NOT_FOUND}: $uuid');
        throw BleException('${BleConstants.ERR_CHARACTERISTIC_NOT_FOUND}: $uuid');
      }
      return null;
    }
  }

  Future<List<int>> readCharacteristic(String uuid) async {
    _ensureInitialized();

    try {
      final char = _getCharacteristic(uuid);
      return await char.read();
    } catch (e) {
      onError('${BleConstants.ERR_CHARACTERISTIC_READ}: $e');
      rethrow;
    }
  }

  Future<void> writeCharacteristic(String uuid, List<int> data) async {
    _ensureInitialized();

    try {
      final char = _getCharacteristic(uuid);
      await char.write(data, withoutResponse: false);
    } catch (e) {
      onError('${BleConstants.ERR_CHARACTERISTIC_WRITE}: $e');
      rethrow;
    }
  }

  BluetoothCharacteristic _getCharacteristic(String uuid) {
    final normalizedUuid = uuid.toLowerCase();
    final char = _characteristics[normalizedUuid];

    if (char == null) {
      throw BleException('${BleConstants.ERR_CHARACTERISTIC_NOT_FOUND}: $uuid');
    }

    return char;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw BleException('CharacteristicsManager not initialized');
    }
  }

  void _logServiceDiscovery(List<BluetoothService> services) {
    print('\n=== BLE Service Discovery Debug ===');
    print('Total services discovered: ${services.length}');

    for (final service in services) {
      print('\nService UUID: ${service.uuid}');
      print('Characteristics in this service: ${service.characteristics.length}');

      for (final char in service.characteristics) {
        print('  Characteristic UUID: ${char.uuid}');
        print('  Properties: ${_getCharacteristicProperties(char)}');
      }
    }
  }

  String _getCharacteristicProperties(BluetoothCharacteristic char) {
    final props = <String>[];
    if (char.properties.read) props.add('Read');
    if (char.properties.write) props.add('Write');
    if (char.properties.notify) props.add('Notify');
    if (char.properties.indicate) props.add('Indicate');
    if (char.properties.authenticatedSignedWrites) props.add('AuthSignedWrites');
    if (char.properties.broadcast) props.add('Broadcast');
    if (char.properties.writeWithoutResponse) props.add('WriteNoResponse');
    return props.join(', ');
  }

  void _handleDiscoveryError(dynamic error) {
    final message = '${BleConstants.ERR_DISCOVERY}: $error';
    onError(message);
    throw BleException(message);
  }

  void dispose() {
    _characteristics.clear();
    _isInitialized = false;
  }
}
