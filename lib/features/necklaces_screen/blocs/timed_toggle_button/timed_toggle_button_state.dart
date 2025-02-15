part of 'timed_toggle_button_bloc.dart';

abstract class TimedToggleButtonState extends Equatable {
  const TimedToggleButtonState();

  @override
  List<Object> get props => [];
}

class TimedToggleButtonInitial extends TimedToggleButtonState {}

class TimedToggleButtonInitialized extends TimedToggleButtonState {}

class TimedToggleButtonLoading extends TimedToggleButtonState {}

class TimedToggleButtonError extends TimedToggleButtonState {
  final String message;

  const TimedToggleButtonError(this.message);

  @override
  List<Object> get props => [message];
}

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
  final int intervalSecondsLeft;
  final bool isEmitting;

  const PeriodicEmissionState(this.secondsLeft, 
      {this.isEmitting = false, this.intervalSecondsLeft = 0});

  @override
  List<Object> get props => [secondsLeft, isEmitting, intervalSecondsLeft];
}
