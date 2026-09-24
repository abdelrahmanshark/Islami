import 'dart:convert';

import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches the last successful prayer-times API response locally.
class TimeLocalDataSource {
  /// Saves the raw API JSON so it can be used offline later.
  Future<void> saveRawJson(String rawJson) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(SharedPreferencesKay.cachedTimeResponse, rawJson);
  }

  /// Saves the raw multi-day calendar JSON used for Adhan scheduling.
  Future<void> saveUpcomingRawJson(String rawJson) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(
      SharedPreferencesKay.cachedUpcomingPrayerDays,
      rawJson,
    );
  }

  /// Returns the cached calendar JSON, or null if nothing was saved yet.
  Future<String?> loadUpcomingRawJson() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(SharedPreferencesKay.cachedUpcomingPrayerDays);
  }

  /// Returns the cached response, or null if nothing was saved yet.
  Future<TimeResponse?> loadCachedResponse() async {
    final pref = await SharedPreferences.getInstance();
    final String? rawJson =
        pref.getString(SharedPreferencesKay.cachedTimeResponse);

    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }

    try {
      return TimeResponse.fromJson(
        jsonDecode(rawJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
