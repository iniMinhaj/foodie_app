import 'dart:developer' as developer;
import 'error.dart';

// Conditional imports — project এ যেটা থাকবে সেটা uncomment করো
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

enum LogLevel { debug, info, warning, error, fatal }

/// Unified logger — Crashlytics + Sentry দুটোই support করে।
/// release mode এ remote log, debug mode এ console log।
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  // ── Configuration ───────────────────────────────────────────
  static bool _crashlyticsEnabled = false;
  static bool _sentryEnabled = false;

  static void configure({bool crashlytics = false, bool sentry = false}) {
    _crashlyticsEnabled = crashlytics;
    _sentryEnabled = sentry;
  }

  // ── Public API ───────────────────────────────────────────────

  void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
    _reportRemotely(
      message,
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
  }

  void fatal(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );
    _reportRemotely(
      message,
      level: LogLevel.fatal,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
      isFatal: true,
    );
  }

  // ── Internal ─────────────────────────────────────────────────

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    if (!kDebugMode) return; // console log শুধু debug mode এ

    final prefix = _prefix(level);
    final tagStr = tag != null ? '[$tag] ' : '';
    developer.log(
      '$prefix $tagStr$message',
      name: 'AppLogger',
      error: error,
      stackTrace: stackTrace,
      level: _dartLogLevel(level),
    );
  }

  Future<void> _reportRemotely(
    String message, {
    required LogLevel level,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
    bool isFatal = false,
  }) async {
    if (kDebugMode) return; // remote log শুধু release/profile mode এ

    // ── Firebase Crashlytics ─────────────────────────────────
    if (_crashlyticsEnabled) {
      // Uncomment when firebase_crashlytics is added:
      //
      // final crashlytics = FirebaseCrashlytics.instance;
      // if (extra != null) {
      //   for (final entry in extra.entries) {
      //     await crashlytics.setCustomKey(entry.key, entry.value.toString());
      //   }
      // }
      // if (isFatal) {
      //   await crashlytics.recordError(
      //     error ?? message,
      //     stackTrace,
      //     fatal: true,
      //   );
      // } else {
      //   await crashlytics.recordError(error ?? message, stackTrace);
      // }
    }

    // ── Sentry ───────────────────────────────────────────────
    if (_sentryEnabled) {
      // Uncomment when sentry_flutter is added:
      //
      // await Sentry.captureException(
      //   error ?? message,
      //   stackTrace: stackTrace,
      //   withScope: (scope) {
      //     scope.level = isFatal ? SentryLevel.fatal : SentryLevel.error;
      //     if (extra != null) {
      //       scope.setExtras(extra);
      //     }
      //   },
      // );
    }
  }

  String _prefix(LogLevel level) => switch (level) {
    LogLevel.debug => '🔍 DEBUG',
    LogLevel.info => 'ℹ️  INFO',
    LogLevel.warning => '⚠️  WARN',
    LogLevel.error => '❌ ERROR',
    LogLevel.fatal => '💀 FATAL',
  };

  int _dartLogLevel(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
    LogLevel.fatal => 1200,
  };
}

/// Shorthand — `logger.error(...)` সরাসরি
final logger = AppLogger.instance;
