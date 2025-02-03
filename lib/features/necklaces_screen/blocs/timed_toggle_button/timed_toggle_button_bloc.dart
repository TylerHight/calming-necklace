import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:calming_necklace/core/services/logging_service.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import 'ticker.dart';
import '../periodic_emission/periodic_emission_bloc.dart';

part 'timed_toggle_button_event.dart';
part 'timed_toggle_button_state.dart';
part 'periodic_emission_ticker.dart';

class TimedToggleButtonBloc extends Bloc<TimedToggleButtonEvent, TimedToggleButtonState> {
  final NecklaceRepository _repository;
  final Necklace necklace;
  final Ticker _ticker;
  StreamSubscription<int>? _tickerSubscription;
  bool _isActive = false;
  final LoggingService _logger = LoggingService();
  bool _isPeriodicEmission = false;
  StreamSubscription? _periodicEmissionSubscription;

  TimedToggleButtonBloc({
    required NecklaceRepository repository,
    required this.necklace,
  }) : _repository = repository,
       _ticker = const Ticker(),
       super(TimedToggleButtonInitial()) {
    on<ToggleLightEvent>(_onToggleLight);
    on<_TimerTicked>(_onTimerTicked);
    on<_PeriodicEmissionTriggered>(_onPeriodicEmissionTriggered);
    
    // Listen to periodic emission state changes
    if (necklace.periodicEmissionEnabled) {
      _periodicEmissionSubscription = _repository
          .periodicEmissionStream
          .listen((triggered) {
        _logger.logDebug('Received periodic emission trigger: $triggered');
        if (triggered) {
          add(_PeriodicEmissionTriggered());
        }
      });
    }
    _logger.logInfo('TimedToggleButtonBloc initialized');
  }

  Future<void> _onToggleLight(ToggleLightEvent event, Emitter<TimedToggleButtonState> emit) async {
    try {
      emit(TimedToggleButtonLoading());
      _logger.logDebug('Toggle light event received. Current state: ${state.runtimeType}');
      
      if (_isPeriodicEmission) {
        // If currently in periodic emission, stop it
        _isPeriodicEmission = false;
        _isActive = false;
        await _repository.toggleLight(necklace, false);
        _stopTimer(emit);
      } else {
        // Normal toggle behavior
        _isActive = !_isActive;
        if (_isActive) {
          await _repository.toggleLight(necklace, true);
          emit(LightOnState(necklace.emission1Duration.inSeconds));
          _startTimer(necklace.emission1Duration.inSeconds);
        } else {
          if (necklace.periodicEmissionEnabled) {
            await _repository.toggleLight(necklace, false);
          }
          _stopTimer(emit);
        }
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

  Future<void> _onPeriodicEmissionTriggered(
    _PeriodicEmissionTriggered event,
    Emitter<TimedToggleButtonState> emit,
  ) async {
    _logger.logDebug('Handling periodic emission trigger');
    try {
      _isPeriodicEmission = true;
      _isActive = true;
      await _repository.toggleLight(necklace, true);
      emit(LightOnState(necklace.emission1Duration.inSeconds));
      _startTimer(necklace.emission1Duration.inSeconds, isPeriodicEmission: true);
    } catch (e) {
      _logger.logError('Error handling periodic emission trigger: $e');
      emit(TimedToggleButtonError(e.toString()));
    }
  }

  void _startTimer(int duration, {bool isPeriodicEmission = false}) {
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: duration)
        .listen((duration) => add(_TimerTicked(duration: duration, 
            isPeriodicEmission: isPeriodicEmission)));
  }

  void _stopTimer(Emitter<TimedToggleButtonState> emit) {
    _tickerSubscription?.cancel();
    emit(LightOffState());
    _logger.logInfo('Timer stopped and light turned off');
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    _periodicEmissionSubscription?.cancel();
    return super.close();
  }
}
