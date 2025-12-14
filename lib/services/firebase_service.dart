import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseMessaging? _messaging;
  String? _fcmToken;
  String? _installationId;

  FirebaseAnalytics? get analytics => _analytics;
  FirebaseMessaging? get messaging => _messaging;
  String? get fcmToken => _fcmToken;
  String? get installationId => _installationId;

  Future<void> initialize() async {
    try {
      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);

      // Initialize Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;
      
      // Request notification permissions
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Get FCM token
      _fcmToken = await _messaging!.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });

      // Use FCM Token as Installation ID (unique per installation)
      _installationId = _fcmToken;
      debugPrint('Installation ID (FCM Token): $_installationId');

      // Setup foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Setup background message handler (must be top-level function)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      debugPrint('Firebase Service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing Firebase Service: $e');
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
    
    // Handle APK ready notification
    if (message.data['type'] == 'apk_ready') {
      final jobId = message.data['job_id'];
      final downloadUrl = message.data['download_url'];
      final filename = message.data['filename'];
      
      debugPrint('APK ready notification: jobId=$jobId, downloadUrl=$downloadUrl');
      
      // This will be handled by the app's notification handler
      // which will show a dialog
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification}');
    
    // Handle APK ready notification when app is opened from notification
    if (message.data['type'] == 'apk_ready') {
      final jobId = message.data['job_id'];
      final downloadUrl = message.data['download_url'];
      final filename = message.data['filename'];
      
      debugPrint('APK ready - opened from notification: jobId=$jobId');
      // This will be handled by the app's navigation/routing
    }
  }

  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  void logError(dynamic error, StackTrace? stackTrace, {bool fatal = false}) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: fatal,
    );
  }

  void logCustomCrash(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  void setCrashlyticsUserId(String userId) {
    FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification}');
}

