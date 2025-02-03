import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/services/logging_service.dart';
import 'package:calming_necklace/core/services/database_service.dart';
import 'dart:async';

abstract class NecklaceRepository {
  Future<void> toggleLight(Necklace necklace, bool isOn);
  Future<void> setAutoTurnOff(Necklace necklace, Duration duration);
  Future<void> setPeriodicEmission(Necklace necklace, Duration interval);
  Stream<bool> get periodicEmissionStream;
  void emissionComplete();
  void triggerPeriodicEmission();
  Future<List<Necklace>> getNecklaces();
  Future<void> archiveNecklace(String id);
  Future<String> getDeviceNameById(String deviceId);
  Future<void> addNecklace(String name, String bleDevice);
}

class NecklaceRepositoryImpl implements NecklaceRepository {
  final LoggingService _logger = LoggingService();
  final List<Necklace> _necklaces = [];
  final DatabaseService _dbService = DatabaseService();
  final _periodicEmissionController = StreamController<bool>.broadcast();
  Timer? _periodicEmissionTimer;

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

  @override
  Stream<bool> get periodicEmissionStream => _periodicEmissionController.stream;

  @override
  void triggerPeriodicEmission() {
    _logger.logDebug('Triggering periodic emission');
    _periodicEmissionController.add(true);
  }

  @override
  void emissionComplete() {
    _logger.logDebug('Emission complete');
    _periodicEmissionController.add(false);
  }

  void dispose() {
    _periodicEmissionController.close();
    _periodicEmissionTimer?.cancel();
  }
}
