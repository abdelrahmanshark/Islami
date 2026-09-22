import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/pillars_of_islam.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads pillars of Islam lectures from the local JSON asset.
class PillarsOfIslamLocalDataSource {
  /// Reads and parses pillars_of_islam.json into lists of sections and lectures.
  Future<PillarsOfIslam> fetchPillarsOfIslam() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.pillarsOfIslamJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return PillarsOfIslam.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
