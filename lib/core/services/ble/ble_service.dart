import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/models/ble_device.dart';
import '../database_service.dart';
import '../logging_service.dart';
import 'managers/ble_connection_manager.dart';
import 'ble_types.dart';
import 'ble_commands.dart';
import '../../../core/utils/ble/ble_utils.dart';
import '../../../core/data/constants/ble_constants.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;

  late final BleConnectionManager _connectionManager;
  DateTime? _lastCommandTime;
  static const _commandDebounceTime = Duration(milliseconds: 500);
  final Map<String, Completer<void>> _pendingCommands = {};
  final _bleUtils = BleUtils();
  late final LoggingService _logger;
  final _deviceStateController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _rssiController = StreamController<int>.broadcast();
  final _reconnectionAttemptsController = StreamController<int>.broadcast();
  final _connectionQualityController = StreamController<double>.broadcast();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _switchCharacteristic;
  bool _isInitialized = false;
  Timer? _rssiTimer;

  Stream<String> get deviceStateStream => _deviceStateController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<int> get rssiStream => _rssiController.stream;
  Stream<int> get reconnectionAttemptsStream => _reconnectionAttemptsController.stream;
  Stream<double> get connectionQualityStream => _connectionQualityController.stream;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BleService._internal() {
    LoggingService.getInstance().then((logger) => _logger = logger);
    print('Initializing BLE Service');
    _initializeConnectionManager();
  }

  Future<bool> isDeviceConnected(String deviceId) async {
    try {
      if (_connectedDevice == null) return false;
      final state = await _connectedDevice!.connectionState.first;
      return state == BluetoothConnectionState.connected;
    } catch (e) {
      _logger.logBleError('Error checking device connection', e);
      return false;
    }
  }

  void _initializeConnectionManager() {
    _connectionManager = BleConnectionManager(
      onStateChange: _handleConnectionStateChange,
      onReconnectionAttempt: _handleReconnectionAttempt,
      onError: _handleError,
    );
  }

  void _handleConnectionStateChange(BleConnectionState state) {
    final isConnected = state == BleConnectionState.connected;
    _connectionStatusController.add(isConnected);

    switch (state) {
      case BleConnectionState.connected:
        _deviceStateController.add('Connected');
        _startRssiUpdates();
        break;
      case BleConnectionState.disconnected:
        _connectedDevice = null;
        _switchCharacteristic = null;
        _deviceStateController.add('Disconnected');
        _stopRssiUpdates();
        break;
      case BleConnectionState.connecting:
        _deviceStateController.add('Connecting...');
        break;
      case BleConnectionState.disconnecting:
        _deviceStateController.add('Disconnecting...');
        break;
      case BleConnectionState.keepAliveFailure:
        _deviceStateController.add('Connection unstable');
        break;
    }
  }

  void _handleReconnectionAttempt(int attempt) {
    _reconnectionAttemptsController.add(attempt);
  }

  void _handleError(String error) {
    _deviceStateController.add('Error: $error');
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _logger.logBleInfo('Attempting to connect to ${device.platformName}');
      _deviceStateController.add('Connecting...');

      final connected = await _connectionManager.connectWithRetry(device);
      if (connected) {
        _logger.logBleInfo('Successfully connected to ${device.platformName}');
        _connectedDevice = device;
        return true;
      } else {
        _logger.logBleError('Connection failed with ${device.platformName}');
        throw BleException('Unable to establish connection. Please ensure the device is powered on and nearby.');
      }
    } catch (e, stackTrace) {
      _logger.logBleError('Connection error', e, stackTrace);
      _deviceStateController.add('Connection failed');
      _connectionStatusController.add(false);
      return false;
    }
  }

  void _startRssiUpdates() {
    _rssiTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_connectedDevice != null) {
        try {
          final rssi = await _connectedDevice!.readRssi();
          _rssiController.add(rssi);
        } catch (e) {
          _logger.logBleError('Failed to read RSSI', e);
        }
      }
    });
  }

  void _stopRssiUpdates() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  Future<void> disconnectFromDevice([String? deviceId]) async {
    // If a specific device ID is provided, verify it matches the currently connected device
    if (deviceId != null && _connectedDevice != null && 
        _connectedDevice!.id.id != deviceId) {
      _logger.logBleError('Disconnect error: Invalid argument (key): Key not in map.: "$deviceId"');
      _logger.logBleWarning('Attempted to disconnect from device $deviceId but currently connected to ${_connectedDevice!.id.id}');
      return;
    }
    
    if (_connectedDevice != null) {
      try {
        _logger.logBleInfo('Attempting to disconnect from device: ${_connectedDevice!.id.id}');
        await _connectionManager.disconnect();
        _connectedDevice = null;
        _switchCharacteristic = null;
        _isInitialized = false; // Ensure characteristics can be re-initialized
        _stopRssiUpdates();
        _logger.logBleInfo('Successfully disconnected from device');
      } catch (e) {
        _logger.logBleError('Disconnect error: $e');
        _deviceStateController.add('Disconnect error: $e');
        rethrow;
      }
    } else {
      _logger.logBleWarning('Disconnect called but no device is currently connected');
    }
  }

  Future<List<BleServiceInfo>> _initializeCharacteristics(BluetoothDevice device, {bool forceRediscovery = false}) async {
    if (_isInitialized && !forceRediscovery) return [];

    try {
      _logger.logBleInfo('Starting service and characteristic discovery for device: ${device.id}');
      final services = await device.discoverServices();
      
      // Find the LED service and characteristic
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == BleConstants.LED_SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == BleConstants.switchCharacteristicUuid.toLowerCase()) {
              _switchCharacteristic = char;
              _logger.logBleDebug('Found LED characteristic: ${char.uuid}');
              break;
            }
          }
        }
      }

      _logger.logBleDebug('Discovered ${services.length} services for device: ${device.id}');

      List<BleServiceInfo> discoveredServices = [];
      final databaseService = DatabaseService();

      for (var service in services) {
        _logger.logBleDebug('Service UUID: ${service.uuid}');
        List<BleCharacteristicInfo> characteristics = [];

        for (var char in service.characteristics) {
          characteristics.add(BleCharacteristicInfo(
            uuid: char.uuid.toString(),
            properties: [
              if (char.properties.read) 'read',
              if (char.properties.write) 'write',
              if (char.properties.notify) 'notify',
              if (char.properties.indicate) 'indicate',
            ],
          ));
        }

        discoveredServices.add(BleServiceInfo(
          uuid: service.uuid.toString(),
          characteristics: characteristics,
        ));
      }

      // Save the discovered services to the database
      await databaseService.saveDeviceServices(device.id.id, discoveredServices);
      _logger.logBleInfo('Saved ${discoveredServices.length} services to database for device: ${device.id}');

      _isInitialized = true;
      _logger.logBleInfo('Service and characteristic discovery completed for device: ${device.id}');

      return discoveredServices;
    } catch (e) {
      _logger.logBleError('Error initializing characteristics for device: ${device.id}', e);
      rethrow;
    }
  }

  Future<List<BleServiceInfo>> discoverServices(BluetoothDevice device) async {
    try {
      _logger.logBleInfo('Starting service discovery for device: ${device.id}');
      final services = await device.discoverServices();

      List<BleServiceInfo> discoveredServices = [];
      final databaseService = DatabaseService();

      for (var service in services) {
        List<BleCharacteristicInfo> characteristics = [];

        for (var char in service.characteristics) {
          characteristics.add(BleCharacteristicInfo(
            uuid: char.uuid.toString(),
            properties: [
              if (char.properties.read) 'read',
              if (char.properties.write) 'write',
              if (char.properties.notify) 'notify',
              if (char.properties.indicate) 'indicate',
            ],
          ));
        }

        discoveredServices.add(BleServiceInfo(
          uuid: service.uuid.toString(),
          characteristics: characteristics,
        ));
      }

      // Save the discovered services to the database
      await databaseService.saveDeviceServices(device.id.id, discoveredServices);
      _logger.logBleInfo('Saved ${discoveredServices.length} services to database for device: ${device.id}');

      return discoveredServices;
    } catch (e) {
      _logger.logBleError('Error discovering services', e);
      rethrow;
    }
  }

  Future<void> connectAndInitializeDevice(BluetoothDevice device) async {
    final connected = await connectToDevice(device);
    if (connected) {
      final services = await discoverServices(device);
      _connectedDevice = device;

      // Log discovered services
      _logger.logBleInfo('Discovered services for device ${device.name}:');
      for (var service in services) {
        _logger.logBleInfo('Service UUID: ${service.uuid}');
        // Add null check for characteristics
        if (service.characteristics != null) {
          for (var char in service.characteristics!) {
            _logger.logBleInfo('  Characteristic UUID: ${char.uuid}');
            _logger.logBleInfo('    Properties: ${char.properties.join(", ")}');
          }
        }
      }

      // Create updated BleDevice
      final bleDevice = BleDevice(
        id: device.id.id,
        name: device.name,
        address: device.id.id,
        rssi: await device.readRssi(),
        deviceType: BleDeviceType.necklace,
        device: device,
      );
      
      // Save the device info to database
      final databaseService = DatabaseService();
      final db = await databaseService.database;
      
      // Check if this device is already associated with a necklace
      final necklaces = await db.query(
        'necklaces',
        where: 'bleDevice LIKE ?',
        whereArgs: ['%${device.id.id}%'],
      );
      
      if (necklaces.isNotEmpty) {
        await db.update(
          'necklaces',
          {'bleDevice': jsonEncode(bleDevice.toMap())},
          where: 'bleDevice LIKE ?',
          whereArgs: ['%${device.id.id}%'],
        );
      }

      await _initializeCharacteristics(device);
    }
  }

  /// Ensures that a device is connected before performing operations
  /// Returns true if connected successfully, false otherwise
  Future<bool> ensureConnected() async {
    try {
      // If we already have a connected device, check if it's still connected
      if (_connectedDevice != null) {
        final isConnected = await isDeviceConnected(_connectedDevice!.id.id);
        if (isConnected) {
          return true;
        }
        
        // If not connected, try to reconnect
        _logger.logBleInfo('Device disconnected. Attempting to reconnect...');
        return await connectToDevice(_connectedDevice!);
      }
      
      _logger.logBleWarning('No device to connect to');
      return false;
    } catch (e) {
      _logger.logBleError('Error ensuring connection', e);
      return false;
    }
  }

  Future<void> setLedColor(int command, [int? value]) async {
    await ensureConnected();
    try {
      if (command < 0 || command > BleCommand.periodic1.value) {
        throw BleException('Invalid LED command');
      }
      
      // Verify connection before sending command
      if (!await isDeviceConnected(_connectedDevice?.id.toString() ?? "")) {
        _connectionStatusController.add(false);
        throw BleException('Device connection lost');
      }
      
      // For LED on/off commands, the value parameter is typically not needed
      // For setting commands (like durations, intervals), the value is required
      final cmd = BleCommand.values.firstWhere((c) => c.value == command, 
                                             orElse: () => throw BleException('Unknown command'));
      
      if (cmd.isSettingCommand && value == null) {
        throw BleException('Value parameter required for setting command');
      }
      
      await _writeCommand(command, value!);
      _logger.logDebug('Command $command sent with value: $value');
    } catch (e) {
      _logger.logBleError('Failed to set LED color or setting: $e');
      rethrow;
    }
  }

  Future<void> setLedState(bool turnOn) async {
    await ensureConnected();
    _logger.logDebug('Sending setLedState command: ${turnOn ? 'ON' : 'OFF'}');
    try {
      if (_switchCharacteristic == null) {
        _logger.logBleError('LED characteristic not initialized');
        await _initializeCharacteristics(_connectedDevice!, forceRediscovery: true);
        if (_switchCharacteristic == null) {
          throw BleException('Failed to initialize LED characteristic');
        }
      }

      await _writeCommand(turnOn ? BleCommand.ledOn.value : BleCommand.ledOff.value, 0);
      _logger.logDebug('LED state command sent successfully');
      return;
    } catch (e) {
      _logger.logBleError('Failed to set LED state: ${e.toString()} - Attempting recovery', e);
      await _attemptCommandRecovery(turnOn);
      rethrow;
    }
  }

  Future<void> _attemptCommandRecovery(bool desiredState) async {
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 500);
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        _logger.logBleInfo('Command recovery attempt ${attempt + 1} of $maxRetries');
        
        // Verify connection status
        if (!await isDeviceConnected(_connectedDevice?.id.toString() ?? "")) {
          await _connectionManager.attemptRecovery(_connectedDevice!);
        }

        // Wait for connection to stabilize
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));

        // Re-initialize characteristics if needed
        if (!_isInitialized || _switchCharacteristic == null) {
          await _initializeCharacteristics(_connectedDevice!, forceRediscovery: true);
        }

        // Attempt command again
        await _writeCommand(
          desiredState ? BleCommand.ledOn.value : BleCommand.ledOff.value, 
          0
        );

        _logger.logBleInfo('Command recovery successful on attempt ${attempt + 1}');
        return;
      } catch (e) {
        attempt++;
        _logger.logBleError('Recovery attempt $attempt failed', e);
        await Future.delayed(baseDelay * attempt);
      }
    }
    
    throw BleException('Command recovery failed after $maxRetries attempts');
  }

  // Device Settings Methods
  Future<void> updateEmission1Duration(String deviceId, Duration duration) async {
    await _writeCommand(BleCommand.emission1Duration.value, duration.inSeconds);
  }

  Future<void> updateInterval1(String deviceId, Duration interval) async {
    await _writeCommand(BleCommand.interval1.value, interval.inSeconds);
  }

  Future<void> updatePeriodicEmission1(String deviceId, bool enabled) async {
    await _writeCommand(BleCommand.periodic1.value, enabled ? 1 : 0);
  }

  Future<void> updateHeartRateSettings(String deviceId, bool enabled, int highThreshold, int lowThreshold) async {
    await ensureConnected();
    
    // Create a settings map to use the existing updateDeviceSettings method
    final settings = {
      'heartRateEnabled': enabled ? 1 : 0,
      'highHeartRate': highThreshold,
      'lowHeartRate': lowThreshold,
    };
    
    await updateDeviceSettings(deviceId, settings);
    _logger.logBleInfo('Heart rate settings updated: enabled=$enabled, high=$highThreshold, low=$lowThreshold');
  }

  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    await ensureConnected();

    for (final entry in settings.entries) {
      switch (entry.key) {
        case 'emission1':
          await updateEmission1Duration(deviceId, Duration(seconds: entry.value));
          break;
        case 'interval1':
          await updateInterval1(deviceId, Duration(seconds: entry.value));
          break;
        case 'periodic1':
          await updatePeriodicEmission1(deviceId, entry.value == 1);
          break;
        case 'heartRateEnabled':
          await _writeCommand(BleCommand.heartRateEnabled.value, entry.value);
          break;
        case 'highHeartRate':
          await _writeCommand(BleCommand.highHeartRateThreshold.value, entry.value);
          break;
        case 'lowHeartRate':
          await _writeCommand(BleCommand.lowHeartRateThreshold.value, entry.value);
          break;
      }
    }
  }

  Future<List<BluetoothDevice>> scanForHeartRateMonitors() async {
    return _bleUtils.startScan(timeout: const Duration(seconds: 4));
  }

  Future<void> connectToHeartRateMonitor(String deviceId, BluetoothDevice monitor) async {
    await connectToDevice(monitor);
  }

  Future<void> forgetDevice(String device_id) async {
    await disconnectFromDevice();
  }

  Future<bool> checkDeviceConnected(BluetoothDevice device) async {
    return _bleUtils.checkDeviceConnected(device);
  }

  Future<void> _writeCommand(int command, int value) async {
    await ensureConnected();
    _logger.logDebug('Writing command: $command with value: $value');

    if (_pendingCommands.isNotEmpty) {
      _logger.logWarning('Command rejected - pending command in progress');
      return;
    }

    final now = DateTime.now();
    if (_lastCommandTime != null && 
        now.difference(_lastCommandTime!) < _commandDebounceTime) {
      _logger.logWarning('Command debounced - too soon after last command');
      return;
    }
    _lastCommandTime = now;

    // Add command verification
    await _verifyCommandExecution(command, value);
  }

  Future<void> _verifyCommandExecution(int command, int value) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        await _switchCharacteristic!.write([command, value]);
        await Future.delayed(Duration(milliseconds: 100));
        return;
      } catch (e) {
        retryCount++;
        _logger.logWarning('Command execution failed, attempt $retryCount of $maxRetries');
        if (retryCount == maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 200));
      }
    }
  }

  void dispose() {
    _connectionManager.dispose();
    _deviceStateController.close();
    _connectionStatusController.close();
    _rssiController.close();
    _pendingCommands.clear();
    _reconnectionAttemptsController.close();
    _connectionQualityController.close();
    _stopRssiUpdates();
  }
}
