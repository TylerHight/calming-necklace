import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/models/necklace.dart';

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
} 