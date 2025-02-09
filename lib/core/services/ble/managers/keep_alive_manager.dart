// lib/core/services/ble/managers/keep_alive_manager.dart

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble_types.dart';
import '../../../data/constants/ble_constants.dart';

class BleKeepAliveManager {
  final KeepAliveFailedCallback onKeepAliveFailed;
  Timer? _keepAliveTimer;
  Timer? _watchdogTimer;
  int _keepAliveCounter = 0;
  BluetoothCharacteristic? _keepAliveCharacteristic;
  StreamSubscription? _keepAliveSubscription;
  bool _isEnabled = false;

  BleKeepAliveManager({required this.onKeepAliveFailed});

  Future<void> initialize(BluetoothDevice device) async {
    try {
      await _setupCharacteristic(device);
      if (_keepAliveCharacteristic != null) {
        _startKeepAlive();
        _isEnabled = true;
      }
    } catch (e) {
      print('Keep-alive initialization failed: $e');
      _isEnabled = false;
    }
  }

  Future<void> _setupCharacteristic(BluetoothDevice device) async {
    final services = await device.discoverServices();

    try {
      final service = services.firstWhere(
            (s) => s.uuid.toString().toLowerCase() == BleConstants.ledServiceUuid.toLowerCase(),
      );

      _keepAliveCharacteristic = service.characteristics.firstWhere(
            (c) => c.uuid.toString().toLowerCase() == BleConstants.KEEPALIVE_CHARACTERISTIC_UUID.toLowerCase(),
      );

      await _keepAliveCharacteristic?.setNotifyValue(true);

      _keepAliveSubscription?.cancel();
      _keepAliveSubscription = _keepAliveCharacteristic?.lastValueStream.listen(
        _handleKeepAliveResponse,
        onError: (error) {
          print('Keep-alive notification error: $error');
          _isEnabled = false;
          onKeepAliveFailed();
        },
      );
    } catch (e) {
      print('Keep-alive characteristic setup failed: $e');
      _keepAliveCharacteristic = null;
      rethrow;
    }
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(
      BleConstants.KEEP_ALIVE_INTERVAL,
          (_) => _sendKeepAlive(),
    );
    _startWatchdog();
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(
      BleConstants.KEEP_ALIVE_TIMEOUT,
          () {
        if (_isEnabled) {
          _isEnabled = false;
          onKeepAliveFailed();
        }
      },
    );
  }

  void _handleKeepAliveResponse(List<int> value) {
    if (!_isEnabled) return;

    if (value.isNotEmpty && value[0] == _keepAliveCounter) {
      _startWatchdog(); // Reset watchdog on successful response
    } else {
      print('Invalid keep-alive response');
      _isEnabled = false;
      onKeepAliveFailed();
    }
  }

  Future<void> _sendKeepAlive() async {
    if (!_isEnabled || _keepAliveCharacteristic == null) return;

    try {
      _keepAliveCounter = (_keepAliveCounter + 1) % 256;
      await _keepAliveCharacteristic!.write(
        [_keepAliveCounter],
        withoutResponse: false,
      );
    } catch (e) {
      print('Failed to send keep-alive: $e');
      _isEnabled = false;
      onKeepAliveFailed();
    }
  }

  void stop() {
    _keepAliveTimer?.cancel();
    _watchdogTimer?.cancel();
    _keepAliveSubscription?.cancel();
    _keepAliveTimer = null;
    _watchdogTimer = null;
    _keepAliveSubscription = null;
    _keepAliveCharacteristic = null;
    _keepAliveCounter = 0;
    _isEnabled = false;
  }

  void dispose() {
    stop();
  }

  bool get isEnabled => _isEnabled;
}