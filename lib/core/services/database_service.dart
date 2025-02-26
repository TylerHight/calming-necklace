import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/models/ble_device.dart';
import '../data/models/necklace.dart';
import '../data/models/note.dart';
import 'logging_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static Database? _database;
  final LoggingService _logger = LoggingService.instance;
  final _necklaceUpdateController = StreamController<void>.broadcast();
  Stream<void> get onNecklaceUpdate => _necklaceUpdateController.stream;

  DatabaseService._internal() {
    // Logger is initialized synchronously
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'necklaces.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE notes(
      id TEXT PRIMARY KEY,
      content TEXT,
      deviceId TEXT,
      timestamp INTEGER,
      FOREIGN KEY (deviceId) REFERENCES necklaces(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE necklaces(
      id TEXT PRIMARY KEY,
      name TEXT,
      bleDevice TEXT,
      heartRateMonitorDevice TEXT,
      emission1Duration INTEGER,
      releaseInterval1 INTEGER,
      periodicEmissionEnabled INTEGER,
      isRelease1Active INTEGER,
      isLedOn INTEGER DEFAULT 0,
      isArchived INTEGER DEFAULT 0,
      autoTurnOffEnabled INTEGER,
      lastLEDStateChange TEXT,
      isConnected INTEGER DEFAULT 0,
      isHeartRateBasedReleaseEnabled INTEGER DEFAULT 0,
      highHeartRateThreshold INTEGER DEFAULT 120,
      lowHeartRateThreshold INTEGER DEFAULT 60
    )
  ''');

    // Create tables for BLE services, characteristics, and properties
    await db.execute('''
    CREATE TABLE ble_services(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_id TEXT NOT NULL,
      uuid TEXT NOT NULL,
      FOREIGN KEY (device_id) REFERENCES necklaces(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE ble_characteristics(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      service_id INTEGER NOT NULL,
      uuid TEXT NOT NULL,
      FOREIGN KEY (service_id) REFERENCES ble_services(id)
    )
  ''');

    await db.execute('''
    CREATE TABLE characteristic_properties(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      characteristic_id INTEGER NOT NULL,
      property TEXT NOT NULL,
      FOREIGN KEY (characteristic_id) REFERENCES ble_characteristics(id)
    )
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes(
          id TEXT PRIMARY KEY,
          content TEXT,
          deviceId TEXT,
          timestamp INTEGER,
          FOREIGN KEY (deviceId) REFERENCES necklaces(id)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE necklaces 
        ADD COLUMN isArchived INTEGER 
        DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN emission1Duration INTEGER
      ''');
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN releaseInterval1 INTEGER
      ''');
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN periodicEmissionEnabled INTEGER
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN isLedOn INTEGER
        DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN lastLEDStateChange TEXT
      ''');
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN isConnected INTEGER
        DEFAULT 0
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN isHeartRateBasedReleaseEnabled INTEGER
        DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN highHeartRateThreshold INTEGER DEFAULT 120
      ''');
      await db.execute('''
        ALTER TABLE necklaces
        ADD COLUMN lowHeartRateThreshold INTEGER DEFAULT 60
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
      ALTER TABLE necklaces
      ADD COLUMN heartRateMonitorDevice TEXT
    ''');
    }
    
    if (oldVersion < 7) {
      // Create tables for BLE services, characteristics, and properties
      await db.execute('''
      CREATE TABLE IF NOT EXISTS ble_services(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        uuid TEXT NOT NULL,
        FOREIGN KEY (device_id) REFERENCES necklaces(id)
      )
    ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS ble_characteristics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_id INTEGER NOT NULL,
        uuid TEXT NOT NULL,
        FOREIGN KEY (service_id) REFERENCES ble_services(id)
      )
    ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS characteristic_properties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        characteristic_id INTEGER NOT NULL,
        property TEXT NOT NULL,
        FOREIGN KEY (characteristic_id) REFERENCES ble_characteristics(id)
      )
    ''');

      // Migrate existing data if possible
      try {
        final List<Map<String, dynamic>> necklaces = await db.query('necklaces');
        for (var necklace in necklaces) {
          await _migrateDeviceServicesData(db, necklace);
        }
      } catch (e) {
        LoggingService.instance.logError('Error migrating BLE service data: $e');
      }
    }
  }

  Future<void> insertNecklace(Necklace necklace) async {
    final db = await database;
    try {
      final result = await db.insert(
        'necklaces',
        necklace.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.logError('Error inserting necklace: $e');
      rethrow;
    }
  }

  Future<List<Necklace>> getNecklaces() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'necklaces',
        where: 'isArchived = ?',
        whereArgs: [0],
      );
      return List.generate(maps.length,
        (i) => Necklace.fromMap(Map<String, dynamic>.from(maps[i])));
    } catch (e) {
      _logger.logError('Error retrieving necklaces: $e');
      rethrow;
    }
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    _logger.logDebug('Inserting note: ${note.toMap()}');
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    _logger.logDebug('Retrieving notes from database');
    try {
      final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'timestamp DESC');
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    } catch (e) {
      _logger.logError('Error retrieving notes: $e');
      return [];
    }
  }

  Future<List<Note>> getNotesByDevice(String? deviceId) async {
    final db = await database;
    _logger.logDebug('Retrieving notes by device: $deviceId');
    List<Map<String, dynamic>> maps;
    if (deviceId != null) {
      maps = await db.query(
        'notes',
        where: 'deviceId = ?',
        whereArgs: [deviceId],
      );
    } else {
      maps = await db.query('notes');
    }
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    _logger.logDebug('Deleting note with id: $id');
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> archiveNecklace(String id) async {
    final db = await database;
    _logger.logDebug('Archiving necklace with id: $id');
    await db.transaction((txn) async {
      await txn.update('necklaces', {'isArchived': 1},
        where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteAllNecklaces() async {
    final db = await database;
    await db.delete('necklaces');
    await db.delete('notes');
    _necklaceUpdateController.add(null);
    _logger.logDebug('Deleted all necklace and note data');
  }

  Future<void> updateNecklaceSettings(String id, Map<String, dynamic> settings) async {
    try {
      final db = await database;
      Map<String, dynamic> sanitizedSettings = Map.from(settings);

      // Handle BLE device data if present
      if (sanitizedSettings.containsKey('bleDevice') && sanitizedSettings['bleDevice'] is Map) {
        try {
          // Convert the BleDevice map to a JSON string
          final bleDeviceMap = sanitizedSettings['bleDevice'] as Map<String, dynamic>;
          _logger.logDebug('Converting BleDevice map to JSON string: ${bleDeviceMap.toString().substring(0, 100)}...');

          // Log the services if they exist
          if (bleDeviceMap.containsKey('services')) {
            final services = bleDeviceMap['services'];
            if (services != null) {
              _logger.logDebug('Services found: ${services.length}');
              for (var service in services) {
                _logger.logDebug('Service UUID: ${service['uuid']}');
              }
            } else {
              _logger.logDebug('Services are null.');
            }
          }
          
          // Convert to JSON string for storage
          sanitizedSettings['bleDevice'] = jsonEncode(bleDeviceMap);
        } catch (e) {
          _logger.logError('Error serializing BLE device data: $e');
          // If there's an error, remove the bleDevice field to prevent database errors
          sanitizedSettings.remove('bleDevice');
        }
      } else if (sanitizedSettings.containsKey('bleDevice') && sanitizedSettings['bleDevice'] is String) {
        // Already a JSON string, no need to convert
        _logger.logDebug('BleDevice is already a JSON string');
      } else {
        _logger.logDebug('BleDevice data not present or in unexpected format');
      }

      await db.update(
        'necklaces',
        sanitizedSettings,
        where: 'id = ?',
        whereArgs: [id],
      );
      _necklaceUpdateController.add(null);
    } catch (e) {
      _logger.logError('Error updating necklace settings: $e');
      rethrow;
    }
  }

  Future<Necklace?> getNecklaceById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'necklaces',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final necklace = Necklace.fromMap(maps.first);
      return necklace;
    }
    return null;
  }

  Future<void> updateNecklaceLedState(String necklaceId, bool isOn) async {
    try {
      _logger.logDebug('Updating LED state for necklace $necklaceId to: $isOn');
      final db = await database; // Get the database instance
      final necklace = await getNecklaceById(necklaceId);
      await db.update(
        'necklaces',
        {
          'isLedOn': isOn ? 1 : 0,
          'lastLEDStateChange': DateTime.now().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [necklaceId],
      );
      _necklaceUpdateController.add(null);
    } catch (e) {
      _logger.logError('Error updating LED state for necklace $necklaceId: $e');
      rethrow;
    }
  }

  Future<void> updateHeartRateMonitorDevice(String necklaceId, Map<String, dynamic> deviceData) async {
    try {
      final db = await database;
      await db.update(
        'necklaces',
        {'heartRateMonitorDevice': jsonEncode(deviceData)},
        where: 'id = ?',
        whereArgs: [necklaceId],
      );
      _necklaceUpdateController.add(null);
      _logger.logDebug('Updated heart rate monitor device for necklace: $necklaceId');
    } catch (e) {
      _logger.logError('Error updating heart rate monitor device: $e');
      rethrow;
    }
  }

  Future<void> removeHeartRateMonitor(String necklaceId) async {
    try {
      final db = await database;
      await db.update(
        'necklaces',
        {'heartRateMonitorDevice': null},
        where: 'id = ?',
        whereArgs: [necklaceId],
      );
      _necklaceUpdateController.add(null);
      _logger.logDebug('Removed heart rate monitor from necklace: $necklaceId');
    } catch (e) {
      _logger.logError('Error removing heart rate monitor: $e');
      rethrow;
    }
  }

  // New methods for BLE services, characteristics, and properties
  Future<void> _migrateDeviceServicesData(Database db, Map<String, dynamic> necklace) async {
    try {
      if (necklace['bleDevice'] == null) return;
      
      final deviceId = necklace['id'];
      final bleDeviceJson = necklace['bleDevice'];
      
      if (bleDeviceJson == null) return;
      
      Map<String, dynamic>? bleDeviceMap;
      try {
        bleDeviceMap = jsonDecode(bleDeviceJson);
      } catch (e) {
        LoggingService.instance.logError('Error decoding BLE device JSON: $e');
        return;
      }
      
      // Check if bleDeviceMap is null or doesn't contain services data
      if (bleDeviceMap == null) return;
      
      // Check if the map contains a 'services' key - older versions might not have this
      if (!bleDeviceMap.containsKey('services')) {
        LoggingService.instance.logDebug('No services data found in device map for migration');
        return;
      }
     
     final services = bleDeviceMap['services'] as List?;
     if (services == null) return;
     
     for (var service in services) {
       final serviceUuid = service['uuid'];
       if (serviceUuid == null) continue;
       
       // Insert service
       final serviceId = await db.insert('ble_services', {
         'device_id': deviceId,
         'uuid': serviceUuid,
       });
       
       // Process characteristics
       final characteristics = service['characteristics'] as List?;
       if (characteristics == null) continue;
       
       for (var characteristic in characteristics) {
         final characteristicUuid = characteristic['uuid'];
         if (characteristicUuid == null) continue;
         
         // Insert characteristic
         final characteristicId = await db.insert('ble_characteristics', {
           'service_id': serviceId,
           'uuid': characteristicUuid,
         });
         
         // Process properties
         final properties = characteristic['properties'] as List?;
         if (properties == null) continue;
         
         for (var property in properties) {
           await db.insert('characteristic_properties', {
             'characteristic_id': characteristicId,
             'property': property,
           });
         }
       }
     }
    } catch (e) {
      LoggingService.instance.logError('Error migrating device services data: $e');
    }
  }

  Future<void> saveDeviceServices(String deviceId, List<BleServiceInfo> services) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // First, delete existing services for this device
      await _deleteDeviceServices(txn, deviceId);
      
      // Then insert the new services
      for (var service in services) {
        final serviceId = await txn.insert('ble_services', {
          'device_id': deviceId,
          'uuid': service.uuid,
        });
        
        if (service.characteristics != null) {
          for (var characteristic in service.characteristics!) {
            final characteristicId = await txn.insert('ble_characteristics', {
              'service_id': serviceId,
              'uuid': characteristic.uuid,
            });
            
            for (var property in characteristic.properties) {
              await txn.insert('characteristic_properties', {
                'characteristic_id': characteristicId,
                'property': property,
              });
            }
          }
        }
      }
    });
  }

  Future<void> _deleteDeviceServices(DatabaseExecutor db, String deviceId) async {
    // Get all services for this device
    final services = await db.query(
      'ble_services',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    
    for (var service in services) {
      final serviceId = service['id'];
      
      // Get all characteristics for this service
      final characteristics = await db.query(
        'ble_characteristics',
        where: 'service_id = ?',
        whereArgs: [serviceId],
      );
      
      for (var characteristic in characteristics) {
        final characteristicId = characteristic['id'];
        
        // Delete properties for this characteristic
        await db.delete('characteristic_properties', where: 'characteristic_id = ?', whereArgs: [characteristicId]);
      }
      
      // Delete characteristics for this service
      await db.delete('ble_characteristics', where: 'service_id = ?', whereArgs: [serviceId]);
    }
    
    // Delete services for this device
    await db.delete('ble_services', where: 'device_id = ?', whereArgs: [deviceId]);
  }

  Future<List<BleServiceInfo>> getDeviceServices(String deviceId) async {
    final db = await database;
    final List<BleServiceInfo> result = [];
    
    final services = await db.query(
      'ble_services',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    
    for (var service in services) {
      final serviceId = service['id'];
      final serviceUuid = service['uuid'] as String;
      
      final characteristics = await db.query(
        'ble_characteristics',
        where: 'service_id = ?',
        whereArgs: [serviceId],
      );
      
      List<BleCharacteristicInfo> characteristicsList = [];
      
      for (var characteristic in characteristics) {
        final characteristicId = characteristic['id'];
        final characteristicUuid = characteristic['uuid'] as String;
        
        final properties = await db.query(
          'characteristic_properties',
          where: 'characteristic_id = ?',
          whereArgs: [characteristicId],
        );
        
        List<String> propertiesList = properties
            .map((p) => p['property'] as String)
            .toList();
        
        characteristicsList.add(BleCharacteristicInfo(
          uuid: characteristicUuid,
          properties: propertiesList,
        ));
      }
      
      result.add(BleServiceInfo(
        uuid: serviceUuid,
        characteristics: characteristicsList,
      ));
    }
    
    return result;
  }

  void dispose() {
    _necklaceUpdateController.close();
  }
}
