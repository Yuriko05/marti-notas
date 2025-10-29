import 'dart:developer' as developer;

/// Utilidad simple de logging para la app
/// Usa dart:developer en lugar de print() para mejor integración con herramientas de debugging
class AppLogger {
  static void log(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name ?? 'MartiNotas',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message, {String? name}) {
    log('ℹ️ $message', name: name);
  }

  static void success(String message, {String? name}) {
    log('✅ $message', name: name);
  }

  static void warning(String message, {String? name}) {
    log('⚠️ $message', name: name);
  }

  static void error(String message,
      {Object? error, StackTrace? stackTrace, String? name}) {
    log('❌ $message', name: name, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, {String? name}) {
    log('🔍 $message', name: name);
  }
}
