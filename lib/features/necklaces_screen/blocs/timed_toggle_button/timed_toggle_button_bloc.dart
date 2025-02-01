import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:calming_necklace/core/services/logging_service.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import 'ticker.dart';

part 'periodic_emission_ticker.dart';
part 'timed_toggle_button_event.dart';
part 'timed_toggle_button_state.dart';

class TimedToggleButtonBloc extends Bloc<TimedToggleButtonEvent, TimedToggleButtonState> {
  final NecklaceRepository _repository;
  final Necklace necklace;
  final Ticker _ticker;
  StreamSubscription<int>? _tickerSubscription;
  bool _isActive = false;
  final LoggingService _logger = LoggingService();
  StreamSubscription<int>? _periodicEmissionSubscription;
  PeriodicEmissionTicker? _periodicEmissionTicker;

  TimedToggleButtonBloc({
    required NecklaceRepository repository,
    required this.necklace,
  }) : _repository = repository,
       _ticker = const Ticker(),
       super(TimedToggleButtonInitial()) {
    on<ToggleLightEvent>(_onToggleLight);
    on<_TimerTicked>(_onTimerTicked);
    on<_PeriodicEmissionTicked>(_onPeriodicEmissionTicked);
    _logger.logInfo('TimedToggleButtonBloc initialized');
  }

  Future<void> _onToggleLight(ToggleLightEvent event, Emitter<TimedToggleButtonState> emit) async {
    try {
      emit(TimedToggleButtonLoading());
      _logger.logDebug('Toggle light event received. Current state: ${state.runtimeType}');
      
      _isActive = !_isActive;
      if (_isActive) {
        await _repository.toggleLight(necklace, true);
        emit(LightOnState(necklace.emission1Duration.inSeconds));
        if (necklace.periodicEmissionEnabled) {
          _startPeriodicEmission(necklace.releaseInterval1.inSeconds);
        }
        _startTimer(necklace.emission1Duration.inSeconds);
        _logger.logDebug('Light turned on, timer started');
      } else {
        await _repository.toggleLight(necklace, false);
        _stopTimer(emit);
        _stopPeriodicEmission();
      }
      _logger.logDebug('Toggle light completed successfully');
    } catch (e) {
      _logger.logError('Error in _onToggleLight: $e');
      emit(TimedToggleButtonError(e.toString()));
    }
  }

  void _onTimerTicked(_TimerTicked event, Emitter<TimedToggleButtonState> emit) {
    emit(
      event.duration > 0
          ? LightOnState(event.duration)
          : LightOffState(),
    );
  }

  void _onPeriodicEmissionTicked(_PeriodicEmissionTicked event, Emitter<TimedToggleButtonState> emit) {
    emit(PeriodicEmissionState(event.duration));
    if (event.duration == 0) {
      add(ToggleLightEvent());
    }
  }

  void _startTimer(int duration) {
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: duration)
        .listen((duration) => add(_TimerTicked(duration: duration)));
  }

  void _stopTimer(Emitter<TimedToggleButtonState> emit) {
    _tickerSubscription?.cancel();
    emit(LightOffState());
    _logger.logInfo('Timer stopped and light turned off');
  }

  void _startPeriodicEmission(int interval) {
    _periodicEmissionTicker?.dispose();
    _periodicEmissionTicker = PeriodicEmissionTicker(interval: interval);
    _periodicEmissionSubscription = _periodicEmissionTicker?.tick().listen(
      (duration) => add(_PeriodicEmissionTicked(duration: duration))
    );
  }

  void _stopPeriodicEmission() {
    _periodicEmissionSubscription?.cancel();
    _periodicEmissionTicker?.dispose();
  }

  @override
  Future<void> close() {
    _stopPeriodicEmission();
    _tickerSubscription?.cancel();
    return super.close();
  }
}
