import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/models/necklace.dart';
import '../logging_service.dart';
import 'managers/ble_connection_manager.dart';
import 'ble_types.dart';
import 'ble_commands.dart';
import '../../../core/utils/ble/ble_utils.dart';
import 'package:flutter/material.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;

  final _bleUtils = BleUtils();
  final _deviceStateController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _reconnectionAttemptsController = StreamController<int>.broadcast();
  late final BleConnectionManager _connectionManager;
  final _loggingService = LoggingService();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _switchCharacteristic;
  bool _isInitialized = false;

  Stream<String> get deviceStateStream => _deviceStateController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<int> get reconnectionAttemptsStream => _reconnectionAttemptsController.stream;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BleService._internal() {
    print('Initializing BLE Service');
    _initializeConnectionManager();
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
        break;
      case BleConnectionState.disconnected:
        _connectedDevice = null;
        _switchCharacteristic = null;
        _deviceStateController.add('Disconnected');
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

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _loggingService.logBleInfo('Attempting to connect to ${device.platformName}');
      _deviceStateController.add('Connecting to ${device.platformName}...');

      final connected = await _connectionManager.connectWithRetry(device);
      if (connected) {
        _loggingService.logBleInfo('Successfully connected to ${device.platformName}');
        _connectedDevice = device;
        
        // Wait for characteristics initialization
        await _initializeCharacteristics(device, forceRediscovery: true);
        
        // Only maintain connection after successful initialization
        await _connectionManager.maintainConnection(device);
        
        // Signal that device is ready for commands
        _deviceStateController.add('Ready for commands');
      } else {
        _loggingService.logBleError('Failed to establish connection with ${device.platformName}');
        throw BleException('Failed to establish connection');
      }
    } catch (e, stackTrace) {
      _loggingService.logBleError('Connection error', e, stackTrace);
      _deviceStateController.add('Connection error: $e');
      rethrow;
    }
  }

  Future<void> disconnectFromDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectionManager.disconnect();
        _connectedDevice = null;
        _switchCharacteristic = null;
        _isInitialized = false; // Ensure characteristics can be re-initialized
      } catch (e) {
        _loggingService.logBleError('Disconnect error', e);
        _deviceStateController.add('Disconnect error: $e');
        rethrow;
      }
    }
  }

  Future<void> _initializeCharacteristics(BluetoothDevice device, {bool forceRediscovery = false}) async {
    if (_isInitialized && !forceRediscovery) return;

    try {
      final services = await device.discoverServices();
      _loggingService.logBleDebug('Discovered ${services.length} services:');

      for (var service in services) {
        _loggingService.logBleDebug('Service UUID: ${service.uuid}');
        _loggingService.logBleDebug('Characteristics:');
        for (var char in service.characteristics) {
          _loggingService.logBleDebug('  - ${char.uuid}');
        }
      }

      // Look for the LED service (180a)
      final ledService = services.firstWhere(
            (s) => s.uuid.toString().toLowerCase().contains('180a'),
        orElse: () => throw BleException('LED service not found'),
      );

      _loggingService.logBleDebug('Found LED service: ${ledService.uuid}');

      // Look for the switch characteristic (2a57)
      _switchCharacteristic = ledService.characteristics.firstWhere(
            (c) => c.uuid.toString().toLowerCase().contains('2a57'),
        orElse: () => throw BleException('Switch characteristic not found'),
      );

      _loggingService.logBleDebug('Found switch characteristic: ${_switchCharacteristic!.uuid}');

      // Verify the characteristic has the required properties
      if (!_switchCharacteristic!.properties.write) {
        throw BleException('Characteristic does not support write operations');
      }

      _isInitialized = true;
    } catch (e) {
      _loggingService.logBleError('Error initializing characteristics: $e');
      rethrow;
    }
  }

  Future<void> ensureConnected() async {
    if (_connectedDevice == null || !await checkDeviceConnected(_connectedDevice!)) {
      throw BleException('Device not connected');
    }

    if (!_isInitialized) {
      await _initializeCharacteristics(_connectedDevice!, forceRediscovery: true);
    }
  }

  Future<void> setLedColor(int command) async {
    await ensureConnected();
    try {
      if (command < 0 || command > BleCommand.periodic1.value) {
        throw BleException('Invalid LED command');
      }
      await _writeCommand(command, 0); // TODO: Provide correct second parameter (currently dummy value)
    } catch (e) {
      _loggingService.logBleError('Failed to set LED color: $e');
      rethrow;
    }
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
      }
    }
  }

  Future<List<BluetoothDevice>> scanForHeartRateMonitors() async {
    return _bleUtils.startScan(timeout: const Duration(seconds: 4));
  }

  Future<void> connectToHeartRateMonitor(String deviceId, BluetoothDevice monitor) async {
    await connectToDevice(monitor);
  }

  Future<void> forgetDevice(String deviceId) async {
    await disconnectFromDevice();
  }

  Future<bool> checkDeviceConnected(BluetoothDevice device) async {
    return _bleUtils.checkDeviceConnected(device);
  }

  Future<void> _writeCommand(int command, int value) async {
    await ensureConnected();

    try {
      _loggingService.logBleDebug(
          'Writing command: $command, value: $value to device: ${_connectedDevice?.platformName}'
      );

      if (_switchCharacteristic == null) {
        _loggingService.logBleError('Switch characteristic not found');
        throw BleException('Switch characteristic not initialized');
      }

      await _switchCharacteristic!.write([command, value]);
      _loggingService.logBleInfo('Command $command with value $value sent successfully');
    } catch (e, stackTrace) {
      _loggingService.logBleError('Failed to write command', e, stackTrace);
      _deviceStateController.add('Write command error: $e');
      rethrow;
    }
  }

  /** TODO: Adapt this method to work with this app
  Future<void> connectToDeviceWithFeedback(BuildContext context, Necklace necklace, {VoidCallback? onConnected}) async {
    if (necklace.bleDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Bluetooth device available')),
      );
      return;
    }

    try {
      await connectToDevice(necklace.bleDevice!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected successfully')),
        );
      }
      onConnected?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    }
  }
   **/

  void dispose() {
    _connectionManager.dispose();
    _deviceStateController.close();
    _connectionStatusController.close();
    _reconnectionAttemptsController.close();
  }
}
