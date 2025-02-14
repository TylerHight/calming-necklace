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
  bool _isClosed = false;
  final Ticker _ticker;
  bool _isTimerActive = false;
  bool _isProcessingToggle = false;
  StreamSubscription<int>? _tickerSubscription;
  bool _isActive = false;
  bool _isProcessingStateChange = false;
  bool _isPeriodicEmission = false;
  Timer? _stateRecoveryTimer;
  Duration? _currentDuration;
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
    _initializeDuration();
  }

  void _initializeFromNecklace() {
    _logger.logDebug('Initializing TimedToggleButtonBloc with necklace state: ${necklace.isLedOn}');
    _isActive = necklace.isLedOn;
    
    if (necklace.isLedOn && necklace.lastLEDStateChange != null) {
      final elapsedSeconds = DateTime.now().difference(necklace.lastLEDStateChange!).inSeconds;
      final remainingSeconds = necklace.emission1Duration.inSeconds - elapsedSeconds;
      if (remainingSeconds > 0) {
        _startTimer(remainingSeconds);
      }
    }
  }
  
  Future<void> _initializeDuration() async {
    try {
      final updatedNecklace = await _repository.getNecklaceById(necklace.id);
      _currentDuration = updatedNecklace?.emission1Duration;
    } catch (e) {
      _logger.logError('Error initializing duration: $e');
    }
  }

  Future<void> _onToggleLight(ToggleLightEvent event, Emitter<TimedToggleButtonState> emit) async {
    try {
      if (_isProcessingToggle) return;
      _isProcessingToggle = true;
      
      if (_isTimerActive) {
        await _stopTimer(emit);
        return;
      }
      
      _logger.logDebug('Processing toggle event');
      emit(TimedToggleButtonLoading());
      
      _isActive = !_isActive;
      if (_isActive) {
        _logger.logDebug('Attempting to turn light on');
        await _repository.toggleLight(necklace, true);
        emit(LightOnState(_currentDuration?.inSeconds ?? 3));
        _startTimer(_currentDuration?.inSeconds ?? 3);
      } else {
        _logger.logDebug('Attempting to turn light off');
        if (necklace.periodicEmissionEnabled) {
          await _repository.toggleLight(necklace, false);
        }
        _stopTimer(emit);
      }
      _logger.logDebug('Toggle light completed successfully');
    } catch (e) {
      _isProcessingToggle = false;
      _logger.logError('Error in _onToggleLight: $e');
      emit(TimedToggleButtonError(e.toString()));
      _scheduleStateRecovery();
    } finally {
      _isProcessingToggle = false;
    }
  }

  void _onTimerTicked(_TimerTicked event, Emitter<TimedToggleButtonState> emit) {
    if (event.duration > 0) {
      emit(LightOnState(event.duration));
    } else if (_isTimerActive) {
      _isTimerActive = false;
      _repository.completeEmission(necklace.id).then((_) => emit(LightOffState()));
      _stopTimer(emit);
    }
  }

  Future<void> _onPeriodicEmissionTriggered(
    _PeriodicEmissionTriggered event,
    Emitter<TimedToggleButtonState> emit,
  ) async {
    if (_isTimerActive) {
      _logger.logDebug('Ignoring periodic emission - timer already active');
      return;
    }
    
    _logger.logDebug('Handling periodic emission trigger');
    try {
      _isPeriodicEmission = true;
      _isActive = true;
      await _repository.toggleLight(necklace, true);
      emit(LightOnState(_currentDuration?.inSeconds ?? 0));
      _startTimer(_currentDuration?.inSeconds ?? 0, isPeriodicEmission: true);
    } catch (e) {
      _logger.logError('Error handling periodic emission trigger: $e');
      emit(TimedToggleButtonError(e.toString()));
    }
  }

  void _startTimer(int duration, {bool isPeriodicEmission = false}) {
    _tickerSubscription?.cancel();
    if (_isClosed) {
      _logger.logDebug('Cannot start timer - bloc is closed');
      return;
    }
    
    _isTimerActive = true;
    _tickerSubscription = _ticker
        .tick(ticks: duration)
        .listen(
          (duration) => !_isClosed ? add(_TimerTicked(duration: duration, isPeriodicEmission: isPeriodicEmission)) : null,
          onError: (error) => _logger.logError('Timer error: $error'));
  }

  Future<void> _stopTimer(Emitter<TimedToggleButtonState> emit) async {
    _tickerSubscription?.cancel();
    _isTimerActive = false;
    await _repository.toggleLight(necklace, false).then((_) => emit(LightOffState()));
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
    _isClosed = true;
    _isPeriodicEmission = false;
    _stateRecoveryTimer?.cancel();
    _emissionSubscription.cancel();
    return super.close();
  }
}
