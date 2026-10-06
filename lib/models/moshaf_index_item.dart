/// Index row kind: Surah, Juz, Hizb, or Rub.
enum MoshafIndexItemType { surah, juz, hizb, rub }

/// One row in the Mushaf index (Surah / Juz / Hizb / Rub).
class MoshafIndexItem {
  final String title;
  final int pageNumber;
  final MoshafIndexItemType type;

  /// Surah/Juz/Hizb number, or global Rub number (1–240) for a Rub.
  final String id;

  const MoshafIndexItem({
    required this.title,
    required this.pageNumber,
    required this.type,
    required this.id,
  });
}
