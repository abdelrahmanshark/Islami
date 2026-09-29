import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/riyad_assalihin.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads Riyad Assalihin from the local JSON asset.
class RiyadAssalihinLocalDataSource {
  /// Reads and parses assets/json/riyad_assalihin.json.
  Future<RiyadAssalihinModel> fetchRiyadAssalihin() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.riyadAssalihinJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return RiyadAssalihinModel.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
