import 'package:islami/models/moshaf_index_item.dart';
import 'package:islami/models/moshaf_page.dart';

/// Tracks Mushaf memorization using page coverage from Quran metadata.
///
/// Completed pages are the source of truth. An index item is complete only when
/// every page that belongs to it is completed.
class MoshafMemorizationTracker {
  MoshafMemorizationTracker._({
    required this.surahPages,
    required this.juzPages,
    required this.hizbPages,
    required this.rubPages,
    required Set<int> completedPages,
  }) : completedPages = Set<int>.from(completedPages);

  final Map<int, Set<int>> surahPages;
  final Map<int, Set<int>> juzPages;
  final Map<int, Set<int>> hizbPages;

  /// Key format: `"hizb-rub"` (same as the index Rub id).
  final Map<String, Set<int>> rubPages;

  /// Pages the user has marked complete (directly or via a parent/child item).
  final Set<int> completedPages;

  /// Builds page maps for Surah / Juz / Hizb / Rub from Mushaf metadata.
  factory MoshafMemorizationTracker.fromPages(
    List<MoshafPage> pages, {
    Set<int> completedPages = const {},
  }) {
    final surahPages = <int, Set<int>>{};
    final juzPages = <int, Set<int>>{};
    final hizbPages = <int, Set<int>>{};
    final rubPages = <String, Set<int>>{};

    for (final page in pages) {
      surahPages.putIfAbsent(page.sura, () => <int>{}).add(page.pageNumber);
      juzPages.putIfAbsent(page.juz, () => <int>{}).add(page.pageNumber);
      hizbPages.putIfAbsent(page.hizb, () => <int>{}).add(page.pageNumber);
      final rubKey = '${page.hizb}-${page.rub}';
      rubPages.putIfAbsent(rubKey, () => <int>{}).add(page.pageNumber);
    }

    return MoshafMemorizationTracker._(
      surahPages: surahPages,
      juzPages: juzPages,
      hizbPages: hizbPages,
      rubPages: rubPages,
      completedPages: completedPages,
    );
  }

  /// Replaces the in-memory completed page set (e.g. after loading prefs).
  void setCompletedPages(Set<int> pages) {
    completedPages
      ..clear()
      ..addAll(pages);
  }

  /// Pages that belong to this index item.
  Set<int> pagesFor(MoshafIndexItem item) {
    switch (item.type) {
      case MoshafIndexItemType.surah:
        return surahPages[int.parse(item.id)] ?? const {};
      case MoshafIndexItemType.juz:
        return juzPages[int.parse(item.id)] ?? const {};
      case MoshafIndexItemType.hizb:
        return hizbPages[int.parse(item.id)] ?? const {};
      case MoshafIndexItemType.rub:
        return rubPages[item.id] ?? const {};
    }
  }

  /// True when every page of [item] is completed.
  bool isCompleted(MoshafIndexItem item) {
    final pages = pagesFor(item);
    if (pages.isEmpty) return false;
    for (final page in pages) {
      if (!completedPages.contains(page)) return false;
    }
    return true;
  }

  /// Marks or unmarks all pages of [item], then returns the updated page set.
  Set<int> toggle(MoshafIndexItem item) {
    final pages = pagesFor(item);
    if (pages.isEmpty) return Set<int>.from(completedPages);

    if (isCompleted(item)) {
      completedPages.removeAll(pages);
    } else {
      completedPages.addAll(pages);
    }

    return Set<int>.from(completedPages);
  }
}
