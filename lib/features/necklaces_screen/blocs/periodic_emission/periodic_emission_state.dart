part of 'periodic_emission_bloc.dart';

abstract class PeriodicEmissionState extends Equatable {
  const PeriodicEmissionState();

  @override
  List<Object> get props => [];
}

class PeriodicEmissionInitial extends PeriodicEmissionState {}

class PeriodicEmissionRunning extends PeriodicEmissionState {
  final int intervalSecondsLeft;
  final int totalInterval;
  final bool isPaused;
  final bool isEmissionActive;

  const PeriodicEmissionRunning({
    required this.intervalSecondsLeft,
    required this.totalInterval,
    this.isPaused = false,
    this.isEmissionActive = false,
  });

  @override
  List<Object> get props => [intervalSecondsLeft, totalInterval, isPaused, isEmissionActive];
}

class PeriodicEmissionStopped extends PeriodicEmissionState {}
