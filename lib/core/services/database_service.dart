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

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'necklaces.db');
    return await openDatabase(
      path,
      version: 2,
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
      emission2Duration INTEGER,
      releaseInterval2 INTEGER,
      isRelease1Active INTEGER,
      isRelease2Active INTEGER,
      autoTurnOffEnabled INTEGER,
      periodicEmissionEnabled INTEGER
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
  }

  Future<void> insertNecklace(Necklace necklace) async {
    final db = await database;
    await db.insert(
      'necklaces',
      necklace.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Necklace>> getNecklaces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('necklaces');
    return List.generate(maps.length, (i) {
      return Necklace.fromMap(maps[i]);
    });
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    LoggingService().logDebug('Inserting note: ${note.toMap()}');
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    LoggingService().logDebug('Retrieving notes from database');
    try {
      final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'timestamp DESC');
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    } catch (e) {
      LoggingService().logError('Error retrieving notes: $e');
      return [];
    }
  }

  Future<List<Note>> getNotesByDevice(String? deviceId) async {
    final db = await database;
    LoggingService().logDebug('Retrieving notes by device: $deviceId');
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
    LoggingService().logDebug('Deleting note with id: $id');
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
