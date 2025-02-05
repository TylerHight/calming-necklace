String formatDuration(Duration duration, {bool useFullWords = false}) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  // Only add spaces between units, not between numbers and their units
  String formatUnit(int value, String unit) => '$value$unit';

  final List<String> parts = [];

  if (hours > 0) {
    parts.add(useFullWords ? '$hours ${hours == 1 ? 'hour' : 'hours'}' : formatUnit(hours, 'h'));
  }
  if (minutes > 0) {
    parts.add(useFullWords ? '$minutes ${minutes == 1 ? 'minute' : 'minutes'}' : formatUnit(minutes, 'm'));
  }
  if (seconds > 0) {
    parts.add(useFullWords ? '$seconds ${seconds == 1 ? 'second' : 'seconds'}' : formatUnit(seconds, 's'));
  }

  return parts.isEmpty
      ? (useFullWords ? '0 seconds' : '0s')
      : parts.join(useFullWords ? ', ' : ' ');
}