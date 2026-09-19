import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/shared_preferences.dart';

import '../../../../utils/app_routes.dart';

class QuranViewModel extends ChangeNotifier {
  List<int> filterSearch = List.generate(114, (index) => index);

  int? lastReadSuraIndex;
  int? lastReadAyahIndex;
  bool isLastReadLoaded = false;

  QuranViewModel() {
    loadLastRead();
  }

  /// Loads the saved last-read position for the Continue Reading banner.
  Future<void> loadLastRead() async {
    final lastRead = await getLastRead();
    if (lastRead != null) {
      lastReadSuraIndex = lastRead.suraIndex;
      lastReadAyahIndex = lastRead.ayahIndex;
    } else {
      lastReadSuraIndex = null;
      lastReadAyahIndex = null;
    }
    isLastReadLoaded = true;
    notifyListeners();
  }

  /// Whether a last-read position exists to show Continue Reading.
  bool get hasLastRead {
    return lastReadSuraIndex != null && lastReadAyahIndex != null;
  }

  void onSearch(String newText) {
    List<int> suraResultSearch = [];
    final normalizedQuery = normalizeArabic(newText);

    for (int i = 0; i < QuranResources.englishQuranSuras.length; i++) {
      if (QuranResources.englishQuranSuras[i].toUpperCase().contains(
            newText.toUpperCase(),
          ) ||
          normalizeArabic(QuranResources.arabicQuranSuras[i])
              .contains(normalizedQuery)) {
        suraResultSearch.add(i);
      }
    }

    filterSearch = suraResultSearch;
    notifyListeners();
  }

  void onSuraTap(int index, BuildContext context) {
    saveSuraIndexToSharedPreferences(index);
    Navigator.of(context)
        .pushNamed(AppRoutes.soraDetailsRouteName, arguments: index)
        .then((_) => loadLastRead());
  }

  /// Opens the sura of the last-read ayah.
  void onContinueReading(BuildContext context) {
    if (!hasLastRead) return;
    Navigator.of(context)
        .pushNamed(
          AppRoutes.soraDetailsRouteName,
          arguments: lastReadSuraIndex,
        )
        .then((_) => loadLastRead());
  }
}
