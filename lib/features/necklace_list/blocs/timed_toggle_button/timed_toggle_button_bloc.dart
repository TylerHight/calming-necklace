import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/blocs/ble_connection/ble_connection_bloc.dart';

part 'timed_toggle_button_event.dart';
part 'timed_toggle_button_state.dart';

class TimedToggleButtonBloc extends Bloc<TimedToggleButtonEvent, TimedToggleButtonState> {
  final BleConnectionBloc bleConnectionBloc;
  final Necklace necklace;

  TimedToggleButtonBloc({required this.bleConnectionBloc, required this.necklace}) : super(TimedToggleButtonInitial()) {
    on<ToggleLightEvent>(_onToggleLight);
    on<AutoTurnOffEvent>(_onAutoTurnOff);
    on<PeriodicEmissionEvent>(_onPeriodicEmission);
  }

  Future<void> _onToggleLight(ToggleLightEvent event, Emitter<TimedToggleButtonState> emit) async {
    if (state is LightOffState) {
      emit(LightOnState(necklace.emission1Duration.inSeconds));
    } else {
      emit(LightOffState());
    }
  }

  void _onAutoTurnOff(AutoTurnOffEvent event, Emitter<TimedToggleButtonState> emit) {
    if (state is LightOnState) {
      emit(AutoTurnOffState(necklace.emission1Duration.inSeconds));
    }
  }

  void _onPeriodicEmission(PeriodicEmissionEvent event, Emitter<TimedToggleButtonState> emit) {
    if (state is LightOffState) {
      emit(PeriodicEmissionState(necklace.releaseInterval1.inSeconds));
    }
  }
}