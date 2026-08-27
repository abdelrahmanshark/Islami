/*
https://mp3quran.net/api/v3/radios?language=ar
*/

import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/RadioResponce.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/RecitersResponse.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';

abstract class ApiManger {
  static const String baseUrl = 'https://mp3quran.net';
  static const String timesUrl = 'https://api.aladhan.com';
  static const String radioEndPoint = '/api/v3/radios?language=ar';
  static const String recitersEndPoint = '/api/v3/reciters?language=ar';
  static const String timeEndpoint =
      '/v1/timingsByCity?city=cairo&country=egypt';

  /*/v1/timingsByCity?city=cairo&country=egypt*/
  static Future<RadioResponse> getRadioResponse() async {
    try {
      Uri uri = Uri.parse(baseUrl + radioEndPoint);
      var response = await get(uri);
      return RadioResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  static Future<RecitersResponse> getRecitersResponse() async {
    try {
      Uri uri = Uri.parse(baseUrl + recitersEndPoint);
      var response = await get(uri);
      return RecitersResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

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
