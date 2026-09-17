import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';

abstract class ApiManger {
  static const String timesUrl = 'https://api.aladhan.com';
  static const String timeEndpoint =
      '/v1/timingsByCity?city=cairo&country=egypt';

  static Future<TimeResponse> getTimeResponse() async {
    try {
      Uri uri = Uri.parse(timesUrl + timeEndpoint);
      var response = await get(uri);
      return TimeResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
