import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/data/repositories/necklace_repository.dart';

part 'periodic_emission_event.dart';
part 'periodic_emission_state.dart';

class PeriodicEmissionBloc extends Bloc<PeriodicEmissionEvent, PeriodicEmissionState> {
  final LoggingService _logger = LoggingService();
  Timer? _timer;
  final Necklace necklace;
  final NecklaceRepository repository;
  bool _isPaused = false;

  PeriodicEmissionBloc({required this.necklace, required this.repository}) 
      : super(PeriodicEmissionInitial()) {
    on<StartPeriodicEmission>(_onStartPeriodicEmission);
    on<StopPeriodicEmission>(_onStopPeriodicEmission);
    on<InitializePeriodicEmission>(_onInitializePeriodicEmission);
    on<UpdateInterval>(_onUpdateInterval);
    on<TimerTick>(_onTimerTick);
    
    // Listen to emission events
    repository.periodicEmissionStream.listen((isEmitting) {
      if (isEmitting) {
        _isPaused = true;
      } else {
        _isPaused = false;
      }
    });
  }

  void _onStartPeriodicEmission(
    StartPeriodicEmission event,
    Emitter<PeriodicEmissionState> emit,
  ) {
    _logger.logDebug('Starting periodic emission');
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
    _logger.logDebug('Stopping periodic emission');
    _timer?.cancel();
    emit(PeriodicEmissionStopped());
  }

  void _onInitializePeriodicEmission(
    InitializePeriodicEmission event,
    Emitter<PeriodicEmissionState> emit,
  ) {
    if (necklace.periodicEmissionEnabled) {
      add(const StartPeriodicEmission());
    }
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
      
      if (_isPaused) {
        emit(PeriodicEmissionRunning(intervalSecondsLeft: currentState.intervalSecondsLeft, totalInterval: currentState.totalInterval, isPaused: true));
      } else if (newSecondsLeft <= 0) {
        _logger.logDebug('Periodic emission timer reached zero, triggering emission');
        repository.triggerPeriodicEmission();
        emit(PeriodicEmissionRunning(
          intervalSecondsLeft: currentState.totalInterval,
          isPaused: false,
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
