import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/services/logging_service.dart';
import 'package:calming_necklace/core/services/database_service.dart';
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
  Future<void> addNecklace(String name, String bleDevice);
  Stream<bool> getEmissionStream(String necklaceId);
}

class NecklaceRepositoryImpl implements NecklaceRepository {
  final LoggingService _logger;
  final DatabaseService _dbService;
  final List<Necklace> _necklaces = [];
  final Map<String, Timer> _periodicEmissionTimers = {};
  final Map<String, bool> _emissionStates = {};
  final Map<String, StreamController<bool>> _emissionControllers = {};

  NecklaceRepositoryImpl({required DatabaseService databaseService})
      : _logger = LoggingService(),
        _dbService = databaseService;

  StreamController<bool> _getOrCreateController(String necklaceId) {
    return _emissionControllers.putIfAbsent(
      necklaceId,
      () => StreamController<bool>.broadcast(),
    );
  }

  @override
  Future<void> toggleLight(Necklace necklace, bool isOn) async {
    try {
      // Implement actual Bluetooth Low Energy communication here
      _logger.logInfo('Toggle light ${isOn ? 'on' : 'off'} for necklace ${necklace.id}');
    } catch (e) {
      _logger.logError('Error toggling light: $e');
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
  Future<void> addNecklace(String name, String bleDevice) async {
    try {
      final necklace = Necklace(
        id: DateTime.now().toString(),
        name: name,
        bleDevice: bleDevice,
        emission1Duration: Duration(seconds: 3),
        releaseInterval1: Duration(seconds: 20),
        isArchived: false,
      );

      await _dbService.insertNecklace(necklace);
      _logger.logInfo('Successfully added necklace: $name with Bluetooth Low Energy device: $bleDevice');
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
}
