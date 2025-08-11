import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class FLoggerHelper {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,           // Number of stack trace lines
      errorMethodCount: 5,      // Number of stack trace lines for errors
      lineLength: 100,          // Log line width
      colors: true,             // Enable colors
      printEmojis: true,        // Enable emojis
      dateTimeFormat: DateTimeFormat.dateAndTime, // Show timestamp
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  /// Debug-level log
  static void debug(String message) {
    _logger.d(message);
  }

  /// Info-level log
  static void info(String message) {
    _logger.i(message);
  }

  /// Warning-level log
  static void warning(String message) {
    _logger.w(message);
  }

  /// Error-level log with optional error object and stack trace
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace ?? StackTrace.current);
  }

  /// Fatal error (What a Terrible Failure)
  static void wtf(String message) {
    _logger.wtf(message);
  }
}
