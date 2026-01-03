import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service untuk mengelola local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Channel IDs
  static const String _morningChannelId = 'morning_reminder';
  static const String _afternoonChannelId = 'afternoon_reminder';
  static const String _eveningChannelId = 'evening_reminder';

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Skip on web
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      // Android settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Request later
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android (doesn't require permission)
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      _initialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _morningChannelId,
          'Pengingat Pagi',
          description: 'Notifikasi untuk ibadah pagi',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _afternoonChannelId,
          'Pengingat Sore',
          description: 'Notifikasi untuk ibadah sore',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _eveningChannelId,
          'Pengingat Malam',
          description: 'Notifikasi untuk evaluasi harian',
          importance: Importance.high,
        ),
      );
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on payload
    final payload = response.payload;
    if (payload != null) {
      // TODO: Navigate to specific screen based on payload
      print('Notification tapped: $payload');
    }
  }

  /// Request permission (iOS)
  static Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    }

    return false;
  }

  /// Schedule morning reminder (05:00)
  static Future<void> scheduleMorningReminder() async {
    await _scheduleDaily(
      id: 1,
      hour: 5,
      minute: 0,
      channelId: _morningChannelId,
      title: '🌅 Selamat Pagi!',
      body: 'Sudahkah shalat Tahajud dan membaca Al-Qur\'an hari ini?',
      payload: 'morning',
    );
  }

  /// Schedule afternoon reminder (15:30)
  static Future<void> scheduleAfternoonReminder() async {
    await _scheduleDaily(
      id: 2,
      hour: 15,
      minute: 30,
      channelId: _afternoonChannelId,
      title: '🌙 Pengingat Al-Ma\'tsurat Sore',
      body: 'Akhi, jangan lupa baca Al-Ma\'tsurat/Wadzifah Sugro sore ini ya!',
      payload: 'afternoon',
    );
  }

  /// Schedule evening review reminder (21:00)
  static Future<void> scheduleEveningReminder() async {
    await _scheduleDaily(
      id: 3,
      hour: 21,
      minute: 0,
      channelId: _eveningChannelId,
      title: '📊 Waktunya Evaluasi Harian',
      body:
          'Yuk isi tracking ibadah hari ini dan lihat ringkasan dari Syeikh Syarafi!',
      payload: 'evening',
    );
  }

  /// Schedule all default reminders
  static Future<void> scheduleAllReminders() async {
    await scheduleMorningReminder();
    await scheduleAfternoonReminder();
    await scheduleEveningReminder();
  }

  /// Cancel all reminders
  static Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific reminder
  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'Notifikasi Umum',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Schedule daily notification
  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _morningChannelId
          ? 'Pengingat Pagi'
          : channelId == _afternoonChannelId
              ? 'Pengingat Sore'
              : 'Pengingat Malam',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTime = _nextInstanceOfTime(hour, minute);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Get next instance of a specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
