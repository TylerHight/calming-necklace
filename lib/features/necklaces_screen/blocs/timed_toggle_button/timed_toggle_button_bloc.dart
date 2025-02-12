import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:calming_necklace/core/services/logging_service.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import 'package:stream_transform/stream_transform.dart';
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
  bool _isProcessingStateChange = false;
  bool _isPeriodicEmission = false;
  Timer? _stateRecoveryTimer;
  late final StreamSubscription<bool> _emissionSubscription;
  final LoggingService _logger = LoggingService.instance;

  TimedToggleButtonBloc({
    required NecklaceRepository repository,
    required this.necklace,
  }) : _repository = repository,
       _ticker = const Ticker(),
       super(TimedToggleButtonInitial()) {
    _initializeFromNecklace();
    on<StartPeriodicEmission>(_onStartPeriodicEmission);
    on<StopPeriodicEmission>(_onStopPeriodicEmission);
    on<ToggleLightEvent>(_onToggleLight);
    on<_TimerTicked>(_onTimerTicked);
    on<_PeriodicEmissionTriggered>(_onPeriodicEmissionTriggered);

    _emissionSubscription = _repository.getEmissionStream(necklace.id).listen(_handleEmissionTrigger);
  }

  void _initializeFromNecklace() {
    _logger.logDebug('Initializing TimedToggleButtonBloc with necklace state: ${necklace.isLedOn}');
    _isActive = necklace.isLedOn;
    if (necklace.isLedOn) {
      emit(LightOnState(necklace.emission1Duration.inSeconds));
      _startTimer(necklace.emission1Duration.inSeconds);
    }
  }

  Future<void> _onToggleLight(ToggleLightEvent event, Emitter<TimedToggleButtonState> emit) async {
    try {
      if (_isProcessingStateChange) {
        _logger.logDebug('Ignoring toggle event - already processing state change');
        return;
      }
      _isProcessingStateChange = true;
      _cancelStateRecovery();
      
      _logger.logDebug('Processing toggle event. Current state: ${state.runtimeType}, isActive: $_isActive');
      emit(TimedToggleButtonLoading());
      
      _isActive = !_isActive;
      if (_isActive) {
        _logger.logDebug('Attempting to turn light on');
        await _repository.toggleLight(necklace, true);
        emit(LightOnState(necklace.emission1Duration.inSeconds));
        _startTimer(necklace.emission1Duration.inSeconds);
      } else {
        _logger.logDebug('Attempting to turn light off');
        if (necklace.periodicEmissionEnabled) {
          await _repository.toggleLight(necklace, false);
        }
        _stopTimer(emit);
      }
      _logger.logDebug('Toggle light completed successfully');
    } catch (e) {
      _isProcessingStateChange = false;
      _logger.logError('Error in _onToggleLight: $e');
      emit(TimedToggleButtonError(e.toString()));
      _scheduleStateRecovery();
    } finally {
      _isProcessingStateChange = false;
    }
  }

  void _onTimerTicked(_TimerTicked event, Emitter<TimedToggleButtonState> emit) {
    if (event.duration > 0) {
      emit(LightOnState(event.duration));
    } else {
      _repository.completeEmission(necklace.id);
      emit(LightOffState());
    }
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

  Future<void> _onStartPeriodicEmission(
    StartPeriodicEmission event,
    Emitter<TimedToggleButtonState> emit,
  ) async {
    try {
      _isPeriodicEmission = true;
      await _repository.toggleLight(necklace, true);
      _startTimer(event.duration);
      emit(LightOnState(event.duration));
    } catch (e) {
      emit(TimedToggleButtonError(e.toString()));
    }
  }

  void _onStopPeriodicEmission(StopPeriodicEmission event, Emitter<TimedToggleButtonState> emit) {
    _stopTimer(emit);
    _isPeriodicEmission = false;
  }

  void _handleEmissionTrigger(bool isTriggered) {
    if (isTriggered) {
      add(const _PeriodicEmissionTriggered());
    }
  }

  void _scheduleStateRecovery() {
    _stateRecoveryTimer?.cancel();
    _stateRecoveryTimer = Timer(const Duration(seconds: 5), () {
      if (state is TimedToggleButtonError) {
        add(ToggleLightEvent());
      }
    });
  }

  void _cancelStateRecovery() {
    _stateRecoveryTimer?.cancel();
    _stateRecoveryTimer = null;
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    _logger.logError('TimedToggleButtonBloc error: $error\n$stackTrace');
    super.onError(error, stackTrace);
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    _isPeriodicEmission = false;
    _stateRecoveryTimer?.cancel();
    _emissionSubscription.cancel();
    return super.close();
  }
}
