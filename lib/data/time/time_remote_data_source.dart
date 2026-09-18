import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';

/// Fetches prayer times from the Aladhan API.
class TimeRemoteDataSource {
  static const String _baseUrl = 'https://api.aladhan.com';
  static const String _timingsPath =
      '/v1/timingsByCity?city=cairo&country=egypt';

  Future<TimeResponse> fetchTimeResponse() async {
    try {
      final uri = Uri.parse('$_baseUrl$_timingsPath');
      final response = await get(uri);
      return TimeResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
