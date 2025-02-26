import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:equatable/equatable.dart';
import '../../services/logging_service.dart';
import '../repositories/ble_repository.dart';

enum BleDeviceType { necklace, heartRateMonitor }

class BleServiceInfo {
  final String uuid;
  final List<BleCharacteristicInfo>? characteristics;

  BleServiceInfo({
    required this.uuid,
    this.characteristics,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'characteristics': characteristics?.map((c) => c.toMap()).toList(),
    };
  }

  factory BleServiceInfo.fromMap(Map<String, dynamic> map) {
    return BleServiceInfo(
      uuid: map['uuid'],
      characteristics: map['characteristics'] != null
          ? (map['characteristics'] as List)
          .map((c) => BleCharacteristicInfo.fromMap(c))
          .toList()
          : null,
    );
  }
}

class BleCharacteristicInfo {
  final String uuid;
  final List<String> properties;

  BleCharacteristicInfo({
    required this.uuid,
    required this.properties,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'properties': properties,
    };
  }

  factory BleCharacteristicInfo.fromMap(Map<String, dynamic> map) {
    return BleCharacteristicInfo(
      uuid: map['uuid'],
      properties: List<String>.from(map['properties']),
    );
  }
}

class BleDevice extends Equatable {
  final String id;
  final String name;
  final String address;
  final int rssi;
  final BleDeviceType deviceType;
  final BluetoothDevice? device;
  final List<BleServiceInfo>? services;

  const BleDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.rssi,
    required this.deviceType,
    this.device,
    this.services,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rssi': rssi,
      'deviceType': deviceType.toString(),
      'services': services?.map((s) => s.toMap()).toList(),
    };
  }

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    return BleDevice(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      rssi: map['rssi'] ?? 0,
      deviceType: _parseDeviceType(map['deviceType']),
      services: map['services'] != null
          ? (map['services'] as List)
          .map((s) => BleServiceInfo.fromMap(s))
          .toList()
          : null,
    );
  }

  BleDevice copyWith({
    String? id,
    String? name,
    String? address,
    int? rssi,
    BleDeviceType? deviceType,
    BluetoothDevice? device,
    List<BleServiceInfo>? services,
  }) {
    return BleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
      deviceType: deviceType ?? this.deviceType,
      device: device ?? this.device,
      services: services ?? this.services,
    );
  }

  static BleDeviceType _parseDeviceType(String? type) {
    if (type == null) return BleDeviceType.necklace;
    return BleDeviceType.values.firstWhere(
          (e) => e.toString() == type,
      orElse: () => BleDeviceType.necklace,
    );
  }

  @override
  List<Object?> get props => [id, name, address, rssi, deviceType, services];

  @override
  String toString() {
    return 'BleDevice(id: $id, name: $name, address: $address, rssi: $rssi, type: $deviceType)';
  }
}