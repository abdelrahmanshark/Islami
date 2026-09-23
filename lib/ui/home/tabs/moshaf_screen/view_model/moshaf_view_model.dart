import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/models/ayah_coordinate.dart';
import 'package:islami/models/hafs_ayah_meta.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/models/moshaf_page_marker.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/models/tafser_surah.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/shared_preferences.dart';

class MoshafViewModel extends ChangeNotifier {
  /// Madani coordinate page size used by quran_coordinates JSON.
  static const double coordinatePageWidth = 345;
  static const double coordinatePageHeight = 550;

  List<MoshafPage> pages = [];
  bool isLoading = true;
  String? errorMessage;

  /// Cached ayah metadata for the Mushaf index screen.
  List<HafsAyahMeta>? _ayahMeta;

  /// Whether Mushaf uses dark page images. Default is light.
  bool isDarkTheme = false;

  /// 0-based index of the currently visible page in [pages].
  int visiblePageIndex = 0;

  /// Page to open after load (1-based).
  int initialPage = 1;

  /// Saved bookmark page number (1-based), or null if none.
  int? bookmarkedPage;

  bool didRestorePage = false;

  /// Ayah polygons for the currently visible page.
  List<AyahCoordinate> currentPageAyahs = [];

  /// Currently highlighted ayah, or null when nothing is selected.
  AyahCoordinate? selectedAyah;

  /// True when the tafsir panel is shown instead of Mushaf pages.
  bool isShowingTafser = false;

  /// Loaded tafsir for the selected ayah, or null when none.
  TafserAyah? selectedTafserAyah;

  /// Surah name from the loaded tafsir file.
  String? selectedTafserSurahName;

  /// True while loading tafsir JSON.
  bool isTafserLoading = false;

  /// Error message when tafsir fails to load.
  String? tafserErrorMessage;

  /// Cache of page number → parsed ayah coordinates.
  final Map<int, List<AyahCoordinate>> _ayahCache = {};

  /// Cache of surah number → parsed tafsir surah.
  final Map<int, TafserSurah> _tafserCache = {};

  /// Metadata title for the AppBar of the visible page.
  String get visiblePageTitle {
    if (pages.isEmpty ||
        visiblePageIndex < 0 ||
        visiblePageIndex >= pages.length) {
      return 'المصحف';
    }
    return pages[visiblePageIndex].appBarTitle;
  }

  /// AppBar label: selected ayah when set, otherwise the surah title.
  String get appBarTitle {
    if (isShowingTafser) {
      if (selectedAyah != null) {
        final surahLabel =
            selectedTafserSurahName ??
            _surahName(selectedAyah!.surahNumber);
        return '$surahLabel : ${selectedAyah!.ayahNumber}';
      }
      return 'التفسير';
    }
    if (selectedAyah != null) {
      return '${_surahName(selectedAyah!.surahNumber)} : ${selectedAyah!.ayahNumber}';
    }
    return visiblePageTitle;
  }

  /// Arabic Surah name for a 1-based Surah number.
  String _surahName(int surahNumber) {
    if (surahNumber < 1 ||
        surahNumber > QuranResources.arabicQuranSuras.length) {
      return 'سورة $surahNumber';
    }
    return QuranResources.arabicQuranSuras[surahNumber - 1];
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

  /// Loads page metadata, builds image pages, and opens at [startPage] if set.
  Future<void> loadMoshaf({int? startPage}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      isDarkTheme = await getMoshafDarkTheme();

      final markers = await _loadPageMarkers();
      if (markers.isEmpty) {
        throw Exception('empty markers');
      }

      pages = MoshafPage.fromMarkers(markers);

      final savedPage = await getMoshafLastPage();
      bookmarkedPage = savedPage;

      if (startPage != null &&
          startPage >= 1 &&
          startPage <= pages.length) {
        initialPage = startPage;
      } else if (savedPage != null &&
          savedPage >= 1 &&
          savedPage <= pages.length) {
        initialPage = savedPage;
      } else {
        initialPage = 1;
      }

      visiblePageIndex = initialPage - 1;
      isLoading = false;
      notifyListeners();

      await loadAyahCoordinatesForPage(initialPage);
    } catch (_) {
      errorMessage = 'تعذر تحميل المصحف';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles light/dark Mushaf theme and saves the choice.
  Future<void> toggleTheme() async {
    isDarkTheme = !isDarkTheme;
    selectedAyah = null;
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

  /// Loads ayah polygons for [pageNumber] (uses cache when available).
  Future<void> loadAyahCoordinatesForPage(int pageNumber) async {
    if (_ayahCache.containsKey(pageNumber)) {
      if (visiblePageNumber != pageNumber) return;
      currentPageAyahs = _ayahCache[pageNumber]!;
      notifyListeners();
      return;
    }

    try {
      final path = AppAssets.quranPageCoordinates(pageNumber);
      final raw = await rootBundle.loadString(path);
      final list = jsonDecode(raw) as List<dynamic>;
      final ayahs = list
          .map((e) => AyahCoordinate.fromJson(e as Map<String, dynamic>))
          .toList();

      _ayahCache[pageNumber] = ayahs;

      // Ignore stale loads if the user already swiped away.
      if (visiblePageNumber != pageNumber) return;

      currentPageAyahs = ayahs;
      notifyListeners();
    } catch (_) {
      if (visiblePageNumber != pageNumber) return;
      currentPageAyahs = [];
      notifyListeners();
    }
  }

  /// Finds the ayah under [localPosition] using the displayed image [size].
  AyahCoordinate? findAyahAt(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;

    final scaleX = size.width / coordinatePageWidth;
    final scaleY = size.height / coordinatePageHeight;

    // Check from last to first so later (visually upper) ayahs win ties.
    for (var i = currentPageAyahs.length - 1; i >= 0; i--) {
      final ayah = currentPageAyahs[i];
      if (ayah.contains(localPosition, scaleX, scaleY)) {
        return ayah;
      }
    }
    return null;
  }

  /// Handles an ayah tap: select, switch, or toggle off if already selected.
  void onAyahTapped(AyahCoordinate ayah) {
    if (selectedAyah != null && selectedAyah!.isSameAyah(ayah)) {
      selectedAyah = null;
    } else {
      selectedAyah = ayah;
    }
    notifyListeners();
  }

  /// Clears the ayah highlight.
  void clearSelectedAyah() {
    if (selectedAyah == null) return;
    selectedAyah = null;
    notifyListeners();
  }

  /// Opens tafsir for the selected ayah (from ayah label).
  Future<void> openTafserForSelectedAyah() async {
    if (selectedAyah == null) return;
    await openTafser();
  }

  /// Shows the tafsir panel and loads tafsir when an ayah is selected.
  Future<void> openTafser() async {
    isShowingTafser = true;
    notifyListeners();

    if (selectedAyah != null) {
      await loadTafserForAyah(
        selectedAyah!.surahNumber,
        selectedAyah!.ayahNumber,
      );
    }
  }

  /// Hides the tafsir panel and returns to Mushaf pages.
  void closeTafser() {
    if (!isShowingTafser) return;
    isShowingTafser = false;
    notifyListeners();
  }

  /// Toggles between Mushaf pages and the tafsir panel.
  Future<void> toggleTafser() async {
    if (isShowingTafser) {
      closeTafser();
    } else {
      await openTafser();
    }
  }

  /// Loads tafsir for [surahNumber]/[ayahNumber] from assets.
  Future<void> loadTafserForAyah(int surahNumber, int ayahNumber) async {
    isTafserLoading = true;
    tafserErrorMessage = null;
    selectedTafserAyah = null;
    selectedTafserSurahName = null;
    notifyListeners();

    try {
      final surah = await _loadTafserSurah(surahNumber);
      final ayah = surah.ayahByNumber(ayahNumber);
      if (ayah == null) {
        tafserErrorMessage = 'تعذر العثور على تفسير هذه الآية';
      } else {
        selectedTafserAyah = ayah;
        selectedTafserSurahName = surah.surah;
      }
    } catch (_) {
      tafserErrorMessage = 'تعذر تحميل التفسير';
    }

    isTafserLoading = false;
    notifyListeners();
  }

  /// Loads and caches a full surah tafsir file.
  Future<TafserSurah> _loadTafserSurah(int surahNumber) async {
    final cached = _tafserCache[surahNumber];
    if (cached != null) return cached;

    final path = AppAssets.tafserSurah(surahNumber);
    final raw = await rootBundle.loadString(path);
    final surah = TafserSurah.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    _tafserCache[surahNumber] = surah;
    return surah;
  }

  /// Updates the visible page from a PageView index.
  void updateVisiblePage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return;
    if (visiblePageIndex == pageIndex) return;

    visiblePageIndex = pageIndex;
    selectedAyah = null;
    currentPageAyahs = [];
    notifyListeners();

    loadAyahCoordinatesForPage(pages[pageIndex].pageNumber);
  }

  /// Saves the current page as bookmark, or removes it if already saved.
  Future<void> toggleBookmark() async {
    if (pages.isEmpty) return;

    // Second tap on the same page removes the bookmark.
    if (isCurrentPageBookmarked) {
      await clearMoshafLastPage();
      bookmarkedPage = null;
      notifyListeners();
      return;
    }

    final page = visiblePageNumber;
    await saveMoshafLastPage(page);
    bookmarkedPage = page;
    notifyListeners();
  }

  /// Marks that the initial page restore already happened.
  void markPageRestored() {
    didRestorePage = true;
  }

  /// Loads ayah metadata for the index (cached after first load).
  Future<List<HafsAyahMeta>> loadAyahMeta() async {
    if (_ayahMeta != null) return _ayahMeta!;

    final raw = await rootBundle.loadString(AppAssets.hafsAyahMetaJson);
    final list = jsonDecode(raw) as List<dynamic>;
    _ayahMeta = list
        .map((e) => HafsAyahMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _ayahMeta!;
  }
}
