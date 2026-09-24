import 'package:flutter/material.dart';
import 'package:islami/ui/downloads_view/downloads_view.dart';
import 'package:islami/ui/home/tabs/hadith_screen/hadith_screen.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_hub_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_screen.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_screen.dart';
import 'package:islami/ui/home/tabs/time_screen/time_screen.dart';

class HomeScreenViewModel extends ChangeNotifier {
  static const int radioTabIndex = 3;
  static const int downloadsTabIndex = 4;

  int selectedIndex = 0;
  List<Widget> tabs = [
    const MoshafHubView(),
    HadithScreen(),
    SebhaScreen(),
    RadioScreen(),
    DownloadsView(),
    TimeScreen(),
  ];

  void updateIndex(int index) {
    if (selectedIndex == index) return;
    selectedIndex = index;
    notifyListeners();
  }

  /// Switches to [index] (skipped when already open) and waits until the
  /// new tab has been built, so the next navigation step can run on it.
  Future<void> openTab(int index) async {
    if (selectedIndex == index) return;
    updateIndex(index);
    await WidgetsBinding.instance.endOfFrame;
  }
}
