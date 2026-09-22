import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Fixed IDs so weekly reminders can be cancelled and never duplicated.
class WeeklyNotificationIds {
  static const int monday = 200;
  static const int thursday = 201;
  static const int friday = 202;

  static const List<int> all = [monday, thursday, friday];
}

/// Schedules silent weekly local notifications at local midnight.
class WeeklyNotificationService {
  WeeklyNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'weekly_silent_reminders_v1';
  static const String _channelName = 'تذكيرات أسبوعية';
  static const String _channelDescription =
      'تذكيرات صامتة لصيام الاثنين والخميس وكهف الجمعة';

  static const String _mondayBody =
      'كان النبي صلى الله عليه وسلم يحب صوم الاثنين';
  static const String _thursdayBody =
      'كان النبي صلى الله عليه وسلم يحب صوم الخميس';
  static const String _fridayBody =
      'أكثر من الصلاة على النبي، ولا تنسى كهف الجمعة';

  /// Initializes the plugin, timezone, and permission, then schedules reminders.
  static Future<void> initAndSchedule() async {
    try {
      await _configureLocalTimeZone();
      await _initializePlugin();
      await _requestPermissions();
      await scheduleWeeklyReminders();
    } catch (e) {
      log('WeeklyNotificationService init error: $e');
    }
  }

  /// Cancels existing weekly IDs then schedules Mon/Thu/Fri at 12:00 AM.
  static Future<void> scheduleWeeklyReminders() async {
    await _cancelWeekly();

    await _scheduleOne(
      id: WeeklyNotificationIds.monday,
      weekday: DateTime.monday,
      body: _mondayBody,
    );
    await _scheduleOne(
      id: WeeklyNotificationIds.thursday,
      weekday: DateTime.thursday,
      body: _thursdayBody,
    );
    await _scheduleOne(
      id: WeeklyNotificationIds.friday,
      weekday: DateTime.friday,
      body: _fridayBody,
    );
  }

  /// Sets up flutter_local_notifications for Android and iOS.
  static Future<void> _initializePlugin() async {
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
  }

  /// Loads IANA zones and sets the device local timezone.
  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  }

  /// Asks for notification (and exact-alarm) permissions when needed.
  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: false, sound: false);
    }
  }

  /// Removes only the weekly reminder notifications.
  static Future<void> _cancelWeekly() async {
    for (final int id in WeeklyNotificationIds.all) {
      await _plugin.cancel(id: id);
    }
  }

  /// Schedules one weekly silent notification at local midnight.
  static Future<void> _scheduleOne({
    required int id,
    required int weekday,
    required String body,
  }) async {
    final tz.TZDateTime scheduledDate = _nextMidnightOfWeekday(weekday);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      silent: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: 'إسلامي',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    log('Scheduled weekly notification $id at $scheduledDate');
  }

  /// Finds the next occurrence of [weekday] at 00:00 local time.
  static tz.TZDateTime _nextMidnightOfWeekday(int weekday) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
    );

    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
