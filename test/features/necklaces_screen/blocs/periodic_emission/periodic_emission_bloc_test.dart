import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:calming_necklace/core/data/repositories/necklace_repository.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/features/necklaces_screen/blocs/periodic_emission/periodic_emission_bloc.dart';

class MockNecklaceRepository extends Mock implements NecklaceRepository {}

void main() {
  late PeriodicEmissionBloc bloc;
  late MockNecklaceRepository mockRepository;
  late Necklace testNecklace;

  setUp(() {
    mockRepository = MockNecklaceRepository();
    testNecklace = Necklace(
      id: '1',
      name: 'Test Necklace',
      bleDevice: 'test_device',
      emission1Duration: const Duration(seconds: 3),
      releaseInterval1: const Duration(seconds: 20),
      isArchived: false,
    );
    bloc = PeriodicEmissionBloc(
      necklace: testNecklace,
      repository: mockRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('PeriodicEmissionBloc', () {
    blocTest<PeriodicEmissionBloc, PeriodicEmissionState>(
      'emits [PeriodicEmissionRunning] when StartPeriodicEmission is added',
      build: () => bloc,
      act: (bloc) => bloc.add(const StartPeriodicEmission()),
      expect: () => [
        PeriodicEmissionRunning(
          intervalSecondsLeft: testNecklace.releaseInterval1.inSeconds,
          totalInterval: testNecklace.releaseInterval1.inSeconds,
          isEmissionActive: false,
        ),
      ],
    );

    blocTest<PeriodicEmissionBloc, PeriodicEmissionState>(
      'emits [PeriodicEmissionStopped] when StopPeriodicEmission is added',
      build: () => bloc,
      seed: () => PeriodicEmissionRunning(
        intervalSecondsLeft: 10,
        totalInterval: 20,
        isEmissionActive: false,
      ),
      act: (bloc) => bloc.add(const StopPeriodicEmission()),
      expect: () => [PeriodicEmissionStopped()],
    );

    blocTest<PeriodicEmissionBloc, PeriodicEmissionState>(
      'handles timer ticks correctly',
      build: () => bloc,
      seed: () => PeriodicEmissionRunning(
        intervalSecondsLeft: 10,
        totalInterval: 20,
        isEmissionActive: false,
      ),
      act: (bloc) => bloc.add(const TimerTick()),
      expect: () => [
        PeriodicEmissionRunning(
          intervalSecondsLeft: 9,
          totalInterval: 20,
          isEmissionActive: false,
        ),
      ],
    );
  });
}
