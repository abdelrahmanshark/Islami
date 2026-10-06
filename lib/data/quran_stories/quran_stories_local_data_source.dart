import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads Quran stories from the local JSON asset.
@lazySingleton
class QuranStoriesLocalDataSource {
  /// Reads and parses quran_storys.json into lists of sections and lectures.
  Future<QuranStories> fetchQuranStories() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.quranStoriesJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return QuranStories.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
