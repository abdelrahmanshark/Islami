import 'dart:developer';

import 'package:http/http.dart';

/// Fetches prayer times from the Aladhan API.
class TimeRemoteDataSource {
  static const String _baseUrl = 'https://api.aladhan.com';
  static const String _timingsPath =
      '/v1/timingsByCity?city=cairo&country=egypt';

  /// Returns the raw API JSON body on success.
  Future<String> fetchTimeResponseJson() async {
    try {
      final uri = Uri.parse('$_baseUrl$_timingsPath');
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
