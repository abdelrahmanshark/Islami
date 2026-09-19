import 'dart:developer';

import 'package:home_widget/home_widget.dart';
import 'package:islami/ui/home/tabs/time_screen/helpers/next_prayer_calculator.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';

/// Pushes prayer times to the Android home screen widget.
class PrayerWidgetUpdater {
  PrayerWidgetUpdater._();

  static const String androidWidgetName = 'PrayerTimesWidgetProvider';
  static const String qualifiedAndroidName =
      'com.example.islami.PrayerTimesWidgetProvider';

  /// Saves salah times and next-prayer info, then refreshes the widget.
  static Future<void> update({
    required List<Prayer> prayerTimes,
    required NextPrayerResult? nextResult,
    required DateTime now,
  }) async {
    try {
      final Map<String, String> salahTimes = {};
      for (final Prayer prayer in prayerTimes) {
        if (NextPrayerCalculator.salahNames.contains(prayer.PryerName)) {
          salahTimes[prayer.PryerName] = prayer.PryerTime;
        }
      }

      await HomeWidget.saveWidgetData<String>(
        'fajr',
        salahTimes['الفجر'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'dhuhr',
        salahTimes['الظهر'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'asr',
        salahTimes['العصر'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'maghrib',
        salahTimes['المغرب'] ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        'isha',
        salahTimes['العشاء'] ?? '',
      );

      if (nextResult != null) {
        final Duration remaining = nextResult.remainingFrom(now);
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_name',
          nextResult.prayer.PryerName,
        );
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          nextResult.prayer.PryerTime,
        );
        // Store as string so epoch ms never overflows Android int prefs
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_epoch_ms',
          nextResult.dateTime.millisecondsSinceEpoch.toString(),
        );
        await HomeWidget.saveWidgetData<String>(
          'remaining_hm',
          NextPrayerCalculator.formatRemainingHm(remaining),
        );
      } else {
        await HomeWidget.saveWidgetData<String>('next_prayer_name', '');
        await HomeWidget.saveWidgetData<String>('next_prayer_time', '');
        await HomeWidget.saveWidgetData<String>('next_prayer_epoch_ms', '');
        await HomeWidget.saveWidgetData<String>('remaining_hm', '--:--');
      }

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        qualifiedAndroidName: qualifiedAndroidName,
      );
    } catch (e) {
      log('PrayerWidgetUpdater failed: $e');
    }
  }
}
