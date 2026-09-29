import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/riyad_assalihin/riyad_assalihin_repository.dart';
import 'package:islami/domain/repositories/riyad_assalihin_repository.dart';
import 'package:islami/models/riyad_assalihin.dart';
import 'package:islami/models/riyad_hadith_position.dart';
import 'package:islami/models/riyad_search_type.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/shared_preferences.dart';

class HadithViewModel extends ChangeNotifier {
  HadithViewModel({RiyadAssalihinRepository? repository})
      : _repository = repository ?? RiyadAssalihinRepositoryImpl() {
    loadChapters();
  }

  final RiyadAssalihinRepository _repository;

  /// All chapters as loaded from the JSON file.
  List<RiyadChapterModel> _allChapters = [];

  /// Normalized chapter titles, in the same order as [_allChapters].
  List<String> _normalizedTitles = [];

  /// Normalized hadith texts per chapter, in the same order as [_allChapters].
  List<List<String>> _normalizedHadithTexts = [];

  /// Finds where each hadith is, using its id.
  Map<int, RiyadHadithPosition> _hadithPositions = {};

  /// Chapters shown in the list after applying the search.
  List<RiyadChapterModel> filteredChapters = [];

  /// Favorite hadith ids, newest first.
  List<int> favoriteHadithIds = [];

  /// Favorite hadiths shown in the favorites tab after applying the search.
  List<RiyadHadithPosition> filteredFavorites = [];

  /// Selected list tab: "الكل" or "المفضلة".
  int listTabIndex = RadioViewModel.allListTabIndex;

  RiyadSearchType searchType = RiyadSearchType.chapter;
  String _searchText = '';
  bool isLoading = false;
  String failureMsg = '';

  /// True when the favorites tab is selected.
  bool get isFavoritesTab =>
      listTabIndex == RadioViewModel.favoritesListTabIndex;

  /// Loads all chapters, the saved favorites, and prepares search texts.
  Future<void> loadChapters() async {
    try {
      isLoading = true;
      failureMsg = '';
      notifyListeners();

      final response = await _repository.getRiyadAssalihin();
      _allChapters = response.chapters;
      _allChapters.sort((a, b) => a.id.compareTo(b.id));

      _normalizedTitles = [];
      _normalizedHadithTexts = [];
      _hadithPositions = {};
      for (final chapter in _allChapters) {
        _normalizedTitles.add(normalizeArabic(chapter.title));

        List<String> hadithTexts = [];
        for (int i = 0; i < chapter.hadiths.length; i++) {
          final hadith = chapter.hadiths[i];
          hadithTexts.add(normalizeArabic(hadith.text));
          _hadithPositions[hadith.id] = RiyadHadithPosition(
            chapter: chapter,
            hadithIndex: i,
          );
        }
        _normalizedHadithTexts.add(hadithTexts);
      }

      favoriteHadithIds = await getFavoriteHadithIds();
      _applySearch();
    } catch (e) {
      log(e.toString());
      failureMsg = 'فشل تحميل الأحاديث';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the search text and refreshes the lists.
  void onSearchChanged(String text) {
    _searchText = text;
    _applySearch();
    notifyListeners();
  }

  /// Switches between searching chapter titles and hadith texts.
  void onSearchTypeChanged(RiyadSearchType type) {
    if (searchType == type) return;
    searchType = type;
    _applySearch();
    notifyListeners();
  }

  /// Switches the list between "all" and "favorites".
  void changeListTab(int index) {
    if (listTabIndex == index) return;
    listTabIndex = index;
    notifyListeners();
  }

  /// Adds or removes [hadith] from favorites and saves the change.
  void toggleFavoriteHadith(RiyadHadithModel hadith) {
    if (favoriteHadithIds.contains(hadith.id)) {
      favoriteHadithIds.remove(hadith.id);
    } else {
      favoriteHadithIds.insert(0, hadith.id);
    }
    saveFavoriteHadithIds(favoriteHadithIds);
    _applySearch();
    notifyListeners();
  }

  /// Opens the selected chapter from its first hadith.
  void openChapter(BuildContext context, RiyadChapterModel chapter) {
    _openHadith(
      context,
      RiyadHadithPosition(chapter: chapter, hadithIndex: 0),
    );
  }

  /// Opens the full chapter of a favorite hadith, starting at that hadith.
  void openFavorite(BuildContext context, RiyadHadithPosition position) {
    _openHadith(context, position);
  }

  /// Opens the chapter screen, then reloads favorites changed there.
  Future<void> _openHadith(
    BuildContext context,
    RiyadHadithPosition position,
  ) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.riyadChapterRouteName,
      arguments: position,
    );
    favoriteHadithIds = await getFavoriteHadithIds();
    _applySearch();
    notifyListeners();
  }

  /// Filters chapters and favorites using the current search text and type.
  void _applySearch() {
    final query = normalizeArabic(_searchText.trim());
    _filterChapters(query);
    _filterFavorites(query);
  }

  /// Filters [filteredChapters] by chapter title or hadith text.
  void _filterChapters(String query) {
    if (query.isEmpty) {
      filteredChapters = List.of(_allChapters);
      return;
    }

    if (searchType == RiyadSearchType.chapter) {
      _filterByChapterTitle(query);
    } else {
      _filterByHadithText(query);
    }
  }

  /// Keeps chapters whose title contains [query].
  void _filterByChapterTitle(String query) {
    filteredChapters = [];
    for (int i = 0; i < _allChapters.length; i++) {
      if (_normalizedTitles[i].contains(query)) {
        filteredChapters.add(_allChapters[i]);
      }
    }
  }

  /// Keeps chapters that have matching hadiths, with only those hadiths inside.
  void _filterByHadithText(String query) {
    filteredChapters = [];
    for (int i = 0; i < _allChapters.length; i++) {
      final chapter = _allChapters[i];
      List<RiyadHadithModel> matchingHadiths = [];
      for (int j = 0; j < chapter.hadiths.length; j++) {
        if (_normalizedHadithTexts[i][j].contains(query)) {
          matchingHadiths.add(chapter.hadiths[j]);
        }
      }

      if (matchingHadiths.isNotEmpty) {
        filteredChapters.add(
          RiyadChapterModel(
            id: chapter.id,
            title: chapter.title,
            hadiths: matchingHadiths,
          ),
        );
      }
    }
  }

  /// Rebuilds [filteredFavorites] from the saved ids and the search.
  void _filterFavorites(String query) {
    filteredFavorites = [];
    for (final id in favoriteHadithIds) {
      final position = _hadithPositions[id];
      if (position == null) continue;

      if (query.isEmpty || _favoriteMatches(position, query)) {
        filteredFavorites.add(position);
      }
    }
  }

  /// True when a favorite matches [query] using the current search type.
  bool _favoriteMatches(RiyadHadithPosition position, String query) {
    if (searchType == RiyadSearchType.chapter) {
      return normalizeArabic(position.chapter.title).contains(query);
    }
    return normalizeArabic(position.hadith.text).contains(query);
  }
}
