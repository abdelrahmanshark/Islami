import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/shared_preferences.dart';

class MostRecentProvider extends ChangeNotifier {
  static List<int> mostRecentSuras = [];

  void readMostRecentSuras() async {
    final pref = await SharedPreferences.getInstance();
    List<String> mostRecentAsString =
        await pref.getStringList(SharedPreferencesKay.kay) ?? [];
    List<int> mostRecentAsInt = mostRecentAsString
        .map((e) => int.parse(e))
        .toList();
    mostRecentSuras = mostRecentAsInt;
    notifyListeners();
  }
}
