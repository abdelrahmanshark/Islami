import 'package:islami/models/hafs_ayah_meta.dart';
import 'package:islami/models/moshaf_index_item.dart';
import 'package:islami/models/moshaf_memorization_tracker.dart';
import 'package:islami/models/quran_resources.dart';

/// Builds Mushaf index lists and memorization maps from ayah metadata.
class MoshafIndexData {
  final List<MoshafIndexItem> surahItems;
  final List<MoshafIndexItem> juzItems;
  final List<MoshafIndexItem> hizbItems;
  final List<MoshafIndexItem> rubItems;
  final MoshafMemorizationTracker memorizationTracker;

  const MoshafIndexData({
    required this.surahItems,
    required this.juzItems,
    required this.hizbItems,
    required this.rubItems,
    required this.memorizationTracker,
  });

  /// Derives all index divisions from [ayahs] (hafs-ayah-meta.json).
  factory MoshafIndexData.fromAyahs(List<HafsAyahMeta> ayahs) {
    final surahItems = <MoshafIndexItem>[];
    final juzItems = <MoshafIndexItem>[];
    final hizbItems = <MoshafIndexItem>[];
    final rubItems = <MoshafIndexItem>[];

    final surahAyahs = <int, Set<int>>{};
    final juzAyahs = <int, Set<int>>{};
    final hizbAyahs = <int, Set<int>>{};
    final rubAyahs = <int, Set<int>>{};

    final seenSurahs = <int>{};
    final seenJuz = <int>{};
    final seenHizb = <int>{};
    final seenRub = <int>{};

    for (final ayah in ayahs) {
      surahAyahs.putIfAbsent(ayah.sura, () => <int>{}).add(ayah.id);
      juzAyahs.putIfAbsent(ayah.juz, () => <int>{}).add(ayah.id);
      hizbAyahs.putIfAbsent(ayah.hizb, () => <int>{}).add(ayah.id);
      rubAyahs.putIfAbsent(ayah.rub, () => <int>{}).add(ayah.id);

      // First ayah of each division becomes the index row (start page).
      if (seenSurahs.add(ayah.sura)) {
        surahItems.add(
          MoshafIndexItem(
            title: _surahName(ayah.sura),
            pageNumber: ayah.page,
            type: MoshafIndexItemType.surah,
            id: ayah.sura.toString(),
          ),
        );
      }

      if (seenJuz.add(ayah.juz)) {
        juzItems.add(
          MoshafIndexItem(
            title: 'الجزء ${ayah.juz}',
            pageNumber: ayah.page,
            type: MoshafIndexItemType.juz,
            id: ayah.juz.toString(),
          ),
        );
      }

      if (seenHizb.add(ayah.hizb)) {
        hizbItems.add(
          MoshafIndexItem(
            title: 'الحزب ${ayah.hizb}',
            pageNumber: ayah.page,
            type: MoshafIndexItemType.hizb,
            id: ayah.hizb.toString(),
          ),
        );
      }

      if (seenRub.add(ayah.rub)) {
        rubItems.add(
          MoshafIndexItem(
            title: 'الحزب ${ayah.hizb} • الربع ${ayah.rub}',
            pageNumber: ayah.page,
            type: MoshafIndexItemType.rub,
            id: ayah.rub.toString(),
          ),
        );
      }
    }

    return MoshafIndexData(
      surahItems: surahItems,
      juzItems: juzItems,
      hizbItems: hizbItems,
      rubItems: rubItems,
      memorizationTracker: MoshafMemorizationTracker(
        surahAyahs: surahAyahs,
        juzAyahs: juzAyahs,
        hizbAyahs: hizbAyahs,
        rubAyahs: rubAyahs,
      ),
    );
  }

  /// Arabic Surah name for a 1-based Surah number.
  static String _surahName(int sura) {
    if (sura < 1 || sura > QuranResources.arabicQuranSuras.length) {
      return '';
    }
    return QuranResources.arabicQuranSuras[sura - 1];
  }
}
