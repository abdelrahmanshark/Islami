import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads azkar from the local JSON asset.
class AzkarLocalDataSource {
  /// Reads and parses assets/json/azkar.json.
  Future<AzkarResponse> fetchAzkar() async {
    try {
      final jsonString = await rootBundle.loadString(AppAssets.azkarJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AzkarResponse.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
