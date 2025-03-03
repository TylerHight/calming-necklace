import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:calming_necklace/core/services/logging_service.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../../../core/services/ble/ble_types.dart';
import 'ticker.dart';
import '../periodic_emission/periodic_emission_bloc.dart';

part 'timed_toggle_button_event.dart';
part 'timed_toggle_button_state.dart';
part 'periodic_emission_ticker.dart';

class TimedToggleButtonBloc extends Bloc<TimedToggleButtonEvent, TimedToggleButtonState> {
  final NecklaceRepository _repository;
  final Necklace necklace;
  bool _isClosed = false;
  bool _isTimerActive = false;
  bool _isProcessingToggle = false;
  StreamSubscription<int>? _tickerSubscription;
  bool _isActive = false;
  bool _isPeriodicEmission = false;
  Timer? _stateRecoveryTimer;
  Duration? _currentDuration;
  late final StreamSubscription<bool> _emissionSubscription;
  final LoggingService _logger = LoggingService.instance;
  final Ticker _ticker;

  TimedToggleButtonBloc({
    required NecklaceRepository repository,
    required this.necklace,
  }) : _repository = repository,
        _ticker = Ticker(),
        super(TimedToggleButtonInitial()) {
    _initializeFromNecklace();
    on<InitializeTimedToggleButton>(_onInitialize);
    on<StartPeriodicEmission>(_onStartPeriodicEmission);
    on<StopPeriodicEmission>(_onStopPeriodicEmission);
    on<ToggleLightEvent>(_onToggleLight);
    on<_TimerTicked>(_onTimerTicked);
    on<_PeriodicEmissionTriggered>(_onPeriodicEmissionTriggered);
    on<ToggleLightLoadingEvent>(_onToggleLightLoading);
    on<ToggleLightErrorEvent>(_onToggleLightError);

    _emissionSubscription = _repository.getEmissionStream(necklace.id).listen(_handleEmissionTrigger);
    _initializeDuration();
    _initializeLogger();
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
    
    emit(TimedToggleButtonInitialized());
  }

  Future<void> _onInitialize(InitializeTimedToggleButton event, Emitter<TimedToggleButtonState> emit) async {
    _initializeFromNecklace();
  }
  
  Future<void> _initializeDuration() async {
    try {
      final updatedNecklace = await _repository.getNecklaceById(necklace.id);
      _currentDuration = updatedNecklace?.emission1Duration;
    } catch (e) {
      _logger.logError('Error initializing duration: $e');
    }
  }

  Future<void> _initializeLogger() async {
    try {
      final logger = await LoggingService.getInstance();
    } catch (e) {
      print('Error initializing logger: $e');
    }
  }

  Future<void> _onToggleLight(ToggleLightEvent event, Emitter<TimedToggleButtonState> emit) async {
    try {
      await _ensureConnection();
      _logger.logDebug('Connection verified before toggle');
      if (_isProcessingToggle) return;
      if (emit.isDone) return; // Guard against emit after completion
      _isProcessingToggle = true;

      if (_isTimerActive) {
        _isProcessingToggle = true;
        await _stopTimer(emit);
        _isProcessingToggle = false;
        return; // Early return after stopping timer
      }

      _logger.logDebug('Processing toggle event');
      emit(TimedToggleButtonLoading());

      _isActive = !_isActive;
      if (_isActive) {
        await _repository.toggleLight(necklace, true);
        await _verifyLightState(true);
        _logger.logDebug('Attempting to turn light on');
        // Confirm the LED state change
        final updatedNecklace = await _repository.getNecklaceById(necklace.id);
        if (updatedNecklace?.isLedOn == true) {
          if (!emit.isDone) {
            emit(LightOnState(_currentDuration?.inSeconds ?? 3));
            _startTimer(_currentDuration?.inSeconds ?? 3);
          }
        } else {
          _logger.logError('Failed to turn light on');
          emit(TimedToggleButtonError('Failed to turn light on'));
        }
      } else {
        await _repository.toggleLight(necklace, false);
        await _verifyLightState(false);
        _logger.logDebug('Attempting to turn light off');
        if (!emit.isDone) {
          await _stopTimer(emit);
        }
      }
      _logger.logDebug('Toggle light completed successfully');
    } catch (e) {
      _isProcessingToggle = false;
      _logger.logError('Error in _onToggleLight: $e');
      await _attemptStateRecovery();
      emit(TimedToggleButtonError(e.toString()));
    } finally {
      _isProcessingToggle = false;
    }
  }

  void _onTimerTicked(_TimerTicked event, Emitter<TimedToggleButtonState> emit) async {
    if (event.duration > 0) {
      emit(LightOnState(event.duration));
      _isActive = true;
    } else if (_isTimerActive) {
      _isTimerActive = false;
      _isActive = false;
      if (!emit.isDone) emit(LightOffState());
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
      if (!emit.isDone) {
        emit(LightOnState(_currentDuration?.inSeconds ?? 0));
        _startTimer(_currentDuration?.inSeconds ?? 0, isPeriodicEmission: true);
      }
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
    _isActive = false;
    if (!emit.isDone) emit(LightOffState());
    _logger.logInfo('Timer stopped');
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

  Future<void> _ensureConnection() async {
    try {
      final bleState = await _repository.getNecklaceById(necklace.id);
      if (bleState == null) {
        _logger.logDebug('Connection lost - waiting for reconnection');
        // Wait for connection to be re-established
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      _logger.logError('Error ensuring connection: $e');
      throw BleException('Device connection error: $e');
    }
  }

  void _onToggleLightLoading(ToggleLightLoadingEvent event, Emitter<TimedToggleButtonState> emit) {
    emit(TimedToggleButtonLoading());
  }

  void _onToggleLightError(ToggleLightErrorEvent event, Emitter<TimedToggleButtonState> emit) {
    _isProcessingToggle = false;
    _logger.logError('Toggle light error: ${event.error}');
    emit(TimedToggleButtonError(event.error));
  }

  Future<void> _verifyLightState(bool expectedState) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      final necklaceState = await _repository.getNecklaceById(necklace.id);
      if (necklaceState?.isLedOn == expectedState) return;
      
      attempts++;
      _logger.logWarning('Light state verification failed, attempt $attempts of $maxAttempts');
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    throw BleException('Failed to verify light state after $maxAttempts attempts');
  }

  Future<void> _attemptStateRecovery() async {
    _logger.logDebug('Attempting state recovery');
    try {
      await _repository.toggleLight(necklace, false);
      _isActive = false;
      _isTimerActive = false;
    } catch (e) {
      _logger.logError('State recovery failed: $e');
    }
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
