import 'package:equatable/equatable.dart';

class Necklace extends Equatable {
  final String id;
  final String name;
  final String description;
  final String color;
  final bool autoTurnOffEnabled;
  final bool periodicEmissionEnabled;
  final Duration emission1Duration;
  final Duration releaseInterval1;
  final Duration emission2Duration;
  final Duration releaseInterval2;
  final bool isRelease1Active;
  final bool isRelease2Active;

  Necklace({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.autoTurnOffEnabled = false,
    this.periodicEmissionEnabled = false,
    required this.emission1Duration,
    required this.releaseInterval1,
    required this.emission2Duration,
    required this.releaseInterval2,
    this.isRelease1Active = false,
    this.isRelease2Active = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    color,
    autoTurnOffEnabled,
    periodicEmissionEnabled,
    emission1Duration,
    releaseInterval1,
    emission2Duration,
    releaseInterval2,
    isRelease1Active,
    isRelease2Active,
  ];
}