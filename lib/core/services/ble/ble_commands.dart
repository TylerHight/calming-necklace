// lib/core/services/ble/ble_commands.dart

enum BleCommand {
  ledOff(0),
  ledOn(1),
  emission1Duration(2),
  interval1(3),
  periodic1(4);

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
