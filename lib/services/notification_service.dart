import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showUploadProgressNotification({
    required int progress,
    required String fileName,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'upload_channel',
      'File Upload',
      channelDescription: 'Shows progress of file uploads',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: 0,
      indeterminate: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      1,
      'Uploading APK',
      'Uploading $fileName...',
      notificationDetails,
      payload: 'upload',
    );

    // Update progress
    await _notifications.show(
      1,
      'Uploading APK',
      'Uploading $fileName... $progress%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'upload_channel',
          'File Upload',
          channelDescription: 'Shows progress of file uploads',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          indeterminate: false,
        ),
      ),
      payload: 'upload',
    );
  }

  Future<void> showUploadCompleteNotification(String fileName) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'upload_channel',
      'File Upload',
      channelDescription: 'Shows progress of file uploads',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      1,
      'Upload Complete',
      '$fileName uploaded successfully',
      notificationDetails,
      payload: 'upload_complete',
    );
  }

  Future<void> cancelNotification() async {
    await _notifications.cancel(1);
  }
}

