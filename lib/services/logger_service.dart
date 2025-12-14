import 'package:flutter/foundation.dart';

/// Logger Service - Easy to enable/disable logging
/// Set [LoggerService.enabled] to false to disable all logs
class LoggerService {
  // Set this to false to disable all logging
  static const bool enabled = true; // Change to false to disable all logs

  static void d(String tag, String message) {
    if (enabled) {
      debugPrint('[$tag] $message');
    }
  }

  static void i(String tag, String message) {
    if (enabled) {
      debugPrint('[$tag] ℹ️ $message');
    }
  }

  static void w(String tag, String message) {
    if (enabled) {
      debugPrint('[$tag] ⚠️ $message');
    }
  }

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (enabled) {
      debugPrint('[$tag] ❌ $message');
      if (error != null) {
        debugPrint('[$tag] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$tag] StackTrace: $stackTrace');
      }
    }
  }

  static void v(String tag, String message) {
    if (enabled) {
      debugPrint('[$tag] 🔍 $message');
    }
  }

  // Log method calls
  static void logMethod(String className, String methodName, [Map<String, dynamic>? params]) {
    if (enabled) {
      final paramsStr = params != null ? ' with params: $params' : '';
      debugPrint('[$className] → $methodName()$paramsStr');
    }
  }

  // Log navigation
  static void logNavigation(String from, String to) {
    if (enabled) {
      debugPrint('[$from] → Navigate to: $to');
    }
  }

  // Log API calls
  static void logApi(String method, String url, [Map<String, dynamic>? body]) {
    if (enabled) {
      final bodyStr = body != null ? ' | Body: $body' : '';
      debugPrint('🌐 API: $method $url$bodyStr');
    }
  }

  // Log user actions
  static void logUserAction(String action, [Map<String, dynamic>? data]) {
    if (enabled) {
      final dataStr = data != null ? ' | Data: $data' : '';
      debugPrint('👤 User Action: $action$dataStr');
    }
  }
}

