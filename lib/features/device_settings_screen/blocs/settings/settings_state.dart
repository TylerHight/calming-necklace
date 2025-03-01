// lib/features/device_settings_screen/blocs/settings/settings_state.dart

import 'package:equatable/equatable.dart';
import '../../../../core/data/models/necklace.dart';

class SettingsState extends Equatable {
  final Necklace necklace;
  final bool isSaved;
  final bool hasChanges;
  final bool isSaving;
  final String? error;

  SettingsState({
    required this.necklace,
    this.isSaved = false,
    this.hasChanges = false,
    this.isSaving = false,
    this.error,
  });

  @override
  List<Object?> get props => [necklace, isSaved, hasChanges, isSaving, error];

  SettingsState copyWith({
    Necklace? necklace,
    bool? isSaved,
    bool? hasChanges,
    bool? isSaving,
    String? error,
  }) {
    return SettingsState(
      necklace: necklace ?? this.necklace,
      isSaved: isSaved ?? this.isSaved,
      hasChanges: hasChanges ?? this.hasChanges,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}