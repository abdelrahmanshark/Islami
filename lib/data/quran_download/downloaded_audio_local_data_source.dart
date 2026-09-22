import 'dart:convert';

import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/utils/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists downloaded Quran audio metadata in SharedPreferences.
class DownloadedAudioLocalDataSource {
  /// Returns all saved download metadata entries.
  Future<List<DownloadedAudio>> loadAll() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    final String? raw =
        pref.getString(SharedPreferencesKay.downloadedQuranAudio);

    if (raw == null || raw.isEmpty) {
      return <DownloadedAudio>[];
    }

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) =>
                DownloadedAudio.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return <DownloadedAudio>[];
    }
  }

  /// Replaces the full metadata list.
  Future<void> saveAll(List<DownloadedAudio> items) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    final String raw = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );
    await pref.setString(SharedPreferencesKay.downloadedQuranAudio, raw);
  }

  /// Upserts one entry keyed by reciter + sura.
  Future<void> upsert(DownloadedAudio audio) async {
    final List<DownloadedAudio> items = await loadAll();
    final int index = items.indexWhere(
      (item) =>
          item.suraId == audio.suraId && item.reciterId == audio.reciterId,
    );

    if (index >= 0) {
      items[index] = audio;
    } else {
      items.add(audio);
    }

    await saveAll(items);
  }

  /// Removes metadata for the given reciter + sura when present.
  Future<void> remove({
    required int suraId,
    required int reciterId,
  }) async {
    final List<DownloadedAudio> items = await loadAll();
    items.removeWhere(
      (item) => item.suraId == suraId && item.reciterId == reciterId,
    );
    await saveAll(items);
  }
}
