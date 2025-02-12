import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/logging_service.dart';

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
  final bool isValid;
  final LoggingService _logger = LoggingService.instance;

  DurationPickerState({
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
    this.isValid = true,
  }) : duration = Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
        );

  DurationPickerState copyWith({
    int? hours,
    int? minutes,
    int? seconds,
    bool? isValid,
  }) {
    return DurationPickerState(
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object> get props => [hours, minutes, seconds, duration, isValid];
}

// Bloc
class DurationPickerBloc extends Bloc<DurationPickerEvent, DurationPickerState> {
  DurationPickerBloc() : super(DurationPickerState(seconds: 10)) {
    on<UpdateHours>(_onUpdateHours);
    on<UpdateMinutes>(_onUpdateMinutes);
    on<UpdateSeconds>(_onUpdateSeconds);
  }

  void _onUpdateHours(UpdateHours event, Emitter<DurationPickerState> emit) {
    state._logger.logDebug('Updating hours to: ${event.hours}');
    if (event.hours >= 0) {
      emit(state.copyWith(hours: event.hours));
    }
  }

  void _onUpdateMinutes(UpdateMinutes event, Emitter<DurationPickerState> emit) {
    state._logger.logDebug('Updating minutes to: ${event.minutes}');
    emit(state.copyWith(minutes: event.minutes));
  }

  void _onUpdateSeconds(UpdateSeconds event, Emitter<DurationPickerState> emit) {
    state._logger.logDebug('Updating seconds to: ${event.seconds}');
    emit(state.copyWith(seconds: event.seconds));
  }
}
