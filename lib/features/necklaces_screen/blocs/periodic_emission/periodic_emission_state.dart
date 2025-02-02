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

  const PeriodicEmissionRunning({
    required this.intervalSecondsLeft,
    required this.totalInterval,
  });

  @override
  List<Object> get props => [intervalSecondsLeft, totalInterval];
}

class PeriodicEmissionStopped extends PeriodicEmissionState {}
