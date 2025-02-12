import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'ble_device.dart';

class Necklace extends Equatable {
  final String id;
  final String name;
  final BleDevice? bleDevice; // Change type to BleDevice?
  final bool autoTurnOffEnabled;
  final bool periodicEmissionEnabled;
  final Duration emission1Duration;
  final Duration releaseInterval1;
  final bool isRelease1Active;
  final bool isArchived;
  final bool isLedOn; // Added isLedOn field

  Necklace({
    required this.id,
    required this.name,
    this.bleDevice, // Update constructor
    this.isLedOn = false, // Initialize isLedOn
    required this.emission1Duration,
    required this.releaseInterval1,
    this.autoTurnOffEnabled = false,
    this.periodicEmissionEnabled = false,
    this.isRelease1Active = false,
    this.isArchived = false,
  });

  Necklace copyWith({
    String? id,
    String? name,
    BleDevice? bleDevice, // Update copyWith method
    Duration? emission1Duration,
    Duration? releaseInterval1,
    bool? autoTurnOffEnabled,
    bool? periodicEmissionEnabled,
    bool? isRelease1Active,
    bool? isArchived,
    bool? isLedOn, // Update copyWith method
  }) {
    return Necklace(
      id: id ?? this.id,
      name: name ?? this.name,
      isLedOn: isLedOn ?? this.isLedOn, // Update copyWith method
      bleDevice: bleDevice ?? this.bleDevice, // Update copyWith method
      emission1Duration: emission1Duration ?? this.emission1Duration,
      releaseInterval1: releaseInterval1 ?? this.releaseInterval1,
      autoTurnOffEnabled: autoTurnOffEnabled ?? this.autoTurnOffEnabled,
      periodicEmissionEnabled: periodicEmissionEnabled ?? this.periodicEmissionEnabled,
      isRelease1Active: isRelease1Active ?? this.isRelease1Active,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    bleDevice, // Update props
    autoTurnOffEnabled,
    emission1Duration,
    releaseInterval1,
    periodicEmissionEnabled,
    isRelease1Active,
    isArchived,
    isLedOn, // Update props
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bleDevice': bleDevice != null ? 
          jsonEncode({
            ...bleDevice!.toMap(),
            'device': null  // Exclude the BluetoothDevice instance from serialization
          }) : null,
      'name': name,
      'autoTurnOffEnabled': autoTurnOffEnabled ? 1 : 0,
      'emission1Duration': emission1Duration.inSeconds,
      'releaseInterval1': releaseInterval1.inSeconds,
      'periodicEmissionEnabled': periodicEmissionEnabled ? 1 : 0,
      'isRelease1Active': isRelease1Active ? 1 : 0,
      'isLedOn': isLedOn ? 1 : 0, // Add isLedOn to map
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory Necklace.fromMap(Map<String, dynamic> map) {
    return Necklace(
      id: map['id'],
      bleDevice: map['bleDevice'] != null ? 
          BleDevice.fromMap(
            map['bleDevice'] is String ? 
              jsonDecode(map['bleDevice']) as Map<String, dynamic> :
              map['bleDevice'] as Map<String, dynamic>
          ) : null,
      name: map['name'],
      autoTurnOffEnabled: map['autoTurnOffEnabled'] == 1,
      emission1Duration: Duration(seconds: map['emission1Duration']),
      releaseInterval1: Duration(seconds: map['releaseInterval1']),
      periodicEmissionEnabled: map['periodicEmissionEnabled'] == 1,
      isRelease1Active: map['isRelease1Active'] == 1,
      isLedOn: map['isLedOn'] == 1, // Add isLedOn from map
      isArchived: map['isArchived'] == 1,
    );
  }
}
