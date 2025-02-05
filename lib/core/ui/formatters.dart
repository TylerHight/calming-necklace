String formatDuration(Duration duration, {bool useFullWords = false}) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  String addSpaces(String input) => input.split('').join(' ');

  final List<String> parts = [];
  
  if (hours > 0) {
    parts.add(useFullWords ? '$hours ${hours == 1 ? 'hour' : 'hours'}' : '${hours}h');
  }
  if (minutes > 0) {
    parts.add(useFullWords ? '$minutes ${minutes == 1 ? 'minute' : 'minutes'}' : '${minutes}m');
  }
  if (seconds > 0) {
    parts.add(useFullWords ? '$seconds ${seconds == 1 ? 'second' : 'seconds'}' : '${seconds}s');
  }

  return addSpaces(parts.isEmpty 
    ? (useFullWords ? '0 seconds' : '0s') 
    : parts.join(useFullWords ? ', ' : ''));
}
