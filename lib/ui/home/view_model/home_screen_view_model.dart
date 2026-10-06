import 'package:flutter/material.dart';

class HomeScreenViewModel extends ChangeNotifier {
  static const int radioTabIndex = 3;
  static const int downloadsTabIndex = 4;

  int selectedIndex = 0;

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
