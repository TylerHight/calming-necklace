import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class UpdateNecklaceName extends SettingsEvent {
  final String name;
  const UpdateNecklaceName(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdatePeriodicEmission extends SettingsEvent {
  final bool enabled;
  final int scentNumber;
  const UpdatePeriodicEmission(this.enabled, this.scentNumber);

  @override
  List<Object?> get props => [enabled, scentNumber];
}

class UpdateEmissionDuration extends SettingsEvent {
  final Duration duration;
  final int scentNumber;
  const UpdateEmissionDuration(this.duration, this.scentNumber);

  @override
  List<Object?> get props => [duration, scentNumber];
}

class UpdateReleaseInterval extends SettingsEvent {
  final Duration interval;
  final int scentNumber;
  const UpdateReleaseInterval(this.interval, this.scentNumber);

  @override
  List<Object?> get props => [interval, scentNumber];
}

class DeleteNecklace extends SettingsEvent {
  final String id;
  const DeleteNecklace(this.id);
}

// State
class SettingsState extends Equatable {
  final Necklace necklace;
  final bool isSaving;
  final String? error;

  const SettingsState({
    required this.necklace,
    this.isSaving = false,
    this.error,
  });

  SettingsState copyWith({
    Necklace? necklace,
    bool? isSaving,
    String? error,
  }) {
    return SettingsState(
      necklace: necklace ?? this.necklace,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }

  @override
  List<Object?> get props => [necklace, isSaving, error];
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final NecklaceRepository _repository;

  SettingsBloc(Necklace necklace, this._repository) : super(SettingsState(necklace: necklace)) {
    on<UpdateNecklaceName>(_onUpdateName);
    on<UpdatePeriodicEmission>(_onUpdatePeriodicEmission);
    on<UpdateEmissionDuration>(_onUpdateEmissionDuration);
    on<UpdateReleaseInterval>(_onUpdateReleaseInterval);
    on<DeleteNecklace>(_onDeleteNecklace);
  }

  void _onUpdateName(UpdateNecklaceName event, Emitter<SettingsState> emit) {
    final updatedNecklace = Necklace(
      id: state.necklace.id,
      name: event.name,
      bleDevice: state.necklace.bleDevice,
      emission1Duration: state.necklace.emission1Duration,
      emission2Duration: state.necklace.emission2Duration,
      releaseInterval1: state.necklace.releaseInterval1,
      releaseInterval2: state.necklace.releaseInterval2,
    );
    emit(state.copyWith(necklace: updatedNecklace));
  }

  void _onUpdatePeriodicEmission(UpdatePeriodicEmission event, Emitter<SettingsState> emit) {
    final updatedNecklace = event.scentNumber == 1
        ? Necklace(
            id: state.necklace.id,
            name: state.necklace.name,
            bleDevice: state.necklace.bleDevice,
            periodicEmissionEnabled: event.enabled,
            emission1Duration: state.necklace.emission1Duration,
            emission2Duration: state.necklace.emission2Duration,
            releaseInterval1: state.necklace.releaseInterval1,
            releaseInterval2: state.necklace.releaseInterval2,
          )
        : Necklace(
            id: state.necklace.id,
            name: state.necklace.name,
            bleDevice: state.necklace.bleDevice,
            periodicEmissionEnabled: event.enabled,
            emission1Duration: state.necklace.emission1Duration,
            emission2Duration: state.necklace.emission2Duration,
            releaseInterval1: state.necklace.releaseInterval1,
            releaseInterval2: state.necklace.releaseInterval2,
          );
    emit(state.copyWith(necklace: updatedNecklace));
  }

  void _onUpdateEmissionDuration(UpdateEmissionDuration event, Emitter<SettingsState> emit) {
    final updatedNecklace = event.scentNumber == 1
        ? Necklace(
            id: state.necklace.id,
            name: state.necklace.name,
            bleDevice: state.necklace.bleDevice,
            emission1Duration: event.duration,
            emission2Duration: state.necklace.emission2Duration,
            releaseInterval1: state.necklace.releaseInterval1,
            releaseInterval2: state.necklace.releaseInterval2,
          )
        : Necklace(
            id: state.necklace.id,
            name: state.necklace.name,
            bleDevice: state.necklace.bleDevice,
            emission1Duration: state.necklace.emission1Duration,
            emission2Duration: event.duration,
            releaseInterval1: state.necklace.releaseInterval1,
            releaseInterval2: state.necklace.releaseInterval2,
          );
    emit(state.copyWith(necklace: updatedNecklace));
  }

  void _onUpdateReleaseInterval(UpdateReleaseInterval event, Emitter<SettingsState> emit) {
    final updatedNecklace = event.scentNumber == 1
        ? Necklace(
            id: state.necklace.id,
            name: state.necklace.name,
            bleDevice: state.necklace.bleDevice,
            emission1Duration: state.necklace.emission1Duration,
            emission2Duration: state.necklace.emission2Duration,
            releaseInterval1: event.interval,
            releaseInterval2: state.necklace.releaseInterval2,
          )
        : Necklace(
            id: state.necklace.id,
            name: state.necklace.name,
            bleDevice: state.necklace.bleDevice,
            emission1Duration: state.necklace.emission1Duration,
            emission2Duration: state.necklace.emission2Duration,
            releaseInterval1: state.necklace.releaseInterval1,
            releaseInterval2: event.interval,
          );
    emit(state.copyWith(necklace: updatedNecklace));
  }

  Future<void> _onDeleteNecklace(DeleteNecklace event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(isSaving: true));
      await _repository.deleteNecklace(event.id);
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }
}
