import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/data/models/ble_device.dart';
import 'package:calming_necklace/core/services/logging_service.dart';
import 'package:calming_necklace/core/services/database_service.dart';
import 'package:calming_necklace/core/services/ble/ble_service.dart';
import 'dart:async';

abstract class NecklaceRepository {
  Future<void> toggleLight(Necklace necklace, bool isOn);
  Future<void> setAutoTurnOff(Necklace necklace, Duration duration);
  Future<void> setPeriodicEmission(Necklace necklace, Duration interval);
  Future<void> triggerEmission(String necklaceId);
  Future<void> completeEmission(String necklaceId);
  Future<List<Necklace>> getNecklaces();
  Future<void> archiveNecklace(String id);
  Future<String> getDeviceNameById(String deviceId);
  Future<void> addNecklace(String name, String bleDeviceId);
  Future<Necklace?> getNecklaceByBleDeviceId(String bleDeviceId);
  Stream<bool> getEmissionStream(String necklaceId);
  Future<Necklace?> getNecklaceById(String id);
}

class NecklaceRepositoryImpl implements NecklaceRepository {
  final LoggingService _logger = LoggingService.instance;
  final DatabaseService _dbService;
  final BleService _bleService;
  final List<Necklace> _necklaces = [];
  final Map<String, Timer> _periodicEmissionTimers = {};
  final Map<String, bool> _emissionStates = {};
  final Map<String, StreamController<bool>> _emissionControllers = {};
  final Map<String, bool> _processingStates = {};
  final Map<String, bool> _stateChangeInProgress = {};
  final Map<String, DateTime> _lastToggleAttempt = {};

  NecklaceRepositoryImpl({required DatabaseService databaseService, required BleService bleService})
      : _dbService = databaseService,
        _bleService = bleService;

  StreamController<bool> _getOrCreateController(String necklaceId) {
    return _emissionControllers.putIfAbsent(
      necklaceId,
          () => StreamController<bool>.broadcast(),
    );
  }

  @override
  Future<void> toggleLight(Necklace necklace, bool isOn) async {
    try {
      // Debounce toggle attempts
      final now = DateTime.now();
      final lastAttempt = _lastToggleAttempt[necklace.id];
      if (lastAttempt != null && now.difference(lastAttempt) < const Duration(milliseconds: 500)) {
        return;
      }
      _lastToggleAttempt[necklace.id] = now;

      // Check if device is connected
      if (!await _bleService.isDeviceConnected(necklace.bleDevice!.id)) {
        throw Exception('Device not connected');
      }

      if (_processingStates[necklace.id] == true) return;
      if (_stateChangeInProgress[necklace.id] == true) return;
      _processingStates[necklace.id] = true;
      _stateChangeInProgress[necklace.id] = true;

      // Update database first to ensure UI reflects the change immediately
      await _dbService.updateNecklaceLedState(necklace.id, isOn);

      _logger.logInfo('Toggle light ${isOn ? 'on' : 'off'} for necklace ${necklace.id}');
      await _bleService.setLedState(isOn);

      _emissionControllers[necklace.id]?.add(isOn);
      _processingStates[necklace.id] = false;
      _stateChangeInProgress[necklace.id] = false;
    } catch (e) {
      _logger.logError('Error toggling light: $e');
      _processingStates[necklace.id] = false;
      _stateChangeInProgress[necklace.id] = false;
      rethrow;
    }
  }

  @override
  Future<void> setAutoTurnOff(Necklace necklace, Duration duration) async {
    try {
      _logger.logInfo('Set auto turn off for necklace ${necklace.id}: ${duration.inSeconds}s');
    } catch (e) {
      _logger.logError('Error setting auto turn off: $e');
      rethrow;
    }
  }

  @override
  Future<void> setPeriodicEmission(Necklace necklace, Duration interval) async {
    try {
      _logger.logInfo('Set periodic emission for necklace ${necklace.id}: ${interval.inSeconds}s');
    } catch (e) {
      _logger.logError('Error setting periodic emission: $e');
      rethrow;
    }
  }

  @override
  Future<void> addNecklace(String name, String bleDeviceId) async {
    try {
      final bleDevice = BleDevice(
        id: bleDeviceId,
        name: 'Default Name', // Provide a default name
        address: '00:00:00:00:00:00', // Provide a default address
        rssi: 0, // Provide a default RSSI value
        deviceType: BleDeviceType.necklace, // Provide a default device type
      ); // Create BleDevice instance
      final necklace = Necklace(
        id: DateTime.now().toString(),
        name: name,
        isConnected: false,
        bleDevice: bleDevice, // Pass BleDevice instance
        emission1Duration: Duration(seconds: 3),
        releaseInterval1: Duration(seconds: 20),
        isArchived: false,
      );

      await _dbService.insertNecklace(necklace);
      _logger.logInfo('Successfully added necklace: $name with Bluetooth Low Energy device: $bleDeviceId');
    } catch (e) {
      _logger.logError('Error adding necklace: $e');
      throw Exception('Failed to add necklace: $e');
    }
  }

  @override
  Future<List<Necklace>> getNecklaces() async {
    final necklaces = await _dbService.getNecklaces();
    return necklaces.where((n) => !n.isArchived).toList();
  }

  @override
  Future<void> archiveNecklace(String id) async {
    try {
      await _dbService.archiveNecklace(id);
      _logger.logInfo('Successfully archived necklace with id: $id');
    } catch (e) {
      _logger.logError('Error archiving necklace: $e');
      throw Exception('Failed to archive necklace: $e');
    }
  }

  @override
  Future<String> getDeviceNameById(String deviceId) async {
    try {
      final necklaces = await getNecklaces();
      final necklace = necklaces.firstWhere((n) => n.id == deviceId);
      return necklace.name;
    } catch (e) {
      return 'Unknown Device';
    }
  }

  @override
  Future<Necklace?> getNecklaceByBleDeviceId(String bleDeviceId) async {
    try {
      final necklaces = await _dbService.getNecklaces();
      return necklaces.firstWhere(
        (necklace) => necklace.bleDevice?.id == bleDeviceId,
        orElse: () => throw Exception('No necklace found for device ID: $bleDeviceId'),
      );
    } catch (e) {
      _logger.logError('Error getting necklace by BLE device ID: $e');
      return null;
    }
  }

  Stream<bool> getEmissionStream(String necklaceId) {
    return _getOrCreateController(necklaceId).stream;
  }

  @override
  Future<void> triggerEmission(String necklaceId) async {
    _logger.logDebug('Triggering emission for necklace: $necklaceId');
    _emissionStates[necklaceId] = true;
    _getOrCreateController(necklaceId).add(true);
  }

  @override
  Future<void> completeEmission(String necklaceId) async {
    _logger.logDebug('Completing emission for necklace: $necklaceId');
    _emissionStates[necklaceId] = false;
    _getOrCreateController(necklaceId).add(false);
  }

  void dispose() {
    for (var controller in _emissionControllers.values) {
      controller.close();
    }
    _emissionControllers.clear();
  }

  @override
  Future<Necklace?> getNecklaceById(String id) async {
    try {
      final necklaces = await getNecklaces();
      return necklaces.firstWhere((necklace) => necklace.id == id, orElse: () => Necklace(id: '', name: '', isConnected: false, bleDevice: const BleDevice(id: '', name: '', address: '', rssi: 0, deviceType: BleDeviceType.necklace), emission1Duration: Duration.zero, releaseInterval1: Duration.zero, isArchived: false));
    } catch (e) {
      _logger.logError('Error getting necklace by id: $e');
      return null;
    }
  }
}
