import 'package:logger/logger.dart';

class LogManager {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );

  static void info(String message) => _logger.i(message);
  static void error(String message) => _logger.e(message);
  static void warning(String message) => _logger.w(message);
}
