import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';

/// Result of finding the next salah and when it occurs.
class NextPrayerResult {
  NextPrayerResult({
    required this.prayer,
    required this.index,
    required this.dateTime,
  });

  final Prayer prayer;
  final int index;
  final DateTime dateTime;

  /// Remaining duration until [dateTime] from [now].
  Duration remainingFrom(DateTime now) => dateTime.difference(now);
}

/// Shared next-prayer logic for the Time screen and home widget.
class NextPrayerCalculator {
  NextPrayerCalculator._();

  static const List<String> salahNames = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  /// Finds the next salah from [prayerTimes], or Fajr tomorrow after Isha.
  static NextPrayerResult? findNext(List<Prayer> prayerTimes, DateTime now) {
    if (prayerTimes.isEmpty) {
      return null;
    }

    Prayer? foundPrayer;
    int foundIndex = -1;
    DateTime? foundDateTime;

    // Find the first salah that is still ahead today
    for (int i = 0; i < prayerTimes.length; i++) {
      Prayer prayer = prayerTimes[i];

      if (!salahNames.contains(prayer.PryerName)) {
        continue;
      }

      DateTime? prayerDateTime = toTodayDateTime(prayer.PryerTime, now);
      if (prayerDateTime == null) {
        continue;
      }

      if (prayerDateTime.isAfter(now)) {
        foundPrayer = prayer;
        foundIndex = i;
        foundDateTime = prayerDateTime;
        break;
      }
    }

    // If no upcoming salah today, next is Fajr tomorrow
    if (foundPrayer == null) {
      for (int i = 0; i < prayerTimes.length; i++) {
        Prayer prayer = prayerTimes[i];

        if (prayer.PryerName != 'الفجر') {
          continue;
        }

        DateTime? fajrTime = toTodayDateTime(prayer.PryerTime, now);
        if (fajrTime == null) {
          break;
        }

        foundPrayer = prayer;
        foundIndex = i;
        foundDateTime = fajrTime.add(const Duration(days: 1));
        break;
      }
    }

    if (foundPrayer == null || foundDateTime == null) {
      return null;
    }

    return NextPrayerResult(
      prayer: foundPrayer,
      index: foundIndex,
      dateTime: foundDateTime,
    );
  }

  /// Removes timezone suffix and converts the time to 12-hour format.
  static String cleanTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) {
      return '';
    }

    String time = rawTime.split(' ').first.trim();
    List<String> parts = time.split(':');
    if (parts.length < 2) {
      return time;
    }

    int? hour = int.tryParse(parts[0]);
    int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return time;
    }

    String period = hour >= 12 ? 'م' : 'ص';
    int hour12 = hour % 12;
    if (hour12 == 0) {
      hour12 = 12;
    }

    String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  /// Parses "h:mm ص/م" (or AM/PM) into a DateTime for today.
  static DateTime? toTodayDateTime(String time, DateTime now) {
    List<String> parts = time.split(' ');
    if (parts.isEmpty) {
      return null;
    }

    List<String> timeParts = parts[0].split(':');
    if (timeParts.length < 2) {
      return null;
    }

    int? hour = int.tryParse(timeParts[0]);
    int? minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    // Convert 12-hour time to 24-hour for DateTime
    if (parts.length >= 2) {
      String period = parts[1].toUpperCase();
      bool isAm = period == 'AM' || period == 'ص';
      bool isPm = period == 'PM' || period == 'م';
      if (isAm && hour == 12) {
        hour = 0;
      } else if (isPm && hour != 12) {
        hour = hour + 12;
      }
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Formats remaining time as HH:MM:SS.
  static String formatRemainingHms(Duration remaining) {
    String hours = remaining.inHours.toString().padLeft(2, '0');
    String minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Formats remaining time as HH:MM (for the home widget).
  static String formatRemainingHm(Duration remaining) {
    if (remaining.isNegative) {
      return '00:00';
    }
    String hours = remaining.inHours.toString().padLeft(2, '0');
    String minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
