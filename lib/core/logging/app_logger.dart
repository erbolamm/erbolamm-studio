import 'dart:developer' as developer;

class AppLogger {
  static void i(String message, [String name = 'App']) {
    developer.log(message, name: name);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace, String name = 'App']) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace);
  }
}
