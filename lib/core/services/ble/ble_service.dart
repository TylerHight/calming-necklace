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
    _logger.logDebug('Connected device: ${_connectedDevice?.name}, Switch characteristic: ${_switchCharacteristic?.uuid}');
    try {
      await _writeCommand(turnOn ? BleCommand.ledOn.value : BleCommand.ledOff.value, 0);
      _logger.logDebug('LED state command sent successfully');
    } catch (e) {
      _logger.logBleError('Failed to set LED state: ${e.toString()}', e);
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

    if (_pendingCommands.isNotEmpty) return; // Prevent multiple pending commands
    final now = DateTime.now();
    if (_lastCommandTime != null && 
        now.difference(_lastCommandTime!) < _commandDebounceTime) {
      _logger.logDebug('Command debounced');
      return;
    }
    _lastCommandTime = now;

    final commandId = '${command}_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<void>();
    _pendingCommands[commandId] = completer;

    try {
      await Future.delayed(Duration(milliseconds: 100)); // Add small delay between commands
      Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) {
          completer.completeError('Command timeout');
          _pendingCommands.remove(commandId);
        }
      });

      await _switchCharacteristic!.write([command, value]);
      completer.complete();
      _pendingCommands.remove(commandId);
      _logger.logBleInfo('Command $command with value $value sent successfully');
    } catch (e) {
      _logger.logBleError('Failed to write command', e);
      completer.completeError(e);
      _pendingCommands.remove(commandId);
      rethrow;
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
