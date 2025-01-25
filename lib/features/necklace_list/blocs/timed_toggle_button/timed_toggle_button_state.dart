part of 'timed_toggle_button_bloc.dart';

abstract class TimedToggleButtonState extends Equatable {
  const TimedToggleButtonState();

  @override
  List<Object> get props => [];
}

class TimedToggleButtonInitial extends TimedToggleButtonState {}

class LightOffState extends TimedToggleButtonState {}

class LightOnState extends TimedToggleButtonState {
  final int secondsLeft;

  const LightOnState(this.secondsLeft);

  @override
  List<Object> get props => [secondsLeft];
}

class AutoTurnOffState extends LightOnState {
  const AutoTurnOffState(int secondsLeft) : super(secondsLeft);
}

class PeriodicEmissionState extends TimedToggleButtonState {
  final int secondsLeft;

  const PeriodicEmissionState(this.secondsLeft);

  @override
  List<Object> get props => [secondsLeft];
}