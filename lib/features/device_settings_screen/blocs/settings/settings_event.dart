// lib/features/device_settings_screen/blocs/settings/settings_event.dart

import 'package:equatable/equatable.dart';
import '../../../../core/data/models/necklace.dart';

abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RefreshSettings extends SettingsEvent {
  final Necklace necklace;

  RefreshSettings(this.necklace);

  @override
  List<Object?> get props => [necklace];
}

class UpdateNecklaceName extends SettingsEvent {
  final String name;

  UpdateNecklaceName(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdatePeriodicEmission extends SettingsEvent {
  final bool enabled;

  UpdatePeriodicEmission(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateEmissionDuration extends SettingsEvent {
  final Duration duration;

  UpdateEmissionDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

class UpdateReleaseInterval extends SettingsEvent {
  final Duration interval;

  UpdateReleaseInterval(this.interval);

  @override
  List<Object?> get props => [interval];
}

class ArchiveNecklace extends SettingsEvent {
  final String id;

  ArchiveNecklace(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateHeartRateBasedRelease extends SettingsEvent {
  final bool enabled;

  UpdateHeartRateBasedRelease(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateHighHeartRateThreshold extends SettingsEvent {
  final int threshold;

  UpdateHighHeartRateThreshold(this.threshold);

  @override
  List<Object?> get props => [threshold];
}

class UpdateLowHeartRateThreshold extends SettingsEvent {
  final int threshold;

  UpdateLowHeartRateThreshold(this.threshold);

  @override
  List<Object?> get props => [threshold];
}

class SaveSettings extends SettingsEvent {}