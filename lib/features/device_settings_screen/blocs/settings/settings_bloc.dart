import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/logging_service.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SaveSettings extends SettingsEvent {
  const SaveSettings();

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
  const UpdatePeriodicEmission(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateEmissionDuration extends SettingsEvent {
  final Duration duration;
  const UpdateEmissionDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

class UpdateReleaseInterval extends SettingsEvent {
  final Duration interval;
  final int scentNumber;
  const UpdateReleaseInterval(this.interval, this.scentNumber);

  @override
  List<Object?> get props => [interval, scentNumber];
}

class ArchiveNecklace extends SettingsEvent {
  final String id;
  const ArchiveNecklace(this.id);
}

class RefreshSettings extends SettingsEvent {
  final Necklace necklace;
  const RefreshSettings(this.necklace);
  @override
  List<Object?> get props => [necklace];
}

// State
class SettingsState extends Equatable {
  final Necklace necklace;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const SettingsState({
    required this.necklace,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  SettingsState copyWith({
    Necklace? necklace,
    bool? isSaving,
    bool? isSaved,
    String? error,
  }) {
    return SettingsState(
      necklace: necklace ?? this.necklace,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: error,
    );
  }

  @override
  List<Object?> get props => [necklace, isSaving, isSaved, error];
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final NecklaceRepository _repository;
  final DatabaseService _databaseService;
  final LoggingService _logger = LoggingService();

  SettingsBloc(Necklace necklace, this._repository, this._databaseService) 
      : super(SettingsState(necklace: necklace)) {
    on<UpdateNecklaceName>(_onUpdateName);
    on<UpdatePeriodicEmission>(_onUpdatePeriodicEmission);
    on<UpdateEmissionDuration>(_onUpdateEmissionDuration);
    on<UpdateReleaseInterval>(_onUpdateReleaseInterval);
    on<ArchiveNecklace>(_onArchiveNecklace);
    on<SaveSettings>(_onSaveSettings);
    on<RefreshSettings>(_onRefreshSettings);
  }

  Future<void> _onSaveSettings(
      SaveSettings event,
      Emitter<SettingsState> emit,
      ) async {
    try {
      await _databaseService.updateNecklaceSettings(
        state.necklace.id,
        state.necklace.toMap(),
      );
      emit(state.copyWith(isSaved: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onUpdateName(UpdateNecklaceName event, Emitter<SettingsState> emit) {
    final updatedNecklace = Necklace(
      id: state.necklace.id,
      name: event.name,
      bleDevice: state.necklace.bleDevice,
      emission1Duration: state.necklace.emission1Duration,
      releaseInterval1: state.necklace.releaseInterval1,
      isRelease1Active: state.necklace.isRelease1Active,
      isArchived: state.necklace.isArchived,
    );
    emit(state.copyWith(necklace: updatedNecklace));
  }

  void _onUpdatePeriodicEmission(UpdatePeriodicEmission event, Emitter<SettingsState> emit) {
    final updatedNecklace = Necklace(
      id: state.necklace.id,
      name: state.necklace.name,
      bleDevice: state.necklace.bleDevice,
      periodicEmissionEnabled: event.enabled,
      emission1Duration: state.necklace.emission1Duration,
      releaseInterval1: state.necklace.releaseInterval1,
      isRelease1Active: state.necklace.isRelease1Active,
      isArchived: state.necklace.isArchived,
    );
    emit(state.copyWith(necklace: updatedNecklace));
  }

  void _onUpdateEmissionDuration(
      UpdateEmissionDuration event,
      Emitter<SettingsState> emit,
      ) async {
    _logger.logDebug('Updating emission duration: ${event.duration}');
    try {
      final updatedNecklace = state.necklace.copyWith(
        emission1Duration: event.duration,
      );
      await _databaseService.updateNecklaceSettings(
        state.necklace.id,
        {
          'emission1Duration': event.duration.inSeconds,
          'isRelease1Active': false,
        },
      );
      emit(state.copyWith(necklace: updatedNecklace));
    } catch (e) {
      _logger.logError('Error updating emission duration: $e');
    }
  }

  Future<void> _onUpdateReleaseInterval(UpdateReleaseInterval event, Emitter<SettingsState> emit) async {
    final updatedNecklace = Necklace(
      id: state.necklace.id,
      name: state.necklace.name,
      bleDevice: state.necklace.bleDevice,
      emission1Duration: state.necklace.emission1Duration,
      releaseInterval1: event.interval,
      isRelease1Active: state.necklace.isRelease1Active,
      isArchived: state.necklace.isArchived,
    );
    try {
      emit(state.copyWith(isSaving: true));
      _logger.logDebug('Updating release interval: ${event.interval.inSeconds} seconds for scent ${event.scentNumber}');
      await _databaseService.updateNecklaceSettings(
        state.necklace.id,
        {
          'releaseInterval1': event.interval.inSeconds,
        },
      );
      emit(state.copyWith(
        necklace: updatedNecklace,
        isSaving: false,
      ));
    } catch (e) {
      _logger.logError('Error updating release interval: $e');
      emit(state.copyWith(error: e.toString(), isSaving: false));
    }
  }

  Future<void> _onArchiveNecklace(ArchiveNecklace event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(isSaving: true));
      await _repository.archiveNecklace(event.id);
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  void _onRefreshSettings(RefreshSettings event, Emitter<SettingsState> emit) {
    emit(state.copyWith(necklace: event.necklace));
  }
}
