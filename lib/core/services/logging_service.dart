import 'package:logger/logger.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;

  late final Logger _logger;
  bool _initialized = false;

  LoggingService._internal() {
    _initLogger();
  }

  void _initLogger() {
    if (_initialized) return;

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: Level.verbose,
    );

    _initialized = true;
  }

  void logInfo(String message) {
    _logger.i(message);
  }

  void logDebug(String message) {
    _logger.d(message);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (error != null) {
      _logger.e(message, error, stackTrace);
    } else {
      _logger.e(message);
    }
  }

  void logWarning(String message) {
    _logger.w(message);
  }

  void dispose() {
    _logger.close();
  }
}