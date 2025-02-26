// lib/core/services/ble/ble_commands.dart

enum BleCommand {
  ledOn(1),
  ledOff(2),
  emission1Duration(3),
  interval1(4),
  periodic1(5),
  heartRateEnabled(6),
  highHeartRateThreshold(7),
  lowHeartRateThreshold(8);

  final int value;
  const BleCommand(this.value);

  static BleCommand fromValue(int value) {
    return BleCommand.values.firstWhere(
          (command) => command.value == value,
      orElse: () => throw ArgumentError('Invalid command value: $value'),
    );
  }

  bool get isSettingCommand => value >= emission1Duration.value;
  bool get isLedCommand => value <= ledOn.value;
}
