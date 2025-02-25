import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:equatable/equatable.dart';

import '../../services/logging_service.dart';

enum BleDeviceType { necklace, heartRateMonitor }

class BleDevice extends Equatable {
  final String id;
  final String name;
  final String address;
  final int rssi;
  final BleDeviceType deviceType;
  final BluetoothDevice? device;
  final List<BleServiceInfo> services;

  const BleDevice({
    required this.id,
    required this.name,
    required this.address,
    required this.rssi,
    required this.deviceType,
    this.device,
    this.services = const [],
  });

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

  @override
  List<Object?> get props => [id, name, address, rssi, deviceType, device, services];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rssi': rssi,
      'deviceType': deviceType.toString().split('.').last,
      'services': services.map((service) => service.toMap()).toList(),
    };
  }

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    try {
      return BleDevice(
        id: map['id'] ?? '',
        name: map['name'] ?? 'Unknown Device',
        address: map['address'] ?? '',
        rssi: map['rssi'] ?? 0,
        deviceType: _parseDeviceType(map['deviceType']),
        services: _parseServices(map['services']),
      );
    } catch (e) {
      LoggingService.instance.logError('Error parsing BLE device data: $e');
      // Return a default device on error
      return BleDevice(
        id: '',
        name: 'Unknown Device',
        address: '',
        rssi: 0,
        deviceType: BleDeviceType.necklace,
        services: const [],
      );
    }
  }

  static BleDeviceType _parseDeviceType(dynamic value) {
    try {
      if (value == null) return BleDeviceType.necklace;
      
      if (value is String) {
        // Handle both full enum string and just the name
        final enumString = value.contains('.') ? value.split('.').last : value;
        return BleDeviceType.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == enumString.toLowerCase(),
          orElse: () => BleDeviceType.necklace
        );
      }
      return BleDeviceType.necklace;
    } catch (e) {
      LoggingService.instance.logError('Error parsing device type: $e');
      return BleDeviceType.necklace;
    }
  }

  static List<BleServiceInfo> _parseServices(dynamic services) {
    if (services == null || services is! List) return [];

    try {
      return services
          .map((x) => BleServiceInfo.fromMap(x as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggingService.instance.logError('Error parsing BLE services: $e');
      return [];
    }
  }
}

class BleServiceInfo extends Equatable {
  final String uuid;
  final List<BleCharacteristicInfo> characteristics;

  const BleServiceInfo({
    required this.uuid,
    required this.characteristics,
  });

  @override
  List<Object?> get props => [uuid, characteristics];

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'characteristics': characteristics.map((char) => char.toMap()).toList(),
    };
  }

  factory BleServiceInfo.fromMap(Map<String, dynamic> map) {
    return BleServiceInfo(
      uuid: map['uuid'],
      characteristics: List<BleCharacteristicInfo>.from(map['characteristics']?.map((x) => BleCharacteristicInfo.fromMap(x))),
    );
  }
}

class BleCharacteristicInfo extends Equatable {
  final String uuid;
  final List<String> properties;

  const BleCharacteristicInfo({
    required this.uuid,
    required this.properties,
  });

  @override
  List<Object?> get props => [uuid, properties];

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
