import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';

/// Fetches prayer times from the Aladhan API
/// (and temporarily from eSalah for Saudi Arabia).
class TimeRemoteDataSource {
  static const String _baseUrl = 'https://api.aladhan.com';
  static const String _eSalahBaseUrl = 'https://esalah.com';

  /// Builds the timings path using the user's GPS coordinates.
  String buildTimingsPath({
    required double latitude,
    required double longitude,
  }) {
    return '/v1/timings?latitude=$latitude&longitude=$longitude';
  }

  /// Builds the calendar path for every day from [from] to [to] (inclusive).
  String buildCalendarRangePath({
    required double latitude,
    required double longitude,
    required DateTime from,
    required DateTime to,
  }) {
    return '/v1/calendar/from/${_formatApiDate(from)}/to/${_formatApiDate(to)}'
        '?latitude=$latitude&longitude=$longitude';
  }

  /// Builds the eSalah Umm al-Qura path for one [date] in Saudi Arabia.
  String buildSaudiTimesPath({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    return '/api/v1/times?lat=$latitude&lng=$longitude'
        '&method=umm-al-qura&date=${_formatIsoDate(date)}'
        '&timezone=Asia%2FRiyadh';
  }

  /// Returns the raw API JSON body on success.
  Future<String> fetchTimeResponseJson({
    required double latitude,
    required double longitude,
  }) async {
    final String timingsPath = buildTimingsPath(
      latitude: latitude,
      longitude: longitude,
    );
    return _getJson('$_baseUrl$timingsPath');
  }

  /// Returns the raw calendar JSON (a list of days) for the date range.
  Future<String> fetchCalendarRangeJson({
    required double latitude,
    required double longitude,
    required DateTime from,
    required DateTime to,
  }) async {
    final String calendarPath = buildCalendarRangePath(
      latitude: latitude,
      longitude: longitude,
      from: from,
      to: to,
    );
    return _getJson('$_baseUrl$calendarPath');
  }

  /// Returns eSalah's "times" map for [date]. Its keys ("Fajr", "Dhuhr", ...)
  /// match Aladhan's "timings", so it can replace them directly.
  Future<Map<String, dynamic>> fetchSaudiTimings({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    final String timesPath = buildSaudiTimesPath(
      latitude: latitude,
      longitude: longitude,
      date: date,
    );
    final String body = await _getJson('$_eSalahBaseUrl$timesPath');
    final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
    final Map<String, dynamic>? times = json['times'] as Map<String, dynamic>?;
    if (times == null) {
      throw const FormatException('eSalah response has no times');
    }
    return times;
  }

  /// Formats [date] as DD-MM-YYYY, the date format used by Aladhan.
  String _formatApiDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  /// Formats [date] as YYYY-MM-DD, the date format used by eSalah.
  String _formatIsoDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Sends a GET request to [url] and returns the body on success.
  Future<String> _getJson(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await get(uri);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Prayer times request failed: ${response.statusCode}');
      }

      return response.body;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
