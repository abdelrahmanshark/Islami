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

  /// Returns the raw API JSON body on success.
  Future<String> fetchTimeResponseJson({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final String timingsPath = buildTimingsPath(
        latitude: latitude,
        longitude: longitude,
      );
      final uri = Uri.parse('$_baseUrl$timingsPath');
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
