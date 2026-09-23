import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:islami/models/mshary_sura.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads مشاري راشد العفاسي from the local JSON asset.
class MsharyLocalDataSource {
  /// Stable local id so downloads stay linked across app restarts.
  static const int localReciterId = 1008008;

  /// Old API name that must be removed from the reciters list.
  static const String oldApiReciterName = 'مشاري العفاسي';

  /// Fallback display name if JSON category is missing.
  static const String displayName = 'مشاري راشد العفاسي';

  /// Builds a [Reciters] entry from mshary.json (name + audio server).
  Future<Reciters> loadReciter() async {
    try {
      final String jsonString =
          await rootBundle.loadString(AppAssets.msharyJson);
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      if (list.isEmpty) {
        throw StateError('mshary.json is empty');
      }

      final MsharySura first =
          MsharySura.fromJson(list.first as Map<String, dynamic>);
      final String server = _serverFromMp3(first.mp3);
      final String name =
          first.category.trim().isNotEmpty ? first.category.trim() : displayName;

      return Reciters(
        id: localReciterId,
        name: name,
        server: server,
      );
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  /// Turns a full mp3 URL into the server base used by playback.
  String _serverFromMp3(String mp3Url) {
    final int slashIndex = mp3Url.lastIndexOf('/');
    if (slashIndex < 0) return mp3Url;
    return mp3Url.substring(0, slashIndex + 1);
  }
}
