import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows a one-shot prayer-time notification when Adhan cannot play.
class PrayerTimeNotificationService {
  PrayerTimeNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 310;
  static const String _channelId = 'prayer_time_alerts_v1';
  static const String _channelName = 'تنبيهات الصلاة';
  static const String _channelDescription =
      'إشعار عند حلول وقت الصلاة أثناء المكالمة';

  static bool _initialized = false;

  /// Initializes the notifications plugin (safe to call from alarm isolate).
  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Shows: حان وقت صلاة [prayerName]
  static Future<void> showPrayerTime(String prayerName) async {
    try {
      await init();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: _notificationId,
        title: 'إسلامي',
        body: 'حان وقت صلاة $prayerName',
        notificationDetails: details,
      );
    } catch (e) {
      log('PrayerTimeNotificationService error: $e');
    }
  }
}
