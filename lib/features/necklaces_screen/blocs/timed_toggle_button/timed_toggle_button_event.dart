// lib/features/necklaces_screen/blocs/timed_toggle_button/timed_toggle_button_event.dart

part of 'timed_toggle_button_bloc.dart';

abstract class TimedToggleButtonEvent extends Equatable {
  const TimedToggleButtonEvent();

  @override
  List<Object> get props => [];
}

class ToggleLightEvent extends TimedToggleButtonEvent {}

class _TimerTicked extends TimedToggleButtonEvent {
  const _TimerTicked({required this.duration});
  final int duration;

  @override
  List<Object> get props => [duration];
}
