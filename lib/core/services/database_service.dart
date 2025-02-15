import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
    // Logger is now initialized synchronously
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
      version: 4,
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
      emission1Duration INTEGER,
      releaseInterval1 INTEGER,
      periodicEmissionEnabled INTEGER,
      isRelease1Active INTEGER,
      isLedOn INTEGER DEFAULT 0,
      isArchived INTEGER DEFAULT 0,
      autoTurnOffEnabled INTEGER,
      lastLEDStateChange TEXT,
      isConnected INTEGER DEFAULT 0
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

  Future<void> updateNecklaceSettings(String id, Map<String, dynamic> settings) async {
    final db = await database;
    await db.update(
      'necklaces',
      settings,
      where: 'id = ?',
      whereArgs: [id],
    );
    _necklaceUpdateController.add(null);
    _logger.logDebug('Updated necklace settings: $settings');
  }

  Future<Necklace?> getNecklaceById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'necklaces',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Necklace.fromMap(maps.first);
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

  void dispose() {
    _necklaceUpdateController.close();
  }
}
