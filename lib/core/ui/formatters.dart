String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  final List<String> parts = [];
  
  if (hours > 0) {
    parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
  }
  if (minutes > 0) {
    parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
  }
  if (seconds > 0) {
    parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
  }

  return parts.isEmpty ? '0 seconds' : parts.join(', ');
}
