// lib/core/utils/ble/ble_permissions.dart

import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BlePermissions {
  /// Request all necessary Bluetooth Low Energy permissions based on platform
  static Future<bool> requestPermissions() async {
    bool allGranted = true;
    if (Platform.isAndroid) {
      final locationStatus = await Permission.locationWhenInUse.request();
      if (!locationStatus.isGranted) {
        allGranted = false;
      }

      // For Android 12+ additional permissions are required
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final bluetoothAdvertise = await Permission.bluetoothAdvertise.request();
      
      if (!bluetoothScan.isGranted || !bluetoothConnect.isGranted || !bluetoothAdvertise.isGranted) {
        allGranted = false;
      }
      return allGranted;
    }
    else if (Platform.isIOS) {
      final bluetoothStatus = await Permission.bluetooth.request();
      return bluetoothStatus.isGranted;
    }

    return false;
  }

  /// Check if Bluetooth is available and enabled
  static Future<bool> checkBleStatus() async {
    try {
      // Check if Bluetooth Low Energy is supported on the device
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception("Bluetooth not supported on this device");
      }

      // Get current adapter state
      final adapterState = await FlutterBluePlus.adapterState.first;

      if (adapterState != BluetoothAdapterState.on) {
        // Try to turn on Bluetooth
        await FlutterBluePlus.turnOn();

        // Wait for adapter state to change
        final newState = await FlutterBluePlus.adapterState.first;
        return newState == BluetoothAdapterState.on;
      }

      return true;
    } catch (e) {
      print('Error checking Bluetooth Low Energy status: $e');
      return false;
    }
  }

  /// Monitor Bluetooth state changes
  static Stream<bool> get bluetoothStateStream {
    return FlutterBluePlus.adapterState.map((state) => state == BluetoothAdapterState.on);
  }

  /// Open app settings if permissions are denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Check if permissions are permanently denied
  static Future<bool> arePermissionsPermanentlyDenied() async {
    if (Platform.isAndroid) {
      return await Permission.bluetoothConnect.isPermanentlyDenied ||
             await Permission.bluetoothScan.isPermanentlyDenied ||
             await Permission.locationWhenInUse.isPermanentlyDenied;
    }
    return false;
  }

  /// Check if all required permissions are granted
  static Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      return await Permission.bluetooth.isGranted &&
          await Permission.bluetoothScan.isGranted &&
          await Permission.bluetoothConnect.isGranted &&
          await Permission.bluetoothAdvertise.isGranted &&
          await Permission.locationWhenInUse.isGranted;
    }
    else if (Platform.isIOS) {
      return await Permission.bluetooth.isGranted;
    }
    return false;
  }
}
