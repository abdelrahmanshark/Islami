import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/jews_in_quran.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads Jews in Quran lectures from the local JSON asset.
class JewsInQuranLocalDataSource {
  /// Reads and parses jews_in_quran.json into lists of sections and lectures.
  Future<JewsInQuran> fetchJewsInQuran() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.jewsInQuranJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return JewsInQuran.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
