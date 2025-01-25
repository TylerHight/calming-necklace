// lib/features/necklace_list/blocs/timed_toggle_button/timed_toggle_button_event.dart

part of 'timed_toggle_button_bloc.dart';

abstract class TimedToggleButtonEvent extends Equatable {
  const TimedToggleButtonEvent();

  @override
  List<Object> get props => [];
}

class ToggleLightEvent extends TimedToggleButtonEvent {}

class AutoTurnOffEvent extends TimedToggleButtonEvent {}

class PeriodicEmissionEvent extends TimedToggleButtonEvent {}