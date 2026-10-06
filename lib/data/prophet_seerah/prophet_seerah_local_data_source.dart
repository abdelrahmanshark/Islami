import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/models/prophet_seerah.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads prophet seerah from the local JSON asset.
@lazySingleton
class ProphetSeerahLocalDataSource {
  /// Reads and parses prophet_mohamed.json into lists of sections and lectures.
  Future<ProphetSeerah> fetchProphetSeerah() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.prophetSeerahJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return ProphetSeerah.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
