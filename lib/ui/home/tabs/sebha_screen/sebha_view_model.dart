import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/azkar/azkar_repository.dart';
import 'package:islami/domain/repositories/azkar_repository.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/shared_preferences.dart';

class SebhaViewModel extends ChangeNotifier {
  SebhaViewModel({AzkarRepository? azkarRepository})
      : _azkarRepository = azkarRepository ?? AzkarRepositoryImpl() {
    loadAzkar();
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
  int counter = 0;
  int totalCount = 0;
  List<String> azkar = ['سبحان الله', 'الحمد لله', 'الله أكبر', 'أستغفر الله'];
  int azkarIndex = 0;

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

  String _searchText = '';
  bool isAzkarLoading = false;
  String azkarFailureMsg = '';

  /// True when the current zikr reached its last tasbiha (33 of 33).
  bool get isRoundCompleted => counter == tasbihLimit;

  /// Switches between the sebha and the azkar tabs.
  /// The search is cleared because the search field is rebuilt empty.
  void changeTab(int index) {
    if (tabIndex == index) return;
    tabIndex = index;
    _searchText = '';
    _applySearch();
    notifyListeners();
  }

  /// Rotates the sebha one bead and advances the tasbih counter.
  /// After 33 the next tap moves to the next zikr and starts again from 1.
  void rotate() {
    turns += 1 / tasbihLimit;
    if (isRoundCompleted) {
      counter = 0;
      azkarIndex = (azkarIndex + 1) % azkar.length;
    }
    counter++;
    totalCount++;
    notifyListeners();
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
    _searchText = text;
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
    final query = normalizeArabic(_searchText.trim());

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
