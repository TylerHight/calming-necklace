import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

class CustomLogPrinter extends LogPrinter {
  static final _levelEmojis = {
    Level.verbose: '🗣️',
    Level.debug: '🔍',
    Level.info: '📘',
    Level.warning: '⚠️',
    Level.error: '🚨',
    Level.wtf: '💀',
  };

  final bool printTime;
  final bool colors;
  final Map<Level, String> customEmojis;

  CustomLogPrinter({
    this.printTime = true,
    this.colors = true,
    Map<Level, String>? customEmojis,
  }) : this.customEmojis = customEmojis ?? _levelEmojis;

  @override
  List<String> log(LogEvent event) {
    var messageStr = _stringifyMessage(event.message);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    var timeStr = printTime ? _getTime() : '';
    var callerStr = _getCaller();
    var emoji = customEmojis[event.level] ?? _levelEmojis[event.level] ?? '';

    return [
      '$timeStr $emoji [$callerStr] $messageStr$errorStr',
      if (event.stackTrace != null) ...(_formatStackTrace(event.stackTrace!))
    ];
  }

  String _stringifyMessage(dynamic message) {
    if (message is Function) return message();
    if (message is String) return message;
    return message.toString();
  }

  String _getTime() {
    var now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
           '${now.minute.toString().padLeft(2, '0')}:'
           '${now.second.toString().padLeft(2, '0')}';
  }

  String _getCaller() {
    const skipFrames = 5;
    const maxFrames = 3;
    var frames = StackTrace.current.toString().split('\n');
    
    for (var i = skipFrames; i < skipFrames + maxFrames && i < frames.length; i++) {
      var frame = frames[i];
      if (_isRelevantFrame(frame)) {
        var fileInfo = _extractFileInfo(frame);
        if (fileInfo != null) return fileInfo;
      }
    }
    return 'unknown';
  }

  bool _isRelevantFrame(String frame) {
    return frame.contains(RegExp(r'dart:|\w+\.dart'));
  }

  String? _extractFileInfo(String frame) {
    var match = RegExp(r'(?:package:)?([^\s]+\.dart)').firstMatch(frame);
    if (match != null) {
      var file = match.group(1)!;
      return path.basename(file).replaceAll('.dart', '');
    }
    return null;
  }

  List<String> _formatStackTrace(StackTrace stackTrace) {
    var lines = stackTrace.toString().split('\n');
    return lines.take(8).map((line) => '  $line').toList();
  }
}
