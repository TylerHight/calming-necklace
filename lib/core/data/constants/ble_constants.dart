class BleConstants {
  // Connection states
  static const String connecting = "Connecting...";
  static const String connected = "Connected";
  static const String disconnected = "Disconnected";

  // Device Information
  static const String DEVICE_NAME = "Calming Necklace";
  static const String DEVICE_NAME_PREFIX = "CN";

  // Connection settings
  static const Duration CONNECTION_TIMEOUT = Duration(seconds: 600);
  static const Duration KEEP_ALIVE_INTERVAL = Duration(seconds: 60);
  static const Duration KEEP_ALIVE_TIMEOUT = Duration(seconds: 120);
  static const Duration RECONNECT_DELAY = Duration(seconds: 2);
  static const int MAX_CONNECTION_RETRIES = 3;
  static const int MIN_RSSI_THRESHOLD = -80;

  // Service UUIDs
  static const String LED_SERVICE_UUID = "19b10000-e8f2-537e-4f6c-d104768a1214";
  static const String SETTINGS_SERVICE_UUID = "00001800-0000-1000-8000-00805f9b34fb";

  // Characteristic UUIDs
  static const String switchCharacteristicUuid = "19b10001-e8f2-537e-4f6c-d104768a1214";
  static const String KEEPALIVE_CHARACTERISTIC_UUID = "2A3B";
  static const String EMISSION_CHARACTERISTIC_UUID = "2A19";
  static const String INTERVAL_CHARACTERISTIC_UUID = "2A1B";
  static const String PERIODIC_CHARACTERISTIC_UUID = "2A1D";

  // MTU Settings
  static const int DEFAULT_MTU = 23;
  static const int PREFERRED_MTU = 512;

  // Error Messages
  static const String ERR_DEVICE_NOT_FOUND = "QUE device not found";
  static const String ERR_CONNECTION_FAILED = "Failed to connect to device";
  static const String ERR_SERVICE_NOT_FOUND = "Required BLE service not found";
  static const String ERR_CHARACTERISTIC_NOT_FOUND = "Required characteristic not found";
  static const String ERR_DEVICE_DISCONNECTED = "Device disconnected unexpectedly";
  static const String ERR_BLUETOOTH_DISABLED = "Bluetooth is disabled";
  static const String ERR_TIMEOUT = "Connection timeout";
  static const String ERR_KEEPALIVE_FAILED = "Keep-alive check failed";
  static const String ERR_INVALID_COMMAND = "Invalid command value";
  static const String ERR_CHARACTERISTIC_WRITE = "Failed to write to characteristic";
  static const String ERR_CHARACTERISTIC_READ = "Failed to read characteristic";
  static const String ERR_DISCOVERY = "Service discovery failed";

  // Status Messages
  static const String MSG_CONNECTING = "Connecting to device...";
  static const String MSG_CONNECTED = "Connected successfully";
  static const String MSG_DISCONNECTED = "Device disconnected";
  static const String MSG_SCANNING = "Scanning for devices...";
}
