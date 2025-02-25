import 'package:equatable/equatable.dart';
import 'dart:convert';
import '../../services/logging_service.dart';
import 'ble_device.dart';

class Necklace extends Equatable {
  final String id;
  final String name;
  final BleDevice? bleDevice;
  final BleDevice? heartRateMonitorDevice;
  final bool autoTurnOffEnabled;
  final bool periodicEmissionEnabled;
  final bool isConnected;
  final Duration emission1Duration;
  final Duration releaseInterval1;
  final bool isRelease1Active;
  final bool isArchived;
  final bool isLedOn;
  final DateTime? lastLEDStateChange;
  final bool isHeartRateBasedReleaseEnabled;
  final int highHeartRateThreshold;
  final int lowHeartRateThreshold;

  Necklace({
    required this.id,
    required this.name,
    this.bleDevice,
    this.heartRateMonitorDevice,
    this.isLedOn = false,
    this.isConnected = false,
    required this.emission1Duration,
    required this.releaseInterval1,
    this.autoTurnOffEnabled = false,
    this.periodicEmissionEnabled = false,
    this.isRelease1Active = false,
    this.isArchived = false,
    this.lastLEDStateChange,
    this.isHeartRateBasedReleaseEnabled = false,
    this.highHeartRateThreshold = 120,
    this.lowHeartRateThreshold = 60,
  });

  Necklace copyWith({
    String? id,
    String? name,
    BleDevice? bleDevice,
    BleDevice? heartRateMonitorDevice,
    Duration? emission1Duration,
    Duration? releaseInterval1,
    bool? autoTurnOffEnabled,
    bool? periodicEmissionEnabled,
    bool? isRelease1Active,
    bool? isArchived,
    bool? isLedOn,
    bool? isConnected,
    DateTime? lastLEDStateChange,
    bool? isHeartRateBasedReleaseEnabled,
    int? highHeartRateThreshold,
    int? lowHeartRateThreshold,
  }) {
    return Necklace(
      id: id ?? this.id,
      name: name ?? this.name,
      isLedOn: isLedOn ?? this.isLedOn,
      isConnected: isConnected ?? this.isConnected,
      bleDevice: bleDevice ?? this.bleDevice,
      heartRateMonitorDevice: heartRateMonitorDevice ?? this.heartRateMonitorDevice,
      emission1Duration: emission1Duration ?? this.emission1Duration,
      releaseInterval1: releaseInterval1 ?? this.releaseInterval1,
      autoTurnOffEnabled: autoTurnOffEnabled ?? this.autoTurnOffEnabled,
      periodicEmissionEnabled: periodicEmissionEnabled ?? this.periodicEmissionEnabled,
      isRelease1Active: isRelease1Active ?? this.isRelease1Active,
      isArchived: isArchived ?? this.isArchived,
      lastLEDStateChange: lastLEDStateChange ?? this.lastLEDStateChange,
      isHeartRateBasedReleaseEnabled: isHeartRateBasedReleaseEnabled ?? this.isHeartRateBasedReleaseEnabled,
      highHeartRateThreshold: highHeartRateThreshold ?? this.highHeartRateThreshold,
      lowHeartRateThreshold: lowHeartRateThreshold ?? this.lowHeartRateThreshold,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    bleDevice,
    heartRateMonitorDevice,
    autoTurnOffEnabled,
    emission1Duration,
    releaseInterval1,
    periodicEmissionEnabled,
    isRelease1Active,
    isArchived,
    isLedOn,
    isConnected,
    lastLEDStateChange,
    isHeartRateBasedReleaseEnabled,
    highHeartRateThreshold,
    lowHeartRateThreshold,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bleDevice': bleDevice != null 
          ? jsonEncode(bleDevice!.toMap())
          : null,
      'heartRateMonitorDevice': heartRateMonitorDevice != null 
          ? jsonEncode(heartRateMonitorDevice!.toMap())
          : null,
      'name': name,
      'autoTurnOffEnabled': autoTurnOffEnabled ? 1 : 0,
      'emission1Duration': emission1Duration.inSeconds,
      'releaseInterval1': releaseInterval1.inSeconds,
      'periodicEmissionEnabled': periodicEmissionEnabled ? 1 : 0,
      'isRelease1Active': isRelease1Active ? 1 : 0,
      'isLedOn': isLedOn ? 1 : 0,
      'isConnected': isConnected ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'lastLEDStateChange': lastLEDStateChange?.toIso8601String(),
      'isHeartRateBasedReleaseEnabled': isHeartRateBasedReleaseEnabled ? 1 : 0,
      'highHeartRateThreshold': highHeartRateThreshold,
      'lowHeartRateThreshold': lowHeartRateThreshold,
    };
  }

  factory Necklace.fromMap(Map<String, dynamic> map) {
    BleDevice? parseDevice(dynamic deviceData) {
      if (deviceData == null) return null;
      try {
        Map<String, dynamic> deviceMap;
        if (deviceData is String) {
          deviceMap = jsonDecode(deviceData) as Map<String, dynamic>;
        } else if (deviceData is Map) {
          deviceMap = Map<String, dynamic>.from(deviceData);
        } else {
          LoggingService.instance.logError('Invalid device data format: $deviceData');
          return null;
        }
        
        // Ensure deviceType is properly formatted
        if (deviceMap['deviceType'] != null) {
          deviceMap['deviceType'] = deviceMap['deviceType'].toString().toLowerCase();
        }
        
        return BleDevice.fromMap(deviceMap);
      } catch (e) {
        LoggingService.instance.logError('Error parsing device data: $e');
        return null;
      }
    }

    return Necklace(
      id: map['id'],
      bleDevice: parseDevice(map['bleDevice']),
      heartRateMonitorDevice: parseDevice(map['heartRateMonitorDevice']),
      name: map['name'],
      autoTurnOffEnabled: map['autoTurnOffEnabled'] == 1,
      emission1Duration: Duration(seconds: map['emission1Duration']),
      releaseInterval1: Duration(seconds: map['releaseInterval1']),
      periodicEmissionEnabled: map['periodicEmissionEnabled'] == 1,
      isRelease1Active: map['isRelease1Active'] == 1,
      isLedOn: map['isLedOn'] == 1,
      isConnected: map['isConnected'] == 1,
      isArchived: map['isArchived'] == 1,
      lastLEDStateChange: map['lastLEDStateChange'] != null ? 
          DateTime.parse(map['lastLEDStateChange']) : null,
      isHeartRateBasedReleaseEnabled: map['isHeartRateBasedReleaseEnabled'] == 1,
      highHeartRateThreshold: map['highHeartRateThreshold'],
      lowHeartRateThreshold: map['lowHeartRateThreshold'],
    );
  }
}
