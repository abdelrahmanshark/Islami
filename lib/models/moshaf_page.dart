import 'package:islami/models/moshaf_page_marker.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/utils/app_assets.dart';

/// One Mushaf page: metadata + image path for the page image.
class MoshafPage {
  final int pageNumber;
  final int sura;
  final int aya;
  final int juz;
  final int hizb;
  final int rub;
  final String imagePath;

  /// All Surah numbers that appear on this page (ordered, 1-based).
  final List<int> suraNumbers;

  const MoshafPage({
    required this.pageNumber,
    required this.sura,
    required this.aya,
    required this.juz,
    required this.hizb,
    required this.rub,
    required this.imagePath,
    required this.suraNumbers,
  });

  /// Builds a page from JSON metadata and the matching Quran image asset.
  factory MoshafPage.fromMarker(
    MoshafPageMarker marker, {
    List<int>? suraNumbers,
  }) {
    return MoshafPage(
      pageNumber: marker.page,
      sura: marker.sura,
      aya: marker.aya,
      juz: marker.juz,
      hizb: marker.hizb,
      rub: marker.rub,
      imagePath: AppAssets.quranPageImage(marker.page),
      suraNumbers: suraNumbers ?? [marker.sura],
    );
  }

  /// Builds all pages and fills each with every Surah that appears on it.
  static List<MoshafPage> fromMarkers(List<MoshafPageMarker> markers) {
    return List<MoshafPage>.generate(markers.length, (index) {
      return MoshafPage.fromMarker(
        markers[index],
        suraNumbers: suraNumbersForPage(markers, index),
      );
    });
  }

  /// Surah numbers on the page at [index], including partial Surahs.
  static List<int> suraNumbersForPage(
    List<MoshafPageMarker> markers,
    int index,
  ) {
    final start = markers[index].sura;

    // Last page: from its first Surah through سورة الناس.
    if (index + 1 >= markers.length) {
      return [for (var s = start; s <= 114; s++) s];
    }

    final next = markers[index + 1];
    // If the next page starts mid-Surah, that Surah is still on this page.
    final end = next.aya > 1 ? next.sura : next.sura - 1;
    if (end < start) return [start];
    return [for (var s = start; s <= end; s++) s];
  }

  /// Arabic Surah name for the first Surah on this page.
  String get suraName => _suraName(sura);

  /// Arabic names for every Surah on this page.
  List<String> get suraNames {
    return suraNumbers
        .map(_suraName)
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// AppBar title: all Surah names on the page, joined when there are several.
  String get appBarTitle {
    final names = suraNames;
    if (names.isEmpty) return 'المصحف';
    return names.join(' • ');
  }

  /// Bottom footer text: juz, hizb, and rub for this page.
  String get pageFooterMarkers {
    return 'الجزء $juz • الحزب $hizb • الربع $rub';
  }

  /// Arabic Surah name for a 1-based Surah number.
  static String _suraName(int suraNumber) {
    if (suraNumber < 1 ||
        suraNumber > QuranResources.arabicQuranSuras.length) {
      return '';
    }
    return QuranResources.arabicQuranSuras[suraNumber - 1];
  }
}
