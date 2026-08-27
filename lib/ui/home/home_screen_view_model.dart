import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/hadith_screen/hadith_screen.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_screen.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_screen.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_screen.dart';
import 'package:islami/ui/home/tabs/time_screen/time_screen.dart';

class HomeScreenViewModel extends ChangeNotifier {
  int selectedIndex = 0;
  List<Widget> tabs = [
    QuranScreen(),
    HadithScreen(),
    SebhaScreen(),
    RadioScreen(),
    TimeScreen(),
  ];

  void updateIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}
