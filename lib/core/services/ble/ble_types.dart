// lib/core/services/ble/ble_types.dart

enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  keepAliveFailure
}

/// Callback typedefs
typedef ErrorCallback = void Function(String message);
typedef StateChangeCallback = void Function(BleConnectionState state);
typedef ConnectionStatusCallback = void Function(bool isConnected);
typedef KeepAliveFailedCallback = void Function();

/// BLE-specific exception
class BleException implements Exception {
  final String message;
  BleException(this.message);

  @override
  String toString() => 'BleException: $message';
}