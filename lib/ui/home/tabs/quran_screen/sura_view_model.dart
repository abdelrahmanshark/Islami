import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuraViewModel extends ChangeNotifier {
  late int index;

  List<String> verses = [];

  void loadSuraContent(int index) async {
    String suraContent = await rootBundle.loadString(
      'assets/files/${index + 1}.txt',
    );
    verses = suraContent.split("\n");
    notifyListeners();
  }
}
