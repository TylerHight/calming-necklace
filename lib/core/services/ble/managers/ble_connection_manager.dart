import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../logging_service.dart';
import '../ble_types.dart';
import '../../../data/constants/ble_constants.dart';
import 'package:rxdart/rxdart.dart';

class BleConnectionManager {
  final StateChangeCallback onStateChange;
  final Function(int) onReconnectionAttempt;
  final ErrorCallback onError;
  final _retryDelays = [1, 2, 3]; // Seconds between retries
  final _maxRetries = 5;
  final LoggingService _logger = LoggingService.instance;
  
  final _connectionStateSubject = BehaviorSubject<BleConnectionState>();
  final _rssiSubject = BehaviorSubject<int>();

  StreamSubscription? _connectionSubscription;
  StreamSubscription? _keepAliveSubscription;
  Timer? _rssiCheckTimer;
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  int _keepAliveCounter = 0;
  BluetoothCharacteristic? _keepAliveCharacteristic;
  bool _isKeepAliveEnabled = false;
  bool _isReconnecting = false;
  BluetoothDevice? _currentDevice;
  int _reconnectAttempts = 0;
  int _currentDelaySeconds = 1;
  final int _maxDelaySeconds = 60;
  final _reconnectionSubject = BehaviorSubject<int>();

  BleConnectionManager({
    required this.onStateChange,
    required this.onError,
    required this.onReconnectionAttempt,
  });

  Future<bool> connectWithRetry(BluetoothDevice device) async {
    _logger.logBleInfo('Starting connection attempt to ${device.platformName}');
    int attempts = 0;
    bool connected = false;

    _reconnectionSubject.add(0);
    while (attempts < _maxRetries && !connected) {
      try {
        _logger.logBleDebug('Connection attempt ${attempts + 1} of $_maxRetries');
        onStateChange(BleConnectionState.connecting);

        await device.connect(
            mtu:null,
            timeout: BleConstants.CONNECTION_TIMEOUT,
            autoConnect: false
        );

        _logger.logBleDebug('Waiting for connection stabilization');
        await Future.delayed(const Duration(milliseconds: 500));

        final state = await device.connectionState.first;
        _connectionStateSubject.add(state == BluetoothConnectionState.connected ? BleConnectionState.connected : BleConnectionState.disconnected);
        if (state == BluetoothConnectionState.connected) {
          connected = true;
          _logger.logBleInfo('Successfully connected to ${device.platformName}');

          await _setupConnectionMonitoring(device);
          await maintainConnection(device);

          onStateChange(BleConnectionState.connected);
          return true;
        }
      } catch (e, stackTrace) {
        attempts++;
        _reconnectionSubject.add(attempts);
        onReconnectionAttempt(attempts);
        _logger.logBleError(
            'Connection attempt $attempts failed',
            e,
            stackTrace
        );
        onError('Connection attempt $attempts failed: $e');

        if (attempts < _maxRetries) {
          _logger.logBleInfo(
              'Waiting ${_retryDelays[attempts - 1]}s before next attempt'
          );
          await Future.delayed(Duration(seconds: _retryDelays[attempts - 1]));
        }
      }
    }
    return false;
  }

  Future<void> maintainConnection(BluetoothDevice device) async {
    _currentDevice = device;
    _logger.logBleInfo('Starting connection maintenance for ${device.platformName}');
    _startKeepAlive();

    // Monitor connection state
    device.connectionState.listen((BluetoothConnectionState state) {
      if (state == BluetoothConnectionState.disconnected && !_isReconnecting) {
        _logger.logBleWarning('Device ${device.platformName} disconnected unexpectedly');
        _handleDisconnection();
      }
    });
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(BleConstants.KEEP_ALIVE_INTERVAL, (_) {
      _checkConnectionStatus();
    });
  }

  Future<void> _checkConnectionStatus() async {
    if (_currentDevice == null) return;

    try {
      final isConnected = await _currentDevice!.connectionState.first ==
          BluetoothConnectionState.connected;
      _connectionStateSubject.add(isConnected ? BleConnectionState.connected : BleConnectionState.disconnected);

      if (!isConnected && !_isReconnecting) {
        _handleDisconnection();
      }
    } catch (e) {
      onError('Connection check failed: $e');
    }
  }

  Future<void> _handleDisconnection() async {
    if (_isReconnecting) {
      _logger.logBleDebug('Reconnection already in progress, skipping');
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts = 0;
    _currentDelaySeconds = 1; // Initial delay

    _reconnectionSubject.add(0);
    while (_reconnectAttempts < _maxRetries && _currentDevice != null) {
      try {
        _logger.logBleInfo(
            'Attempting reconnection ${_reconnectAttempts + 1}/$_maxRetries'
        );
        onStateChange(BleConnectionState.connecting);

        _reconnectionSubject.add(_reconnectAttempts + 1);
        onReconnectionAttempt(_reconnectAttempts + 1);
        await _currentDevice!.connect(
            mtu:null,
            timeout: const Duration(seconds: 5),
            autoConnect: false
        );

        final isConnected = await _currentDevice!.connectionState.first ==
            BluetoothConnectionState.connected;

        if (isConnected) {
          _logger.logBleInfo('Reconnection successful');
          _isReconnecting = false;
          await _setupConnectionMonitoring(_currentDevice!);
          onStateChange(BleConnectionState.connected);
          return;
        }
      } catch (e, stackTrace) {
        _reconnectAttempts++;
        _logger.logBleError(
            'Reconnection attempt $_reconnectAttempts failed',
            e,
            stackTrace
        );

        if (_reconnectAttempts >= _maxRetries) {
          _logger.logBleWarning('Max reconnection attempts reached');
          onError('Failed to reconnect after $_maxRetries attempts');
          break;
        }

        // Exponential backoff
        _currentDelaySeconds = min(_currentDelaySeconds * 2, _maxDelaySeconds);
        _logger.logBleInfo(
            'Waiting ${_currentDelaySeconds}s before next attempt'
        );
        await Future.delayed(Duration(seconds: _currentDelaySeconds));
      }
    }

    _isReconnecting = false;
  }

  void _startAutoReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(BleConstants.RECONNECT_DELAY, (_) {
      if (_currentDevice != null && !_isReconnecting) {
        _handleDisconnection();
      }
    });
  }

  Future<void> _setupConnectionMonitoring(BluetoothDevice device) async {
    _logger.logBleDebug('Setting up connection monitoring');
    _cleanupMonitoring();

    _connectionSubscription = device.connectionState.listen(
            (BluetoothConnectionState state) {
          _logger.logBleDebug('Connection state changed: $state');
          if (state == BluetoothConnectionState.disconnected) {
            _logger.logBleWarning('Device disconnected in monitoring');
            onStateChange(BleConnectionState.disconnected);
            _cleanupMonitoring();
          }
        },
        onError: (error, stackTrace) {
          _logger.logBleError(
              'Connection monitoring error',
              error,
              stackTrace
          );
          onError('Connection monitoring error: $error');
          onStateChange(BleConnectionState.disconnected);
          _cleanupMonitoring();
        }
    );

    // Monitor signal strength
    _rssiCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final rssi = await device.readRssi();
        _rssiSubject.add(rssi);
        if (rssi < BleConstants.MIN_RSSI_THRESHOLD) {
          _logger.logBleWarning('Weak signal strength detected (RSSI: $rssi)');
        }
      } catch (e) {
        // Ignore RSSI read errors
      }
    });

    await _setupKeepAlive(device);
  }

  Future<void> _setupKeepAlive(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      final service = services.firstWhere(
            (s) => s.uuid.toString().toLowerCase() == BleConstants.LED_SERVICE_UUID.toLowerCase(),
      );

      _keepAliveCharacteristic = service.characteristics.firstWhere(
            (c) => c.uuid.toString().toLowerCase() == BleConstants.KEEPALIVE_CHARACTERISTIC_UUID.toLowerCase(),
      );

      await _keepAliveCharacteristic?.setNotifyValue(true);

      _keepAliveSubscription = _keepAliveCharacteristic?.lastValueStream.listen((value) {
        if (value.isNotEmpty && value[0] == _keepAliveCounter) {
          _isKeepAliveEnabled = true;
        } else {
          onStateChange(BleConnectionState.keepAliveFailure);
        }
      });

      _keepAliveTimer = Timer.periodic(BleConstants.KEEP_ALIVE_INTERVAL, (_) {
        _sendKeepAlive(device);
      });

    } catch (e) {
      onError('Keep-alive setup failed: $e');
    }
  }

  Future<void> _sendKeepAlive(BluetoothDevice device) async {
    if (!_isKeepAliveEnabled || _keepAliveCharacteristic == null) {
      _logger.logBleDebug('Keep-alive not enabled, skipping');
      return;
    }

    try {
      _keepAliveCounter = (_keepAliveCounter + 1) % 256;
      _logger.logBleDebug('Sending keep-alive counter: $_keepAliveCounter');
      await _keepAliveCharacteristic!.write([_keepAliveCounter], withoutResponse: false);
    } catch (e, stackTrace) {
      _logger.logBleError('Keep-alive failed', e, stackTrace);
      _isKeepAliveEnabled = false;
      onStateChange(BleConnectionState.keepAliveFailure);
    }
  }

  void _cleanupMonitoring() {
    _connectionSubscription?.cancel();
    _rssiCheckTimer?.cancel();
    _keepAliveSubscription?.cancel();
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectionSubscription = null;
    _rssiCheckTimer = null;
    _keepAliveSubscription = null;
    _keepAliveTimer = null;
    _reconnectTimer = null;
    _keepAliveCharacteristic = null;
    _reconnectionSubject.add(0);
    _keepAliveCounter = 0;
    _isKeepAliveEnabled = false;
    _isReconnecting = false;
  }

  Future<void> disconnect() async {
    try {
      if (_currentDevice != null) {
        _logger.logBleInfo('Starting disconnect sequence');
        onStateChange(BleConnectionState.disconnecting);

        // Cancel all active subscriptions and timers
        _cleanupMonitoring();

        // Disable notifications and disconnect from characteristics
        await _disableNotifications();

        await _currentDevice!.disconnect();
        // Wait for disconnect to complete and verify
        await Future.delayed(Duration(milliseconds: 1000));

        _currentDevice = null;
        onStateChange(BleConnectionState.disconnected);
      }
    } catch (e) {
      _logger.logBleError('Disconnect error', e);
      rethrow;
    }
  }

  Future<void> _disableNotifications() async {
    try {
      if (_keepAliveCharacteristic != null) {
        await _keepAliveCharacteristic!.setNotifyValue(false);
      }

      // Cancel any pending GATT operations
      if (_currentDevice != null) {
        await _currentDevice!.requestMtu(23); // Reset MTU to default
      }
    } catch (e) {
      _logger.logBleError('Error disabling notifications', e);
    }
  }

  Future<bool> attemptRecovery(BluetoothDevice device) async {
    onError('Attempting connection recovery...');
    return await connectWithRetry(device);
  }

  Future<List<BluetoothDevice>> scanForDevices({
    required Duration timeout,
    List<Guid>? withServices,
    bool Function(BluetoothDevice)? filter,
  }) async {
    try {
      await FlutterBluePlus.stopScan();

      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: withServices ?? [],
        androidScanMode: AndroidScanMode.lowLatency,
      );

      final results = await FlutterBluePlus.scanResults.first;
      final devices = results
          .where((r) => r.device.platformName.contains(BleConstants.DEVICE_NAME_PREFIX))
          .where((r) => r.rssi >= BleConstants.MIN_RSSI_THRESHOLD)
          .map((r) => r.device)
          .toList();

      if (filter != null) {
        return devices.where(filter).toList();
      }
      return devices;
    } catch (e) {
      onError('Scan failed: $e');
      return [];
    } finally {
      await FlutterBluePlus.stopScan();
    }
  }

  void dispose() {
    disconnect();
    _cleanupMonitoring();
    _connectionStateSubject.close();
    _rssiSubject.close();
    _reconnectionSubject.close();
  }
}
