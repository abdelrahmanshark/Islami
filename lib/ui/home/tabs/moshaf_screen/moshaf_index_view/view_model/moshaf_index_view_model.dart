import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_index_item.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/utils/arabic_utils.dart';

class MoshafIndexViewModel extends ChangeNotifier {
  final List<MoshafPage> pages;

  late final List<MoshafIndexItem> surahItems;
  late final List<MoshafIndexItem> juzItems;
  late final List<MoshafIndexItem> hizbItems;
  late final List<MoshafIndexItem> rubItems;

  int selectedTabIndex = 0;
  String surahSearchQuery = '';

  MoshafIndexViewModel({required this.pages}) {
    surahItems = _buildSurahIndex();
    juzItems = _buildNumberIndex(label: 'الجزء', valueOf: (page) => page.juz);
    hizbItems = _buildNumberIndex(label: 'الحزب', valueOf: (page) => page.hizb);
    rubItems = _buildRubIndex();
  }

  /// Items for the currently selected index tab.
  List<MoshafIndexItem> get currentItems {
    switch (selectedTabIndex) {
      case 1:
        return juzItems;
      case 2:
        return hizbItems;
      case 3:
        return rubItems;
      case 0:
      default:
        return filteredSurahItems;
    }
  }

  /// Surah list filtered by the current search query.
  List<MoshafIndexItem> get filteredSurahItems {
    if (surahSearchQuery.trim().isEmpty) return surahItems;

    final normalizedQuery = normalizeArabic(surahSearchQuery);
    return surahItems.where((item) {
      return normalizeArabic(item.title).contains(normalizedQuery);
    }).toList();
  }

  /// Updates the selected tab (Surah / Juz / Hizb / Rub).
  void setSelectedTab(int index) {
    if (index == selectedTabIndex) return;
    selectedTabIndex = index;
    notifyListeners();
  }

  /// Filters the Surah tab list by name.
  void onSurahSearch(String query) {
    surahSearchQuery = query;
    notifyListeners();
  }

  /// Builds Surah starting-page entries.
  List<MoshafIndexItem> _buildSurahIndex() {
    final items = <MoshafIndexItem>[];
    final seenSurahs = <int>{};

    for (final page in pages) {
      if (seenSurahs.contains(page.sura)) continue;
      seenSurahs.add(page.sura);
      items.add(
        MoshafIndexItem(
          title: page.suraName,
          pageNumber: page.pageNumber,
        ),
      );
    }

    return items;
  }

  /// Builds starting-page entries for Juz or Hizb.
  List<MoshafIndexItem> _buildNumberIndex({
    required String label,
    required int Function(MoshafPage page) valueOf,
  }) {
    final items = <MoshafIndexItem>[];
    final seenValues = <int>{};

    for (final page in pages) {
      final value = valueOf(page);
      if (seenValues.contains(value)) continue;
      seenValues.add(value);
      items.add(
        MoshafIndexItem(
          title: '$label $value',
          pageNumber: page.pageNumber,
        ),
      );
    }

    return items;
  }

  /// Builds Rub starting pages labeled with Hizb + Rub.
  List<MoshafIndexItem> _buildRubIndex() {
    final items = <MoshafIndexItem>[];
    final seenKeys = <String>{};

    for (final page in pages) {
      final key = '${page.hizb}-${page.rub}';
      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);
      items.add(
        MoshafIndexItem(
          title: 'الحزب ${page.hizb} • الربع ${page.rub}',
          pageNumber: page.pageNumber,
        ),
      );
    }

    return items;
  }
}
