import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:calming_necklace/core/services/database_service.dart';
import 'package:calming_necklace/core/data/repositories/necklace_repository.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late NecklaceRepositoryImpl repository;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    repository = NecklaceRepositoryImpl(databaseService: mockDatabaseService);
  });

  group('NecklaceRepository', () {
    test('getNecklaces returns only non-archived necklaces', () async {
      // Arrange
      final testNecklaces = [
        Necklace(
          id: '1',
          name: 'Test Necklace 1',
          bleDevice: 'device1',
          emission1Duration: const Duration(seconds: 3),
          releaseInterval1: const Duration(seconds: 20),
          isArchived: false,
        ),
        Necklace(
          id: '2',
          name: 'Test Necklace 2',
          bleDevice: 'device2',
          emission1Duration: const Duration(seconds: 3),
          releaseInterval1: const Duration(seconds: 20),
          isArchived: true,
        ),
      ];

      when(mockDatabaseService.getNecklaces())
          .thenAnswer((_) async => testNecklaces);

      // Act
      final result = await repository.getNecklaces();

      // Assert
      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.isArchived, false);
    });

    test('toggleLight updates device state correctly', () async {
      // Arrange
      final testNecklace = Necklace(
        id: '1',
        name: 'Test Necklace',
        bleDevice: 'device1',
        emission1Duration: const Duration(seconds: 3),
        releaseInterval1: const Duration(seconds: 20),
        isArchived: false,
      );

      when(mockDatabaseService.updateNecklaceSettings(any<String>(), any<Map<String, dynamic>>()))
          .thenAnswer((_) async => Future.value());

      // Act
      await repository.toggleLight(testNecklace, true);

      // Assert
      verify(mockDatabaseService.updateNecklaceSettings(
        testNecklace.id,
        {'isRelease1Active': 1},
      )).called(1);
    });

    test('triggerEmission emits correct stream event', () async {
      // Arrange
      const necklaceId = '1';
      final stream = repository.getEmissionStream(necklaceId);

      // Act
      await repository.triggerEmission(necklaceId);

      // Assert
      await expectLater(stream, emits(true));
    });
  });
}