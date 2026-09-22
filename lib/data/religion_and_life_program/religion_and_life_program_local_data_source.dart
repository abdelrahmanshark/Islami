import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/religion_and_life_program.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads religion and life program lectures from the local JSON asset.
class ReligionAndLifeProgramLocalDataSource {
  /// Reads and parses religion_and_life_program.json into sections and lectures.
  Future<ReligionAndLifeProgram> fetchReligionAndLifeProgram() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppAssets.religionAndLifeProgramJson);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return ReligionAndLifeProgram.fromJson(jsonMap);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
