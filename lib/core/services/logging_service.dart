import 'package:logger/logger.dart';
import 'logging/custom_log_printer.dart';
import 'logging/file_output.dart' as custom_file_output;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class LoggingService {
  static LoggingService? _instance;
  static Future<LoggingService> getInstance() async {
    if (_instance == null) {
      _instance = LoggingService._internal();
      await _instance!._initLogger();
    }
    return _instance!;
  }
  
  // Synchronous getter for cases where we know logger is initialized
  static LoggingService get instance => _instance!;

  late Logger _logger;
  File? _logFile;
  bool _initialized = false;
  static const String _logFileName = 'app_logs.txt';

  LoggingService._internal();

  Future<void> _initLogger() async {
    if (_initialized) return;
    print('Initializing logging service...'); // Debug print
    
    await _setupLogFile();
    _logger = Logger(
      printer: CustomLogPrinter(
        colors: true,
        printTime: true,
        customEmojis: {
          Level.verbose: '🗣️',
          Level.debug: '🔍',
          Level.info: '📘',
          Level.warning: '⚠️',
          Level.error: '🚨',
          Level.wtf: '💀',
        },
      ),
      level: Level.verbose,
      output: MultiOutput([
        ConsoleOutput(),
        if (_logFile != null)
          custom_file_output.FileOutput(
            file: _logFile!,
            overrideExisting: false,
            encoding: utf8,
          )
      ]),
    );

    _initialized = true;
    logInfo('Logging service initialized successfully');
  }

  Future<void> _setupLogFile() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create();
      }
      _logFile = File('${logsDir.path}/$_logFileName');
    } catch (e) {
      print('Failed to setup log file: $e');
      _logFile = null;
    }
  }

  void logInfo(String message) {
    if (_initialized) _logger.i('ℹ️ $message');
  }

  void logDebug(String message) {
    if (_initialized) _logger.d('🔍 $message');
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_initialized) {
      if (error != null) {
        _logger.e('❌ $message', error, stackTrace);
      } else {
        _logger.e('❌ $message');
      }
    }
  }

  void logWarning(String message) {
    if (_initialized) _logger.w(message);
  }

  void logBleInfo(String message) {
    logInfo(message);
  }

  void logBleError(String message, [dynamic error, StackTrace? stackTrace]) {
    logError(message, error, stackTrace);
  }

  void logBleDebug(String message) {
    logDebug(message);
  }

  void logBleWarning(String message) {
    logWarning(message);
  }

  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }
  }

  Future<String> exportLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      return await _logFile!.readAsString();
    }
    return '';
  }

  void dispose() {
    _logger.close();
  }
}
