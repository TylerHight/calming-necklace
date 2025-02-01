// lib/features/necklaces_screen/blocs/timed_toggle_button/timed_toggle_button_event.dart

part of 'timed_toggle_button_bloc.dart';

abstract class TimedToggleButtonEvent extends Equatable {
  const TimedToggleButtonEvent();

  @override
  List<Object> get props => [];
}

class ToggleLightEvent extends TimedToggleButtonEvent {}

class _TimerTicked extends TimedToggleButtonEvent {
  final int duration;
  final bool isPeriodicEmission;

  const _TimerTicked({required this.duration, required this.isPeriodicEmission});

  @override
  List<Object> get props => [duration];
}

class _PeriodicEmissionTicked extends TimedToggleButtonEvent {
  final int duration;
  final int intervalDuration;

  const _PeriodicEmissionTicked({required this.duration, required this.intervalDuration});

  @override
  List<Object> get props => [duration];
}
