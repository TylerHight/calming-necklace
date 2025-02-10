import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

enum BleDeviceType {
  necklace,
  heartRateMonitor,
}

class BleDevice extends Equatable {
  final String id;
  final String name;
  final String address;
  final int rssi;
  final BleDeviceType deviceType;
  final bool isConnected;
  final String? necklaceId; 
  final BluetoothDevice? device;  // Add the BluetoothDevice field

  const BleDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.rssi,
    required this.deviceType,
    this.isConnected = false,
    this.necklaceId, 
    this.device,  // Initialize the new field
  });

  @override  // Update props to include the device
  List<Object?> get props => [id, name, address, rssi, deviceType, isConnected, necklaceId];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.toString(),
      'address': address,
      'rssi': rssi,
      'deviceType': deviceType.index,
      'isConnected': isConnected ? 1 : 0,
      // Note: BluetoothDevice is not serialized in toMap
      'necklaceId': necklaceId,
    };
  }

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    try {
      return BleDevice(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Unknown Device',
        address: map['address']?.toString() ?? '',
        rssi: map['rssi'] is int ? map['rssi'] : 0,
        deviceType: map['deviceType'] is int ? 
            BleDeviceType.values[map['deviceType']] : BleDeviceType.necklace,
        isConnected: map['isConnected'] == 1,
        necklaceId: map['necklaceId']?.toString(),
      );
    } catch (e) {
      print('Error parsing BleDevice: $e');
      // Return a default device instead of throwing
      return BleDevice(
        id: '',
        name: 'Parse Error',
        address: '',
        rssi: 0,
        deviceType: BleDeviceType.necklace,
      );
    }
  }

  BleDevice copyWith({
    String? name,
    int? rssi,
    bool? isConnected,
    String? necklaceId, 
    BluetoothDevice? device,  // Add this parameter to the copyWith method
  }) {
    return BleDevice(
      id: id,
      name: name ?? this.name,
      address: address,
      rssi: rssi ?? this.rssi,
      deviceType: deviceType,
      isConnected: isConnected ?? this.isConnected,
      necklaceId: necklaceId ?? this.necklaceId, 
      device: device ?? this.device,  // Copy the new field
    );
  }
}
