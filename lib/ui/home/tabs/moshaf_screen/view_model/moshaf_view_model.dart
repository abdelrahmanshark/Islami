import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/models/moshaf_page_marker.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/shared_preferences.dart';

/// How the Mushaf search field interprets the query.
enum MoshafSearchMode { suraName, pageNumber }

class MoshafViewModel extends ChangeNotifier {
  List<MoshafPage> pages = [];
  bool isLoading = true;
  String? errorMessage;

  /// 0-based index of the currently visible page in [pages].
  int visiblePageIndex = 0;

  /// 0-based Surah index shown in the AppBar.
  int visibleSuraIndex = 0;

  /// Page to jump to after the list is built (1-based).
  int initialPage = 1;

  bool didRestoreScroll = false;

  /// Whether the search field under the AppBar is visible.
  bool isSearchVisible = false;

  /// Current search mode from the dropdown.
  MoshafSearchMode searchMode = MoshafSearchMode.suraName;

  /// Latest text typed in the search field.
  String searchQuery = '';

  /// Arabic Surah name for the AppBar.
  String get visibleSuraName {
    if (visibleSuraIndex < 0 ||
        visibleSuraIndex >= QuranResources.arabicQuranSuras.length) {
      return '';
    }
    return QuranResources.arabicQuranSuras[visibleSuraIndex];
  }

  /// Hint text based on the selected search mode.
  String get searchHint {
    return searchMode == MoshafSearchMode.suraName
        ? 'اسم السورة'
        : 'رقم الصفحة';
  }

  /// Shows or hides the search bar and clears the query when closed.
  void toggleSearch() {
    isSearchVisible = !isSearchVisible;
    if (!isSearchVisible) {
      searchQuery = '';
    }
    notifyListeners();
  }

  /// Changes search mode and clears the current query.
  void setSearchMode(MoshafSearchMode mode) {
    if (searchMode == mode) return;
    searchMode = mode;
    searchQuery = '';
    notifyListeners();
  }

  /// Updates the search query from the text field.
  void updateSearchQuery(String value) {
    searchQuery = value;
  }

  /// Returns the 0-based page index for the current query, or null if invalid.
  int? findTargetPageIndex() {
    final query = searchQuery.trim();
    if (query.isEmpty || pages.isEmpty) return null;

    if (searchMode == MoshafSearchMode.pageNumber) {
      return _findPageIndexByNumber(query);
    }
    return _findPageIndexBySuraName(query);
  }

  /// Parses a page number and maps it to a list index.
  int? _findPageIndexByNumber(String query) {
    final pageNumber = int.tryParse(query);
    if (pageNumber == null) return null;
    if (pageNumber < 1 || pageNumber > pages.length) return null;
    return pageNumber - 1;
  }

  /// Finds the first Surah match and returns the page where it starts.
  int? _findPageIndexBySuraName(String query) {
    final lowerQuery = query.toLowerCase();
    final normalizedQuery = normalizeArabic(query);
    int? suraNumber;

    for (int i = 0; i < QuranResources.arabicQuranSuras.length; i++) {
      final arabic = normalizeArabic(QuranResources.arabicQuranSuras[i]);
      final english = QuranResources.englishQuranSuras[i].toLowerCase();
      if (arabic.contains(normalizedQuery) || english.contains(lowerQuery)) {
        suraNumber = i + 1;
        break;
      }
    }

    if (suraNumber == null) return null;
    return _findPageIndexForSura(suraNumber);
  }

  /// Finds the page where [suraNumber] begins, or the first page that has it.
  int? _findPageIndexForSura(int suraNumber) {
    for (int i = 0; i < pages.length; i++) {
      for (final ayah in pages[i].ayahs) {
        if (ayah.sura == suraNumber && ayah.startsSura) {
          return i;
        }
      }
    }

    for (int i = 0; i < pages.length; i++) {
      if (pages[i].ayahs.any((ayah) => ayah.sura == suraNumber)) {
        return i;
      }
    }
    return null;
  }

  /// Loads page markers, Surah text files, builds 604 pages, restores position.
  Future<void> loadMoshaf() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final markers = await _loadPageMarkers();
      final suraVerses = await _loadAllSuraVerses();
      pages = _buildPages(markers, suraVerses);

      final savedPage = await getMoshafLastPage();
      if (savedPage != null && savedPage >= 1 && savedPage <= pages.length) {
        initialPage = savedPage;
      } else {
        initialPage = 1;
      }

      visiblePageIndex = initialPage - 1;
      if (pages.isNotEmpty) {
        visibleSuraIndex = pages[visiblePageIndex].primarySuraIndex;
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'تعذر تحميل المصحف';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Reads quran.json page-start markers from assets.
  Future<List<MoshafPageMarker>> _loadPageMarkers() async {
    final raw = await rootBundle.loadString(AppAssets.quranJson);
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MoshafPageMarker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Loads all 114 Surah text files (same assets used by the Quran tab).
  Future<List<List<String>>> _loadAllSuraVerses() async {
    final result = <List<String>>[];
    for (int sura = 1; sura <= 114; sura++) {
      final content = await rootBundle.loadString('assets/files/$sura.txt');
      final verses = content
          .split('\n')
          .where((v) => v.trim().isNotEmpty)
          .toList();
      result.add(verses);
    }
    return result;
  }

  /// Maps markers + Surah verses into 604 Mushaf pages.
  List<MoshafPage> _buildPages(
    List<MoshafPageMarker> markers,
    List<List<String>> suraVerses,
  ) {
    final pages = <MoshafPage>[];

    for (int i = 0; i < markers.length; i++) {
      final start = markers[i];
      final end = i + 1 < markers.length ? markers[i + 1] : null;
      final ayahs = _collectAyahs(
        suraVerses: suraVerses,
        startSura: start.sura,
        startAya: start.aya,
        endSura: end?.sura,
        endAya: end?.aya,
      );
      pages.add(MoshafPage(pageNumber: start.page, ayahs: ayahs));
    }

    return pages;
  }

  /// Collects ayahs from [startSura:startAya] inclusive until [endSura:endAya]
  /// exclusive. When end is null, collects until the end of the Quran.
  List<MoshafAyah> _collectAyahs({
    required List<List<String>> suraVerses,
    required int startSura,
    required int startAya,
    int? endSura,
    int? endAya,
  }) {
    final ayahs = <MoshafAyah>[];
    int sura = startSura;
    int aya = startAya;

    while (true) {
      if (endSura != null && endAya != null) {
        if (sura > endSura) break;
        if (sura == endSura && aya >= endAya) break;
      }
      if (sura > 114) break;

      final verses = suraVerses[sura - 1];
      if (aya < 1 || aya > verses.length) {
        // Move to the next Surah when this one is finished.
        sura++;
        aya = 1;
        continue;
      }

      ayahs.add(
        MoshafAyah(
          sura: sura,
          aya: aya,
          text: verses[aya - 1].trim(),
          startsSura: aya == 1,
        ),
      );

      aya++;
      if (aya > verses.length) {
        sura++;
        aya = 1;
      }
    }

    return ayahs;
  }

  /// Updates AppBar Surah from the currently visible page index.
  void updateVisiblePage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return;
    if (visiblePageIndex == pageIndex) return;

    visiblePageIndex = pageIndex;
    visibleSuraIndex = pages[pageIndex].primarySuraIndex;
    notifyListeners();
  }

  /// Saves the current (or given) page as the Moshaf reading position.
  Future<void> saveReadingPosition({int? pageNumber}) async {
    final page = pageNumber ??
        (pages.isEmpty ? 1 : pages[visiblePageIndex].pageNumber);
    await saveMoshafLastPage(page);
  }

  /// Marks that the initial scroll restore already happened.
  void markScrollRestored() {
    didRestoreScroll = true;
  }
}
