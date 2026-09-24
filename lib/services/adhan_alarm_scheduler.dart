import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:islami/data/time/time_repository.dart';
import 'package:islami/models/adhan_alarm_entry.dart';
import 'package:islami/models/user_location.dart';
import 'package:islami/services/prayer_widget_updater.dart';
import 'package:islami/services/user_location_service.dart';
import 'package:islami/ui/home/tabs/time_screen/helpers/next_prayer_calculator.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';
import 'package:islami/utils/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/// Alarm IDs used with android_alarm_manager_plus.
class AdhanAlarmIds {
  // Per-prayer alarms from older builds; cancelled so they never fire twice.
  static const List<int> legacyPrayerIds = [1, 2, 3, 4, 5];
  static const int dailyRefresh = 99;
}

/// Refetches prayer times after midnight and saves a fresh Adhan schedule.
@pragma('vm:entry-point')
Future<void> adhanRefreshCallback() async {
  DartPluginRegistrant.ensureInitialized();
  // This isolate stays alive between alarms, so re-read what the app saved.
  await reloadPreferences();

  try {
    // Without a saved location we would need GPS permission, which needs the UI.
    final UserLocation? location =
        await UserLocationService().getSavedLocation();
    if (location != null) {
      final timeResponse = await TimeRepositoryImpl().getTimeResponse();
      final Timings? timings = timeResponse.data?.timings;
      if (timings != null) {
        await AdhanAlarmScheduler.scheduleFromTimings(
          timings,
          refreshUpcoming: true,
        );
        await AdhanAlarmScheduler.updateHomeWidgetFromTimings(timings);
      }
    }
  } catch (e) {
    log('adhanRefreshCallback error: $e');
  } finally {
    // Keep the daily refresh chain alive even when this refresh failed.
    if (await getAzanEnabled()) {
      await AdhanAlarmScheduler.scheduleDailyRefresh();
    }
  }
}

/// Builds the Adhan schedule in Flutter and hands it to Android to fire.
///
/// Android (AdhanScheduler.kt / AdhanPlaybackService.kt) only fires the saved
/// times and plays the Adhan, so it works while the app is closed.
class AdhanAlarmScheduler {
  AdhanAlarmScheduler._();

  /// How many days of Adhan alarms are kept scheduled ahead.
  static const int _daysAhead = 7;

  static const MethodChannel _channel =
      MethodChannel('com.example.islami/adhan');

  /// Asks for exact-alarm access. Call only from UI code (it opens a settings
  /// screen), never from background isolates.
  static Future<void> requestExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final PermissionStatus status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      return;
    }
    await Permission.scheduleExactAlarm.request();
  }

  /// Saves the next [_daysAhead] days of Adhan times and asks Android to
  /// schedule them. Never requests permissions (safe from background).
  static Future<void> scheduleFromTimings(
    Timings timings, {
    bool refreshUpcoming = false,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final bool enabled = await getAzanEnabled();
    if (!enabled) {
      await cancelAll();
      return;
    }

    await persistTimings(timings);

    List<PrayerData> upcomingDays = [];
    try {
      upcomingDays = await TimeRepositoryImpl().getUpcomingPrayerDays(
        days: _daysAhead,
        forceRefresh: refreshUpcoming,
      );
    } catch (e) {
      log('Could not load upcoming prayer days: $e');
    }

    final List<AdhanAlarmEntry> entries = _buildAlarmEntries(
      upcomingDays,
      timings,
      DateTime.now(),
    );
    final List<Map<String, dynamic>> entriesJson = [];
    for (final AdhanAlarmEntry entry in entries) {
      entriesJson.add(entry.toJson());
    }
    await saveAdhanSchedule(jsonEncode(entriesJson));

    for (final int id in AdhanAlarmIds.legacyPrayerIds) {
      await AndroidAlarmManager.cancel(id);
    }
    await _rescheduleNative();
    await scheduleDailyRefresh();
  }

  /// Reschedules from saved times (app startup, or after unmuting Adhan).
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

  /// Cancels all Adhan alarms and the daily refresh.
  static Future<void> cancelAll() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('cancelAll');
    } on MissingPluginException {
      // Background isolate: Android checks the Adhan setting before playing.
    } catch (e) {
      log('Native Adhan cancel failed: $e');
    }

    await AndroidAlarmManager.cancel(AdhanAlarmIds.dailyRefresh);
    for (final int id in AdhanAlarmIds.legacyPrayerIds) {
      await AndroidAlarmManager.cancel(id);
    }
  }

  /// Schedules the next background refresh shortly after local midnight.
  static Future<void> scheduleDailyRefresh() async {
    final DateTime now = DateTime.now();
    final DateTime refreshAt = DateTime(now.year, now.month, now.day + 1, 0, 5);

    // Inexact is fine here: the Adhan alarms are already scheduled days ahead.
    await AndroidAlarmManager.oneShotAt(
      refreshAt,
      AdhanAlarmIds.dailyRefresh,
      adhanRefreshCallback,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
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

  /// Pushes cached/refreshed salah times to the home widget.
  static Future<void> updateHomeWidgetFromTimings(Timings timings) async {
    final DateTime now = DateTime.now();
    final List<Prayer> prayerTimes = [
      Prayer(NextPrayerCalculator.cleanTime(timings.fajr), 'الفجر'),
      Prayer(NextPrayerCalculator.cleanTime(timings.dhuhr), 'الظهر'),
      Prayer(NextPrayerCalculator.cleanTime(timings.asr), 'العصر'),
      Prayer(NextPrayerCalculator.cleanTime(timings.maghrib), 'المغرب'),
      Prayer(NextPrayerCalculator.cleanTime(timings.isha), 'العشاء'),
    ];
    final NextPrayerResult? next =
        NextPrayerCalculator.findNext(prayerTimes, now);

    await PrayerWidgetUpdater.update(
      prayerTimes: prayerTimes,
      nextResult: next,
    );
  }

  /// Asks Android to schedule alarms from the saved Adhan schedule.
  static Future<void> _rescheduleNative() async {
    try {
      await _channel.invokeMethod<void>('reschedule');
    } on MissingPluginException {
      // Background isolate: Android re-reads the schedule at the next Adhan.
    } catch (e) {
      log('Native Adhan reschedule failed: $e');
    }
  }

  /// Builds future Adhan times for the next [_daysAhead] days.
  /// Days missing from [upcomingDays] reuse [latestTimings] (a few minutes off
  /// at most), so the Adhan never goes silent just because we are offline.
  static List<AdhanAlarmEntry> _buildAlarmEntries(
    List<PrayerData> upcomingDays,
    Timings latestTimings,
    DateTime now,
  ) {
    final Map<String, Timings> timingsByDay = {};
    for (final PrayerData day in upcomingDays) {
      final DateTime? date =
          NextPrayerCalculator.parseApiDate(day.date?.gregorian?.date);
      final Timings? timings = day.timings;
      if (date != null && timings != null) {
        timingsByDay[_dayKey(date)] = timings;
      }
    }

    final List<AdhanAlarmEntry> entries = [];
    for (int offset = 0; offset < _daysAhead; offset++) {
      final DateTime day = DateTime(now.year, now.month, now.day + offset);
      final Timings timings = timingsByDay[_dayKey(day)] ?? latestTimings;

      final List<({String name, String? raw})> salahTimes = [
        (name: 'الفجر', raw: timings.fajr),
        (name: 'الظهر', raw: timings.dhuhr),
        (name: 'العصر', raw: timings.asr),
        (name: 'المغرب', raw: timings.maghrib),
        (name: 'العشاء', raw: timings.isha),
      ];

      for (final salah in salahTimes) {
        final String cleaned = NextPrayerCalculator.cleanTime(salah.raw);
        final DateTime? time = NextPrayerCalculator.toTodayDateTime(cleaned, day);
        if (time != null && time.isAfter(now)) {
          entries.add(AdhanAlarmEntry(time: time, prayerName: salah.name));
        }
      }
    }

    return entries;
  }

  /// Map key for one calendar day, e.g. "2026-9-24".
  static String _dayKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
