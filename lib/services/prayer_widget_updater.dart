import 'dart:developer';

import 'package:home_widget/home_widget.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/models/prayer.dart';
import 'package:islami/utils/next_prayer_calculator.dart';

/// Pushes prayer times to the Android home screen widget.
@lazySingleton
class PrayerWidgetUpdater {
  static const String androidWidgetName = 'PrayerTimesWidgetProvider';
  static const String qualifiedAndroidName =
      'com.example.islami.PrayerTimesWidgetProvider';

  /// Saves salah times and the next prayer's actual DateTime, then refreshes.
  Future<void> update({
    required List<Prayer> prayerTimes,
    required NextPrayerResult? nextResult,
  }) async {
    try {
      final Map<String, String> salahTimes = {};
      for (final Prayer prayer in prayerTimes) {
        if (NextPrayerCalculator.salahNames.contains(prayer.pryerName)) {
          salahTimes[prayer.pryerName] = prayer.pryerTime;
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
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_name',
          nextResult.prayer.pryerName,
        );
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          nextResult.prayer.pryerTime,
        );
        // Actual next-prayer DateTime; Android counts down from this alone.
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_epoch_ms',
          nextResult.dateTime.millisecondsSinceEpoch.toString(),
        );
      } else {
        await HomeWidget.saveWidgetData<String>('next_prayer_name', '');
        await HomeWidget.saveWidgetData<String>('next_prayer_time', '');
        await HomeWidget.saveWidgetData<String>('next_prayer_epoch_ms', '');
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
