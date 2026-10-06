import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/models/asbab_nuzul.dart';
import 'package:islami/models/ayah_coordinate.dart';
import 'package:islami/models/hafs_ayah_meta.dart';
import 'package:islami/models/moshaf_page_marker.dart';
import 'package:islami/models/tafser_surah.dart';
import 'package:islami/utils/app_assets.dart';

/// Loads Mushaf data (page markers, ayah polygons, tafsir, asbab, ayah meta)
/// from the local JSON assets.
@lazySingleton
class MoshafLocalDataSource {
  /// Reads page metadata from quran_with_juz_hizb_rub.json.
  Future<List<MoshafPageMarker>> fetchPageMarkers() async {
    final raw = await rootBundle.loadString(AppAssets.quranWithJuzHizbRubJson);
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MoshafPageMarker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Reads the ayah polygons of Quran page [pageNumber] (1–604).
  Future<List<AyahCoordinate>> fetchPageCoordinates(int pageNumber) async {
    final raw = await rootBundle.loadString(_pageCoordinatesPath(pageNumber));
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => AyahCoordinate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Reads the full tafsir file of [surahNumber] (1–114).
  Future<TafserSurah> fetchTafserSurah(int surahNumber) async {
    final raw = await rootBundle.loadString(_tafserSurahPath(surahNumber));
    return TafserSurah.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Reads asbab.json into a "surah:ayah" → reasons map.
  Future<Map<String, List<AsbabReason>>> fetchAsbabIndex() async {
    final raw = await rootBundle.loadString(AppAssets.asbabJson);
    // compute() parses the large file in a background isolate,
    // so the Mushaf page does not freeze while it loads.
    return compute(_buildAsbabIndex, raw);
  }

  /// Reads the ayah metadata used by the Mushaf index.
  Future<List<HafsAyahMeta>> fetchAyahMeta() async {
    final raw = await rootBundle.loadString(AppAssets.hafsAyahMetaJson);
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => HafsAyahMeta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the ayah-polygon JSON path for Quran page [pageNumber] (1–604).
  String _pageCoordinatesPath(int pageNumber) {
    final padded = pageNumber.toString().padLeft(3, '0');
    return '${AppAssets.quranCoordinatesFolder}/$padded.json';
  }

  /// Returns the tafsir JSON path for [surahNumber] (1–114).
  String _tafserSurahPath(int surahNumber) {
    return '${AppAssets.tafserFolder}/'
        '${AppAssets.tafserFileNames[surahNumber - 1]}';
  }

  /// Parses asbab.json into a "surah:ayah" → reasons map.
  /// Static so it can run inside compute().
  static Map<String, List<AsbabReason>> _buildAsbabIndex(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    final Map<String, List<AsbabReason>> index = {};

    for (final item in list) {
      final entry = AsbabEntry.fromJson(item as Map<String, dynamic>);
      for (final ayahNumber in entry.ayahs) {
        final key = AsbabEntry.ayahKey(entry.surah, ayahNumber);
        final reasons = index.putIfAbsent(key, () => []);
        for (final reason in entry.reasons) {
          // Keep الواحدي first so the source tabs always have the same order.
          if (reason.source == AsbabReason.wahidiSource) {
            reasons.insert(0, reason);
          } else {
            reasons.add(reason);
          }
        }
      }
    }
    return index;
  }
}
