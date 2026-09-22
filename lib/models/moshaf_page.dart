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

  const MoshafPage({
    required this.pageNumber,
    required this.sura,
    required this.aya,
    required this.juz,
    required this.hizb,
    required this.rub,
    required this.imagePath,
  });

  /// Builds a page from JSON metadata and the matching Quran image asset.
  factory MoshafPage.fromMarker(MoshafPageMarker marker) {
    return MoshafPage(
      pageNumber: marker.page,
      sura: marker.sura,
      aya: marker.aya,
      juz: marker.juz,
      hizb: marker.hizb,
      rub: marker.rub,
      imagePath: AppAssets.quranPageImage(marker.page),
    );
  }

  /// Arabic Surah name for this page.
  String get suraName {
    if (sura < 1 || sura > QuranResources.arabicQuranSuras.length) {
      return '';
    }
    return QuranResources.arabicQuranSuras[sura - 1];
  }

  /// AppBar title for the currently visible page (sura name only).
  String get appBarTitle {
    return suraName.isEmpty ? 'المصحف' : suraName;
  }

  /// Bottom footer text: juz, hizb, and rub for this page.
  String get pageFooterMarkers {
    return 'الجزء $juz • الحزب $hizb • الربع $rub';
  }
}
