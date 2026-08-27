import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/utils/shared_preferences.dart';

import '../../../../utils/app_routes.dart';

class QuranViewModel extends ChangeNotifier {
  List<int> filterSearch = List.generate(114, (index) => index);

  void onSearch(String newText) {
    List<int> suraResultSearch = [];

    for (int i = 0; i < QuranResources.englishQuranSuras.length; i++) {
      if (QuranResources.englishQuranSuras[i].toUpperCase().contains(
            newText.toUpperCase(),
          ) ||
          QuranResources.arabicQuranSuras[i].contains(newText)) {
        suraResultSearch.add(i);
      }
    }

    filterSearch = suraResultSearch;
    notifyListeners();
  }

  void onSuraTap(int index, BuildContext context) {
    saveSuraIndexToSharedPreferences(index);
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.soraDetailsRouteName, arguments: index);
    notifyListeners();
  }
}
