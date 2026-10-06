import 'package:islami/models/moshaf_index_item.dart';

/// Tracks Mushaf memorization using ayah coverage from hafs-ayah-meta.json.
///
/// Completed ayah IDs are the source of truth. An index item is complete only
/// when every ayah that belongs to it is completed.
class MoshafMemorizationTracker {
  MoshafMemorizationTracker({
    required this.surahAyahs,
    required this.juzAyahs,
    required this.hizbAyahs,
    required this.rubAyahs,
    Set<int> completedAyahs = const {},
  }) : completedAyahs = Set<int>.from(completedAyahs);

  final Map<int, Set<int>> surahAyahs;
  final Map<int, Set<int>> juzAyahs;
  final Map<int, Set<int>> hizbAyahs;

  /// Key is the global rub number from metadata (1–240).
  final Map<int, Set<int>> rubAyahs;

  /// Ayahs the user has marked complete (directly or via a parent/child item).
  final Set<int> completedAyahs;

  /// Replaces the in-memory completed ayah set (e.g. after loading prefs).
  void setCompletedAyahs(Set<int> ayahs) {
    completedAyahs
      ..clear()
      ..addAll(ayahs);
  }

  /// Ayah IDs that belong to this index item.
  Set<int> ayahsFor(MoshafIndexItem item) {
    switch (item.type) {
      case MoshafIndexItemType.surah:
        return surahAyahs[int.parse(item.id)] ?? const {};
      case MoshafIndexItemType.juz:
        return juzAyahs[int.parse(item.id)] ?? const {};
      case MoshafIndexItemType.hizb:
        return hizbAyahs[int.parse(item.id)] ?? const {};
      case MoshafIndexItemType.rub:
        return rubAyahs[int.parse(item.id)] ?? const {};
    }
  }

  /// True when every ayah of [item] is completed.
  bool isCompleted(MoshafIndexItem item) {
    final ayahs = ayahsFor(item);
    if (ayahs.isEmpty) return false;
    for (final ayahId in ayahs) {
      if (!completedAyahs.contains(ayahId)) return false;
    }
    return true;
  }

  /// Marks or unmarks all ayahs of [item], then returns the updated ayah set.
  Set<int> toggle(MoshafIndexItem item) {
    final ayahs = ayahsFor(item);
    if (ayahs.isEmpty) return Set<int>.from(completedAyahs);

    if (isCompleted(item)) {
      completedAyahs.removeAll(ayahs);
    } else {
      completedAyahs.addAll(ayahs);
    }

    return Set<int>.from(completedAyahs);
  }
}
