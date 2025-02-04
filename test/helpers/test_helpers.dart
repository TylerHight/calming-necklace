import 'package:calming_necklace/core/data/models/necklace.dart';

class TestHelpers {
  static Necklace createTestNecklace({
    String id = '1',
    String name = 'Test Necklace',
    String bleDevice = 'test_device',
    bool isArchived = false,
  }) {
    return Necklace(
      id: id,
      name: name,
      bleDevice: bleDevice,
      emission1Duration: const Duration(seconds: 3),
      releaseInterval1: const Duration(seconds: 20),
      isArchived: isArchived,
    );
  }
}
