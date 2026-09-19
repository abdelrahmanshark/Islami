import 'dart:developer';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:islami/data/time/time_repository.dart';
import 'package:islami/services/adhan_player.dart';
import 'package:islami/ui/home/tabs/time_screen/helpers/next_prayer_calculator.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/utils/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/// Fixed alarm IDs for the five daily prayers and the daily refresh.
class AdhanAlarmIds {
  static const int fajr = 1;
  static const int dhuhr = 2;
  static const int asr = 3;
  static const int maghrib = 4;
  static const int isha = 5;
  static const int dailyRefresh = 99;

  static const List<int> all = [
    fajr,
    dhuhr,
    asr,
    maghrib,
    isha,
    dailyRefresh,
  ];
}

/// Plays Adhan when a prayer alarm fires (runs in a background isolate).
@pragma('vm:entry-point')
Future<void> adhanAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();

  final bool enabled = await getAzanEnabled();
  if (!enabled) {
    return;
  }

  await AdhanPlayer.play();
}

/// Refetches prayer times after midnight and reschedules alarms.
@pragma('vm:entry-point')
Future<void> adhanRefreshCallback() async {
  DartPluginRegistrant.ensureInitialized();

  try {
    final timeResponse = await TimeRepositoryImpl().getTimeResponse();
    final Timings? timings = timeResponse.data?.timings;
    if (timings == null) {
      return;
    }

    await AdhanAlarmScheduler.persistTimings(timings);
    await AdhanAlarmScheduler.scheduleFromTimings(timings);
  } catch (e) {
    log('adhanRefreshCallback error: $e');
  }
}

/// Schedules exact Adhan alarms via Android AlarmManager.
class AdhanAlarmScheduler {
  AdhanAlarmScheduler._();

  /// Requests exact-alarm permission, then schedules from [timings].
  static Future<void> scheduleFromTimings(Timings timings) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final bool enabled = await getAzanEnabled();
    if (!enabled) {
      await cancelAll();
      return;
    }

    final bool hasPermission = await _ensureExactAlarmPermission();
    if (!hasPermission) {
      log('Exact alarm permission not granted');
      return;
    }

    await persistTimings(timings);
    await cancelAll();

    final DateTime now = DateTime.now();
    final List<({int id, DateTime time})> prayerAlarms = _buildPrayerAlarms(
      timings,
      now,
    );

    for (final alarm in prayerAlarms) {
      await _scheduleOneShot(alarm.time, alarm.id, adhanAlarmCallback);
    }

    // Refresh times shortly after local midnight.
    final DateTime refreshAt = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1, minutes: 1));
    await _scheduleOneShot(refreshAt, AdhanAlarmIds.dailyRefresh, adhanRefreshCallback);
  }

  /// Reschedules from SharedPreferences after mute is turned back on.
  static Future<void> rescheduleFromSaved() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final SavedPrayerTimings? saved = await getSavedPrayerTimings();
    if (saved == null) {
      return;
    }

    final Timings timings = Timings(
      fajr: saved.fajr,
      dhuhr: saved.dhuhr,
      asr: saved.asr,
      maghrib: saved.maghrib,
      isha: saved.isha,
    );

    await scheduleFromTimings(timings);
  }

  /// Cancels all Adhan and refresh alarms.
  static Future<void> cancelAll() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    for (final int id in AdhanAlarmIds.all) {
      await AndroidAlarmManager.cancel(id);
    }
  }

  /// Saves raw salah times so alarms can be restored later.
  static Future<void> persistTimings(Timings timings) async {
    final DateTime now = DateTime.now();
    final String date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    await savePrayerTimings(
      date: date,
      fajr: timings.fajr ?? '',
      dhuhr: timings.dhuhr ?? '',
      asr: timings.asr ?? '',
      maghrib: timings.maghrib ?? '',
      isha: timings.isha ?? '',
    );
  }

  /// Builds future prayer alarm times from API timings.
  static List<({int id, DateTime time})> _buildPrayerAlarms(
    Timings timings,
    DateTime now,
  ) {
    final List<({int id, String? raw})> prayers = [
      (id: AdhanAlarmIds.fajr, raw: timings.fajr),
      (id: AdhanAlarmIds.dhuhr, raw: timings.dhuhr),
      (id: AdhanAlarmIds.asr, raw: timings.asr),
      (id: AdhanAlarmIds.maghrib, raw: timings.maghrib),
      (id: AdhanAlarmIds.isha, raw: timings.isha),
    ];

    final List<({int id, DateTime time})> result = [];
    DateTime? fajrToday;

    for (final prayer in prayers) {
      final String cleaned = NextPrayerCalculator.cleanTime(prayer.raw);
      final DateTime? todayTime =
          NextPrayerCalculator.toTodayDateTime(cleaned, now);
      if (todayTime == null) {
        continue;
      }

      if (prayer.id == AdhanAlarmIds.fajr) {
        fajrToday = todayTime;
      }

      if (todayTime.isAfter(now)) {
        result.add((id: prayer.id, time: todayTime));
      }
    }

    // After Isha, schedule tomorrow's Fajr using today's Fajr + 1 day.
    if (result.isEmpty && fajrToday != null) {
      result.add((
        id: AdhanAlarmIds.fajr,
        time: fajrToday.add(const Duration(days: 1)),
      ));
    }

    return result;
  }

  /// Schedules one exact alarm that wakes the device.
  static Future<void> _scheduleOneShot(
    DateTime time,
    int id,
    Function callback,
  ) async {
    final bool scheduled = await AndroidAlarmManager.oneShotAt(
      time,
      id,
      callback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );
    log('Scheduled alarm $id at $time → $scheduled');
  }

  /// Requests SCHEDULE_EXACT_ALARM permission when needed.
  static Future<bool> _ensureExactAlarmPermission() async {
    PermissionStatus status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      return true;
    }

    status = await Permission.scheduleExactAlarm.request();
    if (status.isGranted) {
      return true;
    }

    // Open settings only when the OS blocks further in-app prompts.
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      status = await Permission.scheduleExactAlarm.status;
    }

    return status.isGranted;
  }
}
