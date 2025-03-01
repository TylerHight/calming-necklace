import 'package:flutter/foundation.dart';
import '../../data/models/necklace.dart';
import '../logging_service.dart';
import 'ble_service.dart';
import 'ble_commands.dart';

/// Service responsible for synchronizing settings between the app and BLE device
class BleSettingsSyncService {
  static final BleSettingsSyncService _instance = BleSettingsSyncService._internal();
  factory BleSettingsSyncService() => _instance;
  
  final BleService _bleService = BleService();
  late final LoggingService _logger;
  
  BleSettingsSyncService._internal() {
    _initLogger();
  }
  
  Future<void> _initLogger() async {
    _logger = await LoggingService.getInstance();
  }
  
  /// Synchronizes all settings with the connected BLE device
  Future<void> syncAllSettings(Necklace necklace) async {
    _logger = await LoggingService.getInstance();
    if (necklace.bleDevice == null) {
      _logger.logWarning('Cannot sync settings: No BLE device connected to necklace');
      return;
    }
    
    try {
      _logger.logInfo('Starting settings sync for device: ${necklace.bleDevice!.name}');
      
      // Sync emission duration
      await syncEmissionDuration(necklace);
      
      // Sync release interval
      await syncReleaseInterval(necklace);
      
      // Sync periodic emission setting
      await syncPeriodicEmission(necklace);
      
      // Sync heart rate settings if enabled
      if (necklace.isHeartRateBasedReleaseEnabled) {
        await syncHeartRateSettings(necklace);
      }
      
      _logger.logInfo('Settings sync completed successfully');
    } catch (e) {
      _logger.logError('Error syncing settings with device: $e');
      rethrow;
    }
  }
  
  /// Synchronizes only changed settings with the connected BLE device
  Future<void> syncChangedSettings(Necklace originalNecklace, Necklace updatedNecklace) async {
    _logger = await LoggingService.getInstance();
    if (updatedNecklace.bleDevice == null) {
      _logger.logWarning('Cannot sync settings: No BLE device connected to necklace');
      return;
    }

    try {
      _logger.logInfo('Starting changed settings sync for device: ${updatedNecklace.bleDevice!.name}');

      // Check if device is connected before attempting to sync
      if (!await _bleService.isDeviceConnected(updatedNecklace.bleDevice!.id)) {
        await _bleService.connectToDevice(updatedNecklace.bleDevice!.device!);
      }

      // Check and sync emission duration if changed
      if (originalNecklace.emission1Duration != updatedNecklace.emission1Duration) {
        await syncEmissionDuration(updatedNecklace);
      }

      // Check and sync release interval if changed
      if (originalNecklace.releaseInterval1 != updatedNecklace.releaseInterval1) {
        await syncReleaseInterval(updatedNecklace);
      }

      // Check and sync periodic emission setting if changed
      if (originalNecklace.periodicEmissionEnabled != updatedNecklace.periodicEmissionEnabled) {
        await syncPeriodicEmission(updatedNecklace);
      }

      // Check and sync heart rate settings if changed
      if (originalNecklace.isHeartRateBasedReleaseEnabled != updatedNecklace.isHeartRateBasedReleaseEnabled ||
          originalNecklace.highHeartRateThreshold != updatedNecklace.highHeartRateThreshold ||
          originalNecklace.lowHeartRateThreshold != updatedNecklace.lowHeartRateThreshold) {
        await syncHeartRateSettings(updatedNecklace);
      }

      _logger.logInfo('Changed settings sync completed successfully');
    } catch (e) {
      _logger.logError('Error syncing changed settings with device: $e');
      rethrow;
    }
  }
  
  /// Synchronizes emission duration setting with the device
  Future<void> syncEmissionDuration(Necklace necklace) async {
    try {
      _logger.logDebug('Syncing emission duration: ${necklace.emission1Duration.inSeconds}s');
      await _bleService.updateEmission1Duration(
        necklace.bleDevice!.id, 
        necklace.emission1Duration
      );
    } catch (e) {
      _logger.logError('Failed to sync emission duration: $e');
      rethrow;
    }
  }
  
  /// Synchronizes release interval setting with the device
  Future<void> syncReleaseInterval(Necklace necklace) async {
    try {
      _logger.logDebug('Syncing release interval: ${necklace.releaseInterval1.inSeconds}s');
      await _bleService.updateInterval1(
        necklace.bleDevice!.id, 
        necklace.releaseInterval1
      );
    } catch (e) {
      _logger.logError('Failed to sync release interval: $e');
      rethrow;
    }
  }
  
  /// Synchronizes periodic emission setting with the device
  Future<void> syncPeriodicEmission(Necklace necklace) async {
    try {
      _logger.logDebug('Syncing periodic emission: ${necklace.periodicEmissionEnabled}');
      await _bleService.updatePeriodicEmission1(
        necklace.bleDevice!.id, 
        necklace.periodicEmissionEnabled
      );
    } catch (e) {
      _logger.logError('Failed to sync periodic emission: $e');
      rethrow;
    }
  }
  
  /// Synchronizes heart rate settings with the device
  Future<void> syncHeartRateSettings(Necklace necklace) async {
    try {
      _logger.logDebug('Syncing heart rate settings: enabled=${necklace.isHeartRateBasedReleaseEnabled}, ' +
                       'high=${necklace.highHeartRateThreshold}, low=${necklace.lowHeartRateThreshold}');
      
      // Update heart rate based release setting
      await _bleService.updateHeartRateSettings(
        necklace.bleDevice!.id,
        necklace.isHeartRateBasedReleaseEnabled,
        necklace.highHeartRateThreshold,
        necklace.lowHeartRateThreshold
      );
    } catch (e) {
      _logger.logError('Failed to sync heart rate settings: $e');
      rethrow;
    }
  }
}
