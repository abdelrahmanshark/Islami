import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/domain/repositories/azkar_repository.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/models/tasbih_zikr.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/shared_preferences.dart';

@injectable
class SebhaViewModel extends ChangeNotifier {
  SebhaViewModel(this._azkarRepository) {
    loadAzkar();
    loadTasbihProgress();
  }

  final AzkarRepository _azkarRepository;

  static const int sebhaTabIndex = 0;
  static const int azkarTabIndex = 1;

  /// How many tasbihat make one round of the same zikr.
  static const int tasbihLimit = 33;

  /// Selected top tab: "سبحة" or "أذكار وأدعية".
  int tabIndex = sebhaTabIndex;

  /// Sebha rotation in full turns (1.0 = 360°).
  double turns = 0;

  /// The 4 sebha azkar, each with its own saved counters.
  List<TasbihZikr> tasbihAzkar = [
    TasbihZikr(title: 'الحمد لله'),
    TasbihZikr(title: 'سبحان الله'),
    TasbihZikr(title: 'أستغفر الله'),
    TasbihZikr(title: 'الله أكبر'),
  ];

  /// Index of the zikr the sebha is currently counting.
  int activeZikrIndex = 0;

  /// All azkar categories as loaded from the JSON file.
  List<AzkarCategory> _allCategories = [];

  /// Normalized category titles, in the same order as [_allCategories].
  List<String> _normalizedTitles = [];

  /// Categories shown in the list after applying the search.
  List<AzkarCategory> filteredCategories = [];

  /// Favorite category titles, newest first.
  List<String> favoriteCategoryTitles = [];

  /// Favorite categories shown after applying the search.
  List<AzkarCategory> filteredFavorites = [];

  /// Azkar search field text, saved in SharedPreferences.
  String searchText = '';
  bool isAzkarLoading = false;
  String azkarFailureMsg = '';

  /// The zikr the sebha is currently counting.
  TasbihZikr get activeZikr => tasbihAzkar[activeZikrIndex];

  /// True when the current zikr reached its last tasbiha (33 of 33).
  bool get isRoundCompleted => isZikrCompleted(activeZikr);

  /// Sum of all tasbihat of all azkar.
  int get totalCount {
    int sum = 0;
    for (final zikr in tasbihAzkar) {
      sum += zikr.totalCount;
    }
    return sum;
  }

  /// True when [zikr] finished its current round of 33.
  bool isZikrCompleted(TasbihZikr zikr) => zikr.roundCount == tasbihLimit;

  /// How much of the current round of [zikr] is done, from 0.0 to 1.0.
  double roundProgress(TasbihZikr zikr) => zikr.roundCount / tasbihLimit;

  /// Switches between the sebha and the azkar tabs (the search is kept).
  void changeTab(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    notifyListeners();
  }

  /// Rotates the sebha one bead and counts one tasbiha for the active zikr.
  /// After 33 the next tap moves to the next zikr.
  void rotate() {
    if (isRoundCompleted) {
      activeZikrIndex = (activeZikrIndex + 1) % tasbihAzkar.length;
      _startNewRoundIfCompleted();
    }
    turns += 1 / tasbihLimit;
    activeZikr.roundCount++;
    activeZikr.totalCount++;
    _saveTasbihProgress();
    notifyListeners();
  }

  /// Makes [index] the active zikr. A finished zikr starts a new round of 33.
  void selectZikr(int index) {
    activeZikrIndex = index;
    _startNewRoundIfCompleted();
    _saveTasbihProgress();
    notifyListeners();
  }

  /// Clears all sebha counters and goes back to the first zikr.
  void resetAllCounters() {
    for (final zikr in tasbihAzkar) {
      zikr.roundCount = 0;
      zikr.totalCount = 0;
    }
    activeZikrIndex = 0;
    _saveTasbihProgress();
    notifyListeners();
  }

  /// Loads the saved sebha counters and the selected zikr.
  Future<void> loadTasbihProgress() async {
    final List<int> roundCounts = await getTasbihRoundCounts();
    final List<int> totalCounts = await getTasbihTotalCounts();
    final int savedIndex = await getTasbihActiveIndex();

    // Ignore old data that does not match the current azkar list.
    if (roundCounts.length == tasbihAzkar.length &&
        totalCounts.length == tasbihAzkar.length) {
      for (int i = 0; i < tasbihAzkar.length; i++) {
        tasbihAzkar[i].roundCount = roundCounts[i];
        tasbihAzkar[i].totalCount = totalCounts[i];
      }
    }
    if (savedIndex >= 0 && savedIndex < tasbihAzkar.length) {
      activeZikrIndex = savedIndex;
    }
    notifyListeners();
  }

  /// Resets the active zikr's round to 0 when it already reached 33.
  void _startNewRoundIfCompleted() {
    if (isRoundCompleted) {
      activeZikr.roundCount = 0;
    }
  }

  /// Saves the sebha counters so they survive app restarts.
  void _saveTasbihProgress() {
    List<int> roundCounts = [];
    List<int> totalCounts = [];
    for (final zikr in tasbihAzkar) {
      roundCounts.add(zikr.roundCount);
      totalCounts.add(zikr.totalCount);
    }
    saveTasbihProgress(
      roundCounts: roundCounts,
      totalCounts: totalCounts,
      activeIndex: activeZikrIndex,
    );
  }

  /// Loads the azkar categories and the saved favorites.
  Future<void> loadAzkar() async {
    try {
      isAzkarLoading = true;
      azkarFailureMsg = '';
      notifyListeners();

      final response = await _azkarRepository.getAzkar();
      _allCategories = response.categories;
      _normalizedTitles = [];
      for (final category in _allCategories) {
        _normalizedTitles.add(normalizeArabic(category.title));
      }

      favoriteCategoryTitles = await getFavoriteAzkarCategories();
      searchText = await getSearchText(SharedPreferencesKay.azkarSearch);
      _applySearch();
    } catch (e) {
      log(e.toString());
      azkarFailureMsg = 'فشل تحميل الأذكار';
    } finally {
      isAzkarLoading = false;
      notifyListeners();
    }
  }

  /// Updates the search text and refreshes the lists.
  void onSearchChanged(String text) {
    searchText = text;
    saveSearchText(SharedPreferencesKay.azkarSearch, text);
    _applySearch();
    notifyListeners();
  }

  /// True when [category] is saved in favorites.
  bool isFavorite(AzkarCategory category) {
    return favoriteCategoryTitles.contains(category.title);
  }

  /// Adds or removes [category] from favorites and saves the change.
  void toggleFavorite(AzkarCategory category) {
    if (isFavorite(category)) {
      favoriteCategoryTitles.remove(category.title);
    } else {
      favoriteCategoryTitles.insert(0, category.title);
    }
    saveFavoriteAzkarCategories(favoriteCategoryTitles);
    _applySearch();
    notifyListeners();
  }

  /// Opens the Azkar screen for the selected category.
  void openCategory(BuildContext context, AzkarCategory category) {
    Navigator.pushNamed(
      context,
      AppRoutes.azkarRouteName,
      arguments: category,
    );
  }

  /// Filters categories and favorites by the current search text.
  void _applySearch() {
    final query = normalizeArabic(searchText.trim());

    filteredCategories = [];
    for (int i = 0; i < _allCategories.length; i++) {
      if (query.isEmpty || _normalizedTitles[i].contains(query)) {
        filteredCategories.add(_allCategories[i]);
      }
    }

    filteredFavorites = [];
    for (final title in favoriteCategoryTitles) {
      final int index = _allCategories.indexWhere(
        (category) => category.title == title,
      );
      if (index == -1) continue;

      if (query.isEmpty || _normalizedTitles[index].contains(query)) {
        filteredFavorites.add(_allCategories[index]);
      }
    }
  }
}
