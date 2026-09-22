import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/sharawy_lectures.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads Sharawy lectures and sermons from the local JSON asset.
class SharawyLecturesLocalDataSource {
  /// Reads and parses sharawy_lectures.json into lists of sections and lectures.
  Future<SharawyLectures> fetchSharawyLectures() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.sharawyLecturesJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return SharawyLectures.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
