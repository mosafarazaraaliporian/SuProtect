import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

const AndroidNotificationChannel uploadChannel = AndroidNotificationChannel(
  'upload_channel',
  'File Upload',
  description: 'Shows progress of file uploads',
  importance: Importance.low,
  playSound: false,
  enableVibration: false,
);

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
    
    // Create notification channel for upload progress
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'upload_channel',
      'File Upload',
      description: 'Shows progress of file uploads',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    _initialized = true;
  }

  Future<void> showUploadProgressNotification({
    required int progress,
    required String fileName,
  }) async {
    if (!_initialized) await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      uploadChannel.id,
      uploadChannel.name,
      channelDescription: uploadChannel.description,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      indeterminate: false,
      channelShowBadge: false,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      1,
      'Uploading APK',
      'Uploading $fileName... $progress%',
      notificationDetails,
      payload: 'upload',
    );
  }

  Future<void> showUploadCompleteNotification(String fileName) async {
    if (!_initialized) await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      uploadChannel.id,
      uploadChannel.name,
      channelDescription: uploadChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
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

