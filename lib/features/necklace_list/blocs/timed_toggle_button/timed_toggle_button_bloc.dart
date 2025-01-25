import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'ticker.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/blocs/ble_connection/ble_connection_bloc.dart';
import 'dart:async';
import 'package:calming_necklace/core/services/logging_service.dart';

part 'timed_toggle_button_event.dart';
part 'timed_toggle_button_state.dart';

class TimedToggleButtonBloc extends Bloc<TimedToggleButtonEvent, TimedToggleButtonState> {
  final BleConnectionBloc bleConnectionBloc;
  final Necklace necklace;
  final Ticker _ticker;
  StreamSubscription<int>? _tickerSubscription;
  final LoggingService _logger = LoggingService();

  TimedToggleButtonBloc({
    required this.bleConnectionBloc, 
    required this.necklace,
  }) : _ticker = const Ticker(),
       super(TimedToggleButtonInitial()) {
    on<ToggleLightEvent>(_onToggleLight);
    on<_TimerTicked>(_onTimerTicked);
    _logger.logInfo('TimedToggleButtonBloc initialized');
  }

  void _onToggleLight(ToggleLightEvent event, Emitter<TimedToggleButtonState> emit) {
    _logger.logDebug('ToggleLightEvent received');
    if (state is LightOffState || state is TimedToggleButtonInitial) {
      emit(LightOnState(necklace.emission1Duration.inSeconds));
      _tickerSubscription?.cancel();
      _tickerSubscription = _ticker
          .tick(ticks: necklace.emission1Duration.inSeconds)
          .listen(
            (duration) => add(_TimerTicked(duration: duration)),
          );
    } else {
      _stopTimer(emit);
    }
  }

  void _onTimerTicked(_TimerTicked event, Emitter<TimedToggleButtonState> emit) {
    emit(
      event.duration > 0
          ? LightOnState(event.duration)
          : LightOffState(),
    );
  }

  void _stopTimer(Emitter<TimedToggleButtonState> emit) {
    _tickerSubscription?.cancel();
    emit(LightOffState());
    _logger.logInfo('Timer stopped and light turned off');
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}
