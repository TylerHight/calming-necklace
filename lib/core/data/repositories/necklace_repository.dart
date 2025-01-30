import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/services/logging_service.dart';
import 'package:calming_necklace/core/services/database_service.dart';

abstract class NecklaceRepository {
  Future<void> toggleLight(Necklace necklace, bool isOn);
  Future<void> setAutoTurnOff(Necklace necklace, Duration duration);
  Future<void> setPeriodicEmission(Necklace necklace, Duration interval);
  Future<void> addNecklace(String name, String bleDevice);
  Future<List<Necklace>> getNecklaces();
  Future<void> deleteNecklace(String id);
  Future<String> getDeviceNameById(String deviceId);
}

class NecklaceRepositoryImpl implements NecklaceRepository {
  final LoggingService _logger = LoggingService();
  final List<Necklace> _necklaces = [];
  final DatabaseService _dbService = DatabaseService();

  @override
  Future<void> toggleLight(Necklace necklace, bool isOn) async {
    try {
      // Implement actual BLE communication here
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
        emission2Duration: Duration(seconds: 8),
        releaseInterval2: Duration(seconds: 30),
      );
      
      await _dbService.insertNecklace(necklace);
      _logger.logInfo('Successfully added necklace: $name with BLE device: $bleDevice');
    } catch (e) {
      _logger.logError('Error adding necklace: $e');
      throw Exception('Failed to add necklace: $e');
    }
  }

  @override
  Future<List<Necklace>> getNecklaces() async {
    return _dbService.getNecklaces();
  }

  @override
  Future<void> deleteNecklace(String id) async {
    try {
      await _dbService.deleteNecklace(id);
      _logger.logInfo('Successfully deleted necklace with id: $id');
    } catch (e) {
      _logger.logError('Error deleting necklace: $e');
      throw Exception('Failed to delete necklace: $e');
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
}
