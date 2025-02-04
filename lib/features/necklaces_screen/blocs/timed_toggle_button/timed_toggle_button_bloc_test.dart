import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:calming_necklace/core/data/repositories/necklace_repository.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';
import 'package:calming_necklace/features/necklaces_screen/blocs/timed_toggle_button/timed_toggle_button_bloc.dart';

class MockNecklaceRepository extends Mock implements NecklaceRepository {}

void main() {
  late TimedToggleButtonBloc bloc;
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
    bloc = TimedToggleButtonBloc(
      repository: mockRepository,
      necklace: testNecklace,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('TimedToggleButtonBloc', () {
    blocTest<TimedToggleButtonBloc, TimedToggleButtonState>(
      'emits [LightOnState] when ToggleLightEvent is added and light was off',
      build: () => bloc,
      act: (bloc) => bloc.add(ToggleLightEvent()),
      expect: () => [
        TimedToggleButtonLoading(),
        LightOnState(testNecklace.emission1Duration.inSeconds),
      ],
    );

    blocTest<TimedToggleButtonBloc, TimedToggleButtonState>(
      'emits [LightOffState] when ToggleLightEvent is added and light was on',
      build: () {
        when(mockRepository.toggleLight(testNecklace, false))
            .thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => LightOnState(10),
      act: (bloc) => bloc.add(ToggleLightEvent()),
      expect: () => [
        TimedToggleButtonLoading(),
        LightOffState(),
      ],
    );

    blocTest<TimedToggleButtonBloc, TimedToggleButtonState>(
      'handles periodic emission correctly',
      build: () => bloc,
      act: (bloc) => bloc.add(const StartPeriodicEmission(duration: 30)),
      expect: () => [
        LightOnState(30),
      ],
    );
  });
}
