import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import '../timed_toggle_button/timed_toggle_button_bloc.dart';

part 'periodic_emission_event.dart';
part 'periodic_emission_state.dart';

class PeriodicEmissionBloc extends Bloc<PeriodicEmissionEvent, PeriodicEmissionState> {
  final LoggingService _logger = LoggingService();
  Timer? _timer;
  final Necklace necklace;
  final NecklaceRepository repository;
  late final StreamSubscription<bool> _emissionSubscription;

  PeriodicEmissionBloc({required this.necklace, required this.repository}) 
      : super(PeriodicEmissionInitial()) {
    on<StartPeriodicEmission>(_onStartPeriodicEmission);
    on<StopPeriodicEmission>(_onStopPeriodicEmission);
    on<InitializePeriodicEmission>(_onInitializePeriodicEmission);
    on<UpdateInterval>(_onUpdateInterval);
    on<TimerTick>(_onTimerTick);
    on<EmissionComplete>(_onEmissionComplete);
    
    _emissionSubscription = repository.getEmissionStream(necklace.id).listen(_handleEmissionTrigger);
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
      isEmissionActive: false,
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
        isEmissionActive: false,
      ));
    }
  }

  void _onTimerTick(TimerTick event, Emitter<PeriodicEmissionState> emit) {
    if (state is PeriodicEmissionRunning) {
      final currentState = state as PeriodicEmissionRunning;
      final newSecondsLeft = currentState.intervalSecondsLeft - 1;
      
      if (newSecondsLeft <= 0) {
        _logger.logDebug('Timer reached zero, triggering emission');
        repository.triggerEmission(necklace.id);
        emit(PeriodicEmissionRunning(
          intervalSecondsLeft: currentState.totalInterval,
          totalInterval: currentState.totalInterval,
          isEmissionActive: true,
        ));
        Future.delayed(necklace.emission1Duration, () => add(const EmissionComplete()));
      } else {
        emit(PeriodicEmissionRunning(
          intervalSecondsLeft: newSecondsLeft,
          totalInterval: currentState.totalInterval,
          isEmissionActive: currentState.isEmissionActive,
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

  void _onEmissionComplete(EmissionComplete event, Emitter<PeriodicEmissionState> emit) {
    if (state is PeriodicEmissionRunning) {
      final currentState = state as PeriodicEmissionRunning;
      emit(PeriodicEmissionRunning(
        intervalSecondsLeft: currentState.intervalSecondsLeft,
        totalInterval: currentState.totalInterval,
        isEmissionActive: false,
      ));
    }
  }

  void _handleEmissionTrigger(bool isTriggered) {
    if (isTriggered) {
      _timer?.cancel();
    } else {
      if (necklace.periodicEmissionEnabled) {
        _startTimer();
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _emissionSubscription.cancel();
    return super.close();
  }
}
