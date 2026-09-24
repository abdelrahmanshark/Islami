import 'dart:developer';

import 'package:http/http.dart';

/// Fetches prayer times from the Aladhan API.
class TimeRemoteDataSource {
  static const String _baseUrl = 'https://api.aladhan.com';

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

  /// Returns the raw API JSON body on success.
  Future<String> fetchTimeResponseJson({
    required double latitude,
    required double longitude,
  }) async {
    final String timingsPath = buildTimingsPath(
      latitude: latitude,
      longitude: longitude,
    );
    return _getJson(timingsPath);
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
    return _getJson(calendarPath);
  }

  /// Formats [date] as DD-MM-YYYY, the date format used by Aladhan.
  String _formatApiDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  /// Sends a GET request to [path] and returns the body on success.
  Future<String> _getJson(String path) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
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
