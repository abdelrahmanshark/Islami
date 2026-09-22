/// Index row kind: Surah, Juz, Hizb, or Rub.
enum MoshafIndexItemType { surah, juz, hizb, rub }

/// One row in the Mushaf index (Surah / Juz / Hizb / Rub).
class MoshafIndexItem {
  final String title;
  final int pageNumber;
  final MoshafIndexItemType type;

  /// Surah/Juz/Hizb number, or `"hizb-rub"` for a Rub (e.g. `"2-5"`).
  final String id;

  const MoshafIndexItem({
    required this.title,
    required this.pageNumber,
    required this.type,
    required this.id,
  });
}
