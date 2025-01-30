import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class DurationPickerEvent extends Equatable {
  const DurationPickerEvent();

  @override
  List<Object> get props => [];
}

class UpdateHours extends DurationPickerEvent {
  final int hours;
  const UpdateHours(this.hours);

  @override
  List<Object> get props => [hours];
}

class UpdateMinutes extends DurationPickerEvent {
  final int minutes;
  const UpdateMinutes(this.minutes);

  @override
  List<Object> get props => [minutes];
}

class UpdateSeconds extends DurationPickerEvent {
  final int seconds;
  const UpdateSeconds(this.seconds);

  @override
  List<Object> get props => [seconds];
}

// State
class DurationPickerState extends Equatable {
  final int hours;
  final int minutes;
  final int seconds;
  final Duration duration;

  DurationPickerState({
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
  }) : duration = Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
        );

  DurationPickerState copyWith({
    int? hours,
    int? minutes,
    int? seconds,
  }) {
    return DurationPickerState(
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
    );
  }

  @override
  List<Object> get props => [hours, minutes, seconds, duration];
}

// Bloc
class DurationPickerBloc extends Bloc<DurationPickerEvent, DurationPickerState> {
  DurationPickerBloc() : super(DurationPickerState()) {
    on<UpdateHours>(_onUpdateHours);
    on<UpdateMinutes>(_onUpdateMinutes);
    on<UpdateSeconds>(_onUpdateSeconds);
  }

  void _onUpdateHours(UpdateHours event, Emitter<DurationPickerState> emit) {
    emit(state.copyWith(hours: event.hours));
  }

  void _onUpdateMinutes(UpdateMinutes event, Emitter<DurationPickerState> emit) {
    emit(state.copyWith(minutes: event.minutes));
  }

  void _onUpdateSeconds(UpdateSeconds event, Emitter<DurationPickerState> emit) {
    emit(state.copyWith(seconds: event.seconds));
  }
}
