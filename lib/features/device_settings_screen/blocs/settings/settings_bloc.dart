import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import '../../../../core/services/ble/ble_settings_sync_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/logging_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final NecklaceRepository _repository;
  final DatabaseService _databaseService;
  final LoggingService _logger = LoggingService.instance;

  SettingsBloc(Necklace necklace, this._repository, this._databaseService)
      : super(SettingsState(necklace: necklace)) {
    on<UpdateNecklaceName>(_onUpdateName);
    on<UpdatePeriodicEmission>(_onUpdatePeriodicEmission);
    on<UpdateEmissionDuration>(_onUpdateEmissionDuration);
    on<UpdateReleaseInterval>(_onUpdateReleaseInterval);
    on<ArchiveNecklace>(_onArchiveNecklace);
    on<SaveSettings>(_onSaveSettings);
    on<RefreshSettings>(_onRefreshSettings);
    on<UpdateHeartRateBasedRelease>(_onUpdateHeartRateBasedRelease);
    on<UpdateHighHeartRateThreshold>(_onUpdateHighHeartRateThreshold);
    on<UpdateLowHeartRateThreshold>(_onUpdateLowHeartRateThreshold);
  }

  Future<void> _onSaveSettings(SaveSettings event, Emitter<SettingsState> emit) async {
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

  void _onUpdateName(UpdateNecklaceName event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(isSaving: true));
      await _databaseService.updateNecklaceSettings(
        state.necklace.id,
        {'name': event.name},
      );
      final updatedNecklace = state.necklace.copyWith(name: event.name);
      emit(state.copyWith(
        necklace: updatedNecklace,
        isSaving: false,
        isSaved: true,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isSaving: false));
    }
  }

  void _onUpdatePeriodicEmission(UpdatePeriodicEmission event, Emitter<SettingsState> emit) async {
    try {
      await _databaseService.updateNecklaceSettings(state.necklace.id, {'periodicEmissionEnabled': event.enabled ? 1 : 0});
      final updatedNecklace = state.necklace.copyWith(periodicEmissionEnabled: event.enabled);
      emit(state.copyWith(necklace: updatedNecklace));
    } catch (e) {
      _logger.logError('Error updating periodic emission: $e');
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onUpdateEmissionDuration(UpdateEmissionDuration event, Emitter<SettingsState> emit) async {
    _logger.logDebug('Updating emission duration: ${event.duration}');
    try {
      final updatedNecklace = state.necklace.copyWith(emission1Duration: event.duration);
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
    final updatedNecklace = state.necklace.copyWith(releaseInterval1: event.interval);
    try {
      emit(state.copyWith(isSaving: true));
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

  void _onUpdateHeartRateBasedRelease(UpdateHeartRateBasedRelease event, Emitter<SettingsState> emit) async {
    try {
      await _databaseService.updateNecklaceSettings(
        state.necklace.id,
        {'isHeartRateBasedReleaseEnabled': event.enabled ? 1 : 0},
      );
      emit(state.copyWith(
        necklace: state.necklace.copyWith(isHeartRateBasedReleaseEnabled: event.enabled),
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onUpdateHighHeartRateThreshold(UpdateHighHeartRateThreshold event, Emitter<SettingsState> emit) async {
    try {
      await _databaseService.updateNecklaceSettings(
        state.necklace.id,
        {'highHeartRateThreshold': event.threshold},
      );
      emit(state.copyWith(
        necklace: state.necklace.copyWith(highHeartRateThreshold: event.threshold),
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onUpdateLowHeartRateThreshold(UpdateLowHeartRateThreshold event, Emitter<SettingsState> emit) async {
    try {
      await _databaseService.updateNecklaceSettings(
        state.necklace.id,
        {'lowHeartRateThreshold': event.threshold},
      );
      emit(state.copyWith(
        necklace: state.necklace.copyWith(lowHeartRateThreshold: event.threshold),
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
