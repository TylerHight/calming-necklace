import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:calming_necklace/core/services/database_service.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/core/data/models/note.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  late DatabaseService databaseService;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockDatabase();
    databaseService = DatabaseService();
  });

  group('DatabaseService', () {
    test('insertNecklace adds necklace to database', () async {
      // Arrange
      final testNecklace = Necklace(
        id: '1',
        name: 'Test Necklace',
        bleDevice: 'device1',
        emission1Duration: const Duration(seconds: 3),
        releaseInterval1: const Duration(seconds: 20),
        isArchived: false,
      );

      when(mockDatabase.insert(
        'necklaces',
        testNecklace.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).thenAnswer((_) async => 1);

      // Act
      await databaseService.insertNecklace(testNecklace);

      // Assert
      verify(mockDatabase.insert(
        'necklaces',
        testNecklace.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).called(1);
    });

    test('getNecklaces returns list of necklaces', () async {
      // Arrange
      final testData = [
        {
          'id': '1',
          'name': 'Test Necklace 1',
          'bleDevice': 'device1',
          'emission1Duration': 3,
          'releaseInterval1': 20,
          'isArchived': 0,
        }
      ];

      when(mockDatabase.query('necklaces'))
          .thenAnswer((_) async => testData);

      // Act
      final result = await databaseService.getNecklaces();

      // Assert
      expect(result.length, 1);
      expect(result.first.name, 'Test Necklace 1');
    });

    test('archiveNecklace updates isArchived flag', () async {
      // Arrange
      const necklaceId = '1';

      // Act
      await databaseService.archiveNecklace(necklaceId);

      // Assert
      verify(mockDatabase.update(
        'necklaces',
        {'isArchived': 1},
        where: 'id = ?',
        whereArgs: [necklaceId],
      )).called(1);
    });
  });
}
