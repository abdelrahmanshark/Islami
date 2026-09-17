import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/radio_response.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/reciters_response.dart';

class RadioRemoteDataSource {
  static const String _baseUrl = 'https://mp3quran.net';
  static const String _radiosPath = '/api/v3/radios?language=ar';
  static const String _recitersPath = '/api/v3/reciters?language=ar';

  Future<RadioResponse> fetchRadios() async {
    try {
      final uri = Uri.parse('$_baseUrl$_radiosPath');
      final response = await get(uri);
      return RadioResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<RecitersResponse> fetchReciters() async {
    try {
      final uri = Uri.parse('$_baseUrl$_recitersPath');
      final response = await get(uri);
      return RecitersResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
