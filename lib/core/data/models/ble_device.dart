import 'package:equatable/equatable.dart';

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
  final String? necklaceId; // Add this field to associate with a Necklace

  const BleDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.rssi,
    required this.deviceType,
    this.isConnected = false,
    this.necklaceId, // Initialize the new field
  });

  @override
  List<Object?> get props => [id, name, address, rssi, deviceType, isConnected, necklaceId];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rssi': rssi,
      'deviceType': deviceType.index,
      'isConnected': isConnected ? 1 : 0,
      'necklaceId': necklaceId, // Include the new field in the map
    };
  }

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    return BleDevice(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      rssi: map['rssi'],
      deviceType: BleDeviceType.values[map['deviceType']],
      isConnected: map['isConnected'] == 1,
      necklaceId: map['necklaceId'], // Initialize the new field from the map
    );
  }

  BleDevice copyWith({
    String? name,
    int? rssi,
    bool? isConnected,
    String? necklaceId, // Add this parameter to the copyWith method
  }) {
    return BleDevice(
      id: id,
      name: name ?? this.name,
      address: address,
      rssi: rssi ?? this.rssi,
      deviceType: deviceType,
      isConnected: isConnected ?? this.isConnected,
      necklaceId: necklaceId ?? this.necklaceId, // Copy the new field
    );
  }
}