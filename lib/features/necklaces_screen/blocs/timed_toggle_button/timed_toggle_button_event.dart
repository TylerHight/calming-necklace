// lib/features/necklaces_screen/blocs/timed_toggle_button/timed_toggle_button_event.dart

part of 'timed_toggle_button_bloc.dart';

abstract class TimedToggleButtonEvent extends Equatable {
  const TimedToggleButtonEvent();

  @override
  List<Object> get props => [];
}

class InitializeTimedToggleButton extends TimedToggleButtonEvent {
  const InitializeTimedToggleButton();
}

class ToggleLightEvent extends TimedToggleButtonEvent {
  const ToggleLightEvent();
}

class ToggleLightLoadingEvent extends TimedToggleButtonEvent {
  const ToggleLightLoadingEvent();
}

class ToggleLightErrorEvent extends TimedToggleButtonEvent {
  final String error;
  const ToggleLightErrorEvent(this.error);

  @override
  List<Object> get props => [error];
}

class StartPeriodicEmission extends TimedToggleButtonEvent {
  final int duration;
  const StartPeriodicEmission({required this.duration});

  @override
  List<Object> get props => [duration];
}

class StopPeriodicEmission extends TimedToggleButtonEvent {
  const StopPeriodicEmission();
}

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
  List<Object> get props => [duration, intervalDuration];
}

class _PeriodicEmissionTriggered extends TimedToggleButtonEvent {
  const _PeriodicEmissionTriggered();
}