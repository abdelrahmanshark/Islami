import 'package:flutter/material.dart';
import 'package:islami/models/riyad_assalihin.dart';
import 'package:islami/models/riyad_hadith_position.dart';
import 'package:islami/utils/shared_preferences.dart';

class RiyadChapterViewModel extends ChangeNotifier {
  RiyadChapterViewModel({required RiyadHadithPosition position})
      : chapter = position.chapter,
        initialIndex = position.hadithIndex,
        currentIndex = position.hadithIndex {
    _loadFavorites();
  }

  final RiyadChapterModel chapter;

  /// Index of the hadith shown first when the screen opens.
  final int initialIndex;

  /// Index of the hadith card currently shown in the carousel.
  int currentIndex;

  /// Favorite hadith ids, newest first.
  List<int> favoriteHadithIds = [];

  /// Text like "3 / 47" showing the current hadith position.
  String get positionText => '${currentIndex + 1} / ${chapter.hadiths.length}';

  /// Title shown on the hadith card at [index].
  String hadithTitle(int index) => 'الحديث ${index + 1}';

  /// Updates the current hadith when the carousel page changes.
  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  /// True when the hadith at [index] is in the favorites.
  bool isFavorite(int index) {
    return favoriteHadithIds.contains(chapter.hadiths[index].id);
  }

  /// Adds or removes the hadith at [index] from favorites and saves it.
  void toggleFavorite(int index) {
    final int id = chapter.hadiths[index].id;
    if (favoriteHadithIds.contains(id)) {
      favoriteHadithIds.remove(id);
    } else {
      favoriteHadithIds.insert(0, id);
    }
    saveFavoriteHadithIds(favoriteHadithIds);
    notifyListeners();
  }

  /// Reads the saved favorite ids so the hearts show the right state.
  Future<void> _loadFavorites() async {
    favoriteHadithIds = await getFavoriteHadithIds();
    notifyListeners();
  }
}
