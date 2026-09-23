import 'package:flutter/material.dart';
import 'package:islami/models/hafs_ayah_meta.dart';
import 'package:islami/models/moshaf_index_data.dart';
import 'package:islami/models/moshaf_index_item.dart';
import 'package:islami/models/moshaf_memorization_tracker.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/shared_preferences.dart';

class MoshafIndexViewModel extends ChangeNotifier {
  final List<HafsAyahMeta> ayahs;
  late final List<MoshafIndexItem> surahItems;
  late final List<MoshafIndexItem> juzItems;
  late final List<MoshafIndexItem> hizbItems;
  late final List<MoshafIndexItem> rubItems;
  late final MoshafMemorizationTracker memorizationTracker;

  int selectedTabIndex = 0;
  String surahSearchQuery = '';
  bool isProgressLoaded = false;

  MoshafIndexViewModel({required this.ayahs}) {
    final indexData = MoshafIndexData.fromAyahs(ayahs);
    surahItems = indexData.surahItems;
    juzItems = indexData.juzItems;
    hizbItems = indexData.hizbItems;
    rubItems = indexData.rubItems;
    memorizationTracker = indexData.memorizationTracker;
    loadMemorizationProgress();
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

  /// Loads saved memorized ayahs (migrates old page progress when needed).
  Future<void> loadMemorizationProgress() async {
    var savedAyahs = await getMoshafMemorizedAyahs();

    // Migrate older page-based progress into ayah IDs once.
    if (savedAyahs.isEmpty) {
      final savedPages = await getMoshafMemorizedPages();
      if (savedPages.isNotEmpty) {
        savedAyahs = {
          for (final ayah in ayahs)
            if (savedPages.contains(ayah.page)) ayah.id,
        };
        await saveMoshafMemorizedAyahs(savedAyahs);
      }
    }

    memorizationTracker.setCompletedAyahs(savedAyahs);
    isProgressLoaded = true;
    notifyListeners();
  }

  /// Whether this index item is fully memorized.
  bool isItemCompleted(MoshafIndexItem item) {
    return memorizationTracker.isCompleted(item);
  }

  /// Toggles memorization for [item] and persists ayah progress.
  Future<void> toggleItemCompletion(MoshafIndexItem item) async {
    final updatedAyahs = memorizationTracker.toggle(item);
    notifyListeners();
    await saveMoshafMemorizedAyahs(updatedAyahs);
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
}
