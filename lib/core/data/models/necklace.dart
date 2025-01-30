import 'package:equatable/equatable.dart';

class Necklace extends Equatable {
  final String id;
  final String name;
  final String bleDevice;
  final bool autoTurnOffEnabled;
  final bool periodicEmissionEnabled;
  final Duration emission1Duration;
  final Duration releaseInterval1;
  final Duration emission2Duration;
  final Duration releaseInterval2;
  final bool isRelease1Active;
  final bool isRelease2Active;
  final bool isArchived;

  Necklace({
    required this.id,
    required this.name,
    required this.bleDevice,
    this.autoTurnOffEnabled = false,
    this.periodicEmissionEnabled = false,
    required this.emission1Duration,
    required this.releaseInterval1,
    required this.emission2Duration,
    required this.releaseInterval2,
    this.isRelease1Active = false,
    this.isRelease2Active = false,
    this.isArchived = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    bleDevice,
    autoTurnOffEnabled,
    periodicEmissionEnabled,
    emission1Duration,
    releaseInterval1,
    emission2Duration,
    releaseInterval2,
    isRelease1Active,
    isRelease2Active,
    isArchived,
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bleDevice': bleDevice,
      'autoTurnOffEnabled': autoTurnOffEnabled ? 1 : 0,
      'periodicEmissionEnabled': periodicEmissionEnabled ? 1 : 0,
      'emission1Duration': emission1Duration.inSeconds,
      'releaseInterval1': releaseInterval1.inSeconds,
      'emission2Duration': emission2Duration.inSeconds,
      'releaseInterval2': releaseInterval2.inSeconds,
      'isRelease1Active': isRelease1Active ? 1 : 0,
      'isRelease2Active': isRelease2Active ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
    };
  }

  factory Necklace.fromMap(Map<String, dynamic> map) {
    return Necklace(
      id: map['id'],
      name: map['name'],
      bleDevice: map['bleDevice'],
      autoTurnOffEnabled: map['autoTurnOffEnabled'] == 1,
      periodicEmissionEnabled: map['periodicEmissionEnabled'] == 1,
      emission1Duration: Duration(seconds: map['emission1Duration']),
      releaseInterval1: Duration(seconds: map['releaseInterval1']),
      emission2Duration: Duration(seconds: map['emission2Duration']),
      releaseInterval2: Duration(seconds: map['releaseInterval2']),
      isRelease1Active: map['isRelease1Active'] == 1,
      isRelease2Active: map['isRelease2Active'] == 1,
      isArchived: map['isArchived'] == 1,
    );
  }
}