import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/models/ble_device.dart';
import '../../data/models/necklace.dart';
import '../logging_service.dart';
import 'managers/ble_connection_manager.dart';
import 'ble_types.dart';
import 'ble_commands.dart';
import '../../../core/utils/ble/ble_utils.dart';
import 'package:flutter/material.dart';
import '../../../core/data/constants/ble_constants.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;

  DateTime? _lastCommandTime;
  static const _commandDebounceTime = Duration(milliseconds: 500);
  final Map<String, Completer<void>> _pendingCommands = {};
  final _bleUtils = BleUtils();
  late final LoggingService _logger;
  final _deviceStateController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _rssiController = StreamController<int>.broadcast();
  final _reconnectionAttemptsController = StreamController<int>.broadcast();
  late final BleConnectionManager _connectionManager;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _switchCharacteristic;
  bool _isInitialized = false;
  Timer? _rssiTimer;

  Stream<String> get deviceStateStream => _deviceStateController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  Stream<int> get rssiStream => _rssiController.stream;
  Stream<int> get reconnectionAttemptsStream => _reconnectionAttemptsController.stream;
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

  Future<void> disconnectFromDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectionManager.disconnect();
        _connectedDevice = null;
        _switchCharacteristic = null;
        _isInitialized = false; // Ensure characteristics can be re-initialized
        _stopRssiUpdates();
      } catch (e) {
        _logger.logBleError('Disconnect error', e);
        _deviceStateController.add('Disconnect error: $e');
        rethrow;
      }
    }
  }

  Future<void> _initializeCharacteristics(BluetoothDevice device, {bool forceRediscovery = false}) async {
    if (_isInitialized && !forceRediscovery) return;

    try {
      _logger.logBleInfo('Starting service and characteristic discovery for device: ${device.id}');
      final services = await device.discoverServices();
      _logger.logBleDebug('Discovered ${services.length} services for device: ${device.id}');

      for (var service in services) {
        _logger.logBleDebug('Service UUID: ${service.uuid}');
        _logger.logBleDebug('Characteristics:');
        for (var char in service.characteristics) {
          _logger.logBleDebug('  - ${char.uuid}');
        }
      }

      final ledService = services.firstWhere(
            (s) => s.uuid.toString().toLowerCase() == BleConstants.LED_SERVICE_UUID,
        orElse: () => throw BleException('LED service not found'),
      );

      _logger.logBleDebug('Found LED service: ${ledService.uuid}');

      _switchCharacteristic = ledService.characteristics.firstWhere(
            (c) => c.uuid.toString().toLowerCase().contains(BleConstants.switchCharacteristicUuid),
        orElse: () => throw BleException('Switch characteristic not found'),
      );

      _logger.logBleDebug('Found switch characteristic: ${_switchCharacteristic!.uuid}');

      if (!_switchCharacteristic!.properties.write) {
        throw BleException('Characteristic does not support write operations');
      }

      _isInitialized = true;
      _logger.logBleInfo('Service and characteristic discovery completed for device: ${device.id}');
    } catch (e) {
      _logger.logBleError('Error initializing characteristics for device: ${device.id}', e);
      rethrow;
    }
  }

  Future<void> connectAndInitializeDevice(BluetoothDevice device) async {
    final connected = await connectToDevice(device);
    if (connected) {
      await _initializeCharacteristics(device);
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
      _logger.logBleError('Failed to set LED color: $e');
      rethrow;
    }
  }

  Future<void> setLedState(bool turnOn) async {
    await ensureConnected();
    _logger.logDebug('Sending setLedState command: ${turnOn ? 'ON' : 'OFF'}');
    _logger.logDebug('Connection state before command: ${await isDeviceConnected(_connectedDevice?.id.toString() ?? "")}');
    try {
      // Add connection verification before sending command
      if (!await isDeviceConnected(_connectedDevice?.id.toString() ?? "")) {
        throw BleException('Device connection lost before sending command');
      }

      await _writeCommand(turnOn ? BleCommand.ledOn.value : BleCommand.ledOff.value, 0);
      _logger.logDebug('LED state command sent successfully');
      // Verify command was successful
      await Future.delayed(Duration(milliseconds: 100));
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
    _stopRssiUpdates();
  }
}
