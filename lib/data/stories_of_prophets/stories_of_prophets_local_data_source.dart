import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/models/stories_of_prophets.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads stories of the prophets from the local JSON asset.
@lazySingleton
class StoriesOfProphetsLocalDataSource {
  /// Reads and parses storys_of_phrophets.json into sections and lectures.
  Future<StoriesOfProphets> fetchStoriesOfProphets() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.storiesOfProphetsJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return StoriesOfProphets.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
