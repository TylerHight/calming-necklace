part of 'periodic_emission_bloc.dart';

abstract class PeriodicEmissionEvent extends Equatable {
  const PeriodicEmissionEvent();

  @override
  List<Object> get props => [];
}

class StartPeriodicEmission extends PeriodicEmissionEvent {
  const StartPeriodicEmission();
}

class StopPeriodicEmission extends PeriodicEmissionEvent {
  const StopPeriodicEmission();
}

class UpdateInterval extends PeriodicEmissionEvent {
  final Duration newInterval;

  const UpdateInterval(this.newInterval);

  @override
  List<Object> get props => [newInterval];
}

class TimerTick extends PeriodicEmissionEvent {
  const TimerTick();
}
