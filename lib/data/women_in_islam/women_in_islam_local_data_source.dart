import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/women_in_islam.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads women in Islam lectures from the local JSON asset.
class WomenInIslamLocalDataSource {
  /// Reads and parses wemen_in_islam.json into lists of sections and lectures.
  Future<WomenInIslam> fetchWomenInIslam() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.womenInIslamJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return WomenInIslam.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
