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

  Necklace copyWith({
    String? id,
    String? name,
    String? bleDevice,
    bool? autoTurnOffEnabled,
    bool? periodicEmissionEnabled,
    Duration? emission1Duration,
    Duration? releaseInterval1,
    Duration? emission2Duration,
    Duration? releaseInterval2,
    bool? isRelease1Active,
    bool? isRelease2Active,
    bool? isArchived,
  }) {
    return Necklace(
      id: id ?? this.id,
      name: name ?? this.name,
      bleDevice: bleDevice ?? this.bleDevice,
      autoTurnOffEnabled: autoTurnOffEnabled ?? this.autoTurnOffEnabled,
      periodicEmissionEnabled: periodicEmissionEnabled ?? this.periodicEmissionEnabled,
      emission1Duration: emission1Duration ?? this.emission1Duration,
      releaseInterval1: releaseInterval1 ?? this.releaseInterval1,
      emission2Duration: emission2Duration ?? this.emission2Duration,
      releaseInterval2: releaseInterval2 ?? this.releaseInterval2,
      isRelease1Active: isRelease1Active ?? this.isRelease1Active,
      isRelease2Active: isRelease2Active ?? this.isRelease2Active,
      isArchived: isArchived ?? this.isArchived,
    );
  }

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
      emission1Duration: Duration(seconds: map['emission1Duration'] ?? 5),
      releaseInterval1: Duration(minutes: map['releaseInterval1'] ?? 30),
      emission2Duration: Duration(seconds: map['emission2Duration'] ?? 10),
      releaseInterval2: Duration(minutes: map['releaseInterval2'] ?? 40),
      isRelease1Active: map['isRelease1Active'] == 1,
      isRelease2Active: map['isRelease2Active'] == 1,
      isArchived: map['isArchived'] == 1,
    );
  }
}