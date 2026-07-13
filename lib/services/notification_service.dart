import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    // Gunakan zona waktu Indonesia Tengah (WITA/Makassar) secara default
    tz.setLocalLocation(tz.getLocation('Asia/Makassar'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
    
    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleCheckoutReminder(DateTime targetTime) async {
    if (!_isInitialized) await init();

    final now = DateTime.now();
    if (targetTime.isBefore(now)) return; // Already passed

    // Request permission on Android 13+ right before scheduling to ensure Activity is present
    if (Platform.isAndroid) {
      final androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }

    // Schedule notification
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1001, // Unique ID for checkout reminder
      'Waktunya Absen Pulang!',
      'Jam shift Anda sudah berakhir. Jangan lupa untuk melakukan absen pulang di aplikasi.',
      tz.TZDateTime.from(targetTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkout_reminder',
          'Checkout Reminders',
          channelDescription: 'Notifikasi untuk mengingatkan absen pulang',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    debugPrint("Scheduled checkout reminder for: $targetTime");
  }

  Future<void> cancelCheckoutReminder() async {
    if (!_isInitialized) return;
    await _flutterLocalNotificationsPlugin.cancel(1001);
    debugPrint("Cancelled checkout reminder");
  }
}
