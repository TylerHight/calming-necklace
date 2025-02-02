import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/services/logging_service.dart';

part 'periodic_emission_event.dart';
part 'periodic_emission_state.dart';

class PeriodicEmissionBloc extends Bloc<PeriodicEmissionEvent, PeriodicEmissionState> {
  final LoggingService _logger = LoggingService();
  Timer? _timer;
  final Necklace necklace;

  PeriodicEmissionBloc({required this.necklace}) 
      : super(PeriodicEmissionInitial()) {
    on<StartPeriodicEmission>(_onStartPeriodicEmission);
    on<StopPeriodicEmission>(_onStopPeriodicEmission);
    on<UpdateInterval>(_onUpdateInterval);
    on<TimerTick>(_onTimerTick);
  }

  void _onStartPeriodicEmission(
    StartPeriodicEmission event,
    Emitter<PeriodicEmissionState> emit,
  ) {
    if (!necklace.periodicEmissionEnabled) return;
    
    _startTimer();
    emit(PeriodicEmissionRunning(
      intervalSecondsLeft: necklace.releaseInterval1.inSeconds,
      totalInterval: necklace.releaseInterval1.inSeconds,
    ));
  }

  void _onStopPeriodicEmission(
    StopPeriodicEmission event,
    Emitter<PeriodicEmissionState> emit,
  ) {
    _timer?.cancel();
    emit(PeriodicEmissionStopped());
  }

  void _onUpdateInterval(
    UpdateInterval event,
    Emitter<PeriodicEmissionState> emit,
  ) {
    if (state is PeriodicEmissionRunning) {
      _timer?.cancel();
      _startTimer();
      emit(PeriodicEmissionRunning(
        intervalSecondsLeft: event.newInterval.inSeconds,
        totalInterval: event.newInterval.inSeconds,
      ));
    }
  }

  void _onTimerTick(TimerTick event, Emitter<PeriodicEmissionState> emit) {
    if (state is PeriodicEmissionRunning) {
      final currentState = state as PeriodicEmissionRunning;
      final newSecondsLeft = currentState.intervalSecondsLeft - 1;
      
      if (newSecondsLeft <= 0) {
        emit(PeriodicEmissionRunning(
          intervalSecondsLeft: currentState.totalInterval,
          totalInterval: currentState.totalInterval,
        ));
      } else {
        emit(PeriodicEmissionRunning(
          intervalSecondsLeft: newSecondsLeft,
          totalInterval: currentState.totalInterval,
        ));
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const TimerTick()),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
