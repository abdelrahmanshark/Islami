import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/models/moshaf_page_marker.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/shared_preferences.dart';

class MoshafViewModel extends ChangeNotifier {
  List<MoshafPage> pages = [];
  bool isLoading = true;
  String? errorMessage;

  /// Whether Mushaf uses dark page images. Default is light.
  bool isDarkTheme = false;

  /// 0-based index of the currently visible page in [pages].
  int visiblePageIndex = 0;

  /// Page to open after load (1-based).
  int initialPage = 1;

  /// Saved bookmark page number (1-based), or null if none.
  int? bookmarkedPage;

  bool didRestorePage = false;

  /// Metadata title for the AppBar of the visible page.
  String get visiblePageTitle {
    if (pages.isEmpty ||
        visiblePageIndex < 0 ||
        visiblePageIndex >= pages.length) {
      return 'المصحف';
    }
    return pages[visiblePageIndex].appBarTitle;
  }

  /// Current 1-based page number, or 1 when empty.
  int get visiblePageNumber {
    if (pages.isEmpty) return 1;
    return pages[visiblePageIndex].pageNumber;
  }

  /// True when the visible page matches the saved bookmark.
  bool get isCurrentPageBookmarked {
    return bookmarkedPage != null && bookmarkedPage == visiblePageNumber;
  }

  /// Loads page metadata, builds image pages, and restores the bookmark.
  Future<void> loadMoshaf() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      isDarkTheme = await getMoshafDarkTheme();

      final markers = await _loadPageMarkers();
      if (markers.isEmpty) {
        throw Exception('empty markers');
      }

      pages = markers.map(MoshafPage.fromMarker).toList();

      final savedPage = await getMoshafLastPage();
      bookmarkedPage = savedPage;

      if (savedPage != null && savedPage >= 1 && savedPage <= pages.length) {
        initialPage = savedPage;
      } else {
        initialPage = 1;
      }

      visiblePageIndex = initialPage - 1;
      isLoading = false;
      notifyListeners();
    } catch (_) {
      errorMessage = 'تعذر تحميل المصحف';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles light/dark Mushaf theme and saves the choice.
  Future<void> toggleTheme() async {
    isDarkTheme = !isDarkTheme;
    notifyListeners();
    await saveMoshafDarkTheme(isDarkTheme);
  }

  /// Reads page metadata from quran_with_juz_hizb_rub.json.
  Future<List<MoshafPageMarker>> _loadPageMarkers() async {
    final raw = await rootBundle.loadString(AppAssets.quranWithJuzHizbRubJson);
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => MoshafPageMarker.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates the visible page from a PageView index.
  void updateVisiblePage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return;
    if (visiblePageIndex == pageIndex) return;

    visiblePageIndex = pageIndex;
    notifyListeners();
  }

  /// Saves the currently visible page as the bookmark.
  Future<void> saveBookmark() async {
    if (pages.isEmpty) return;

    final page = visiblePageNumber;
    await saveMoshafLastPage(page);
    bookmarkedPage = page;
    notifyListeners();
  }

  /// Marks that the initial page restore already happened.
  void markPageRestored() {
    didRestorePage = true;
  }
}
