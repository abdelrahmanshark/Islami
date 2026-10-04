import 'package:islami/ui/home/tabs/time_screen/models/time_response.dart';

/// Contract for loading prayer times.
abstract class TimeRepository {
  Future<TimeResponse> getTimeResponse();

  /// Prayer times for today and the following days (for Adhan alarms).
  Future<List<PrayerData>> getUpcomingPrayerDays({
    required int days,
    bool forceRefresh = false,
  });
}
