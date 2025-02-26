import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:equatable/equatable.dart';
import '../../services/logging_service.dart';
import '../repositories/ble_repository.dart';

enum BleDeviceType { necklace, heartRateMonitor }

class BleServiceInfo extends Equatable {
  final String uuid;
  final List<BleCharacteristicInfo>? characteristics;

  const BleServiceInfo({
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
    try {
      final characteristics = map['characteristics'] as List<dynamic>?;
      return BleServiceInfo(
        uuid: map['uuid'] as String? ?? '',
        characteristics: characteristics?.map((c) =>
            BleCharacteristicInfo.fromMap(Map<String, dynamic>.from(c))
        ).toList(),
      );
    } catch (e) {
      LoggingService.instance.logError('Error parsing BleServiceInfo: $e');
      rethrow;
    }
  }

  @override
  List<Object?> get props => [uuid, characteristics];
}

class BleCharacteristicInfo extends Equatable {
  final String uuid;
  final List<String> properties;

  const BleCharacteristicInfo({
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
    try {
      return BleCharacteristicInfo(
        uuid: map['uuid'] as String? ?? '',
        properties: List<String>.from(map['properties'] ?? []),
      );
    } catch (e) {
      LoggingService.instance.logError('Error parsing BleCharacteristicInfo: $e');
      rethrow;
    }
  }

  @override
  List<Object> get props => [uuid, properties];
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
    try {
      return {
        'id': id,
        'name': name,
        'address': address,
        'rssi': rssi,
        'deviceType': deviceType.toString().split('.').last,
        'services': services?.map((s) => s.toMap()).toList(),
      };
    } catch (e) {
      LoggingService.instance.logError('Error converting BleDevice to map: $e');
      rethrow;
    }
  }

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    try {
      List<BleServiceInfo>? services;
      if (map['services'] != null) {
        if (map['services'] is List) {
          services = (map['services'] as List).map((serviceMap) {
            return BleServiceInfo.fromMap(Map<String, dynamic>.from(serviceMap));
          }).toList();
        }
      }

      return BleDevice(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        address: map['address'] as String? ?? '',
        rssi: map['rssi'] as int? ?? 0,
        deviceType: _parseDeviceType(map['deviceType']),
        services: services,
      );
    } catch (e) {
      LoggingService.instance.logError('Error parsing BleDevice from map: $e\nMap: $map');
      rethrow;
    }
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
    try {
      if (type == null) return BleDeviceType.necklace;
      return BleDeviceType.values.firstWhere(
            (e) => e.toString() == 'BleDeviceType.$type' || e.toString() == type,
        orElse: () => BleDeviceType.necklace,
      );
    } catch (e) {
      LoggingService.instance.logError('Error parsing device type: $e');
      return BleDeviceType.necklace;
    }
  }

  @override
  List<Object?> get props => [id, name, address, rssi, deviceType, services];

  @override
  String toString() {
    return 'BleDevice(id: $id, name: $name, address: $address, rssi: $rssi, type: $deviceType, services: ${services?.length ?? 0})';
  }
}