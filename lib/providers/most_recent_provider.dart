import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_routes.dart';
import '../utils/shared_preferences.dart';

class MostRecentProvider extends ChangeNotifier {
  List<int> mostRecentSuras = [];

  MostRecentProvider() {
    readMostRecentSuras();
  }

  Future<void> readMostRecentSuras() async {
    final pref = await SharedPreferences.getInstance();
    List<String> mostRecentAsString =
        await pref.getStringList(SharedPreferencesKay.kay) ?? [];
    List<int> mostRecentAsInt = mostRecentAsString
        .map((e) => int.parse(e))
        .toList();
    mostRecentSuras = mostRecentAsInt;
    notifyListeners();
  }

  Future<void> saveSuraIndex(int index, BuildContext context) async {
    await saveSuraIndexToSharedPreferences(index);
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.soraDetailsRouteName, arguments: index);

    notifyListeners();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
