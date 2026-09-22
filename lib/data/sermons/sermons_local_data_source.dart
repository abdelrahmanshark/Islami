import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/sermon.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads sermons from the local JSON asset.
class SermonsLocalDataSource {
  /// Reads and parses assets/data/sermons.json into a list.
  Future<List<Sermon>> fetchSermons() async {
    try {
      final jsonString = await rootBundle.loadString(AppAssets.sermonsJson);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => Sermon.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
