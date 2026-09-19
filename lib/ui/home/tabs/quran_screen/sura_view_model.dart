import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/utils/shared_preferences.dart';

class SuraViewModel extends ChangeNotifier {
  late int index;

  List<String> verses = [];

  int? lastReadSuraIndex;
  int? lastReadAyahIndex;
  bool isLastReadLoaded = false;

  /// Loads sura verses from assets, then loads the last-read position.
  void loadSuraContent(int index) async {
    this.index = index;
    String suraContent = await rootBundle.loadString(
      'assets/files/${index + 1}.txt',
    );
    verses = suraContent.split("\n").where((v) => v.trim().isNotEmpty).toList();
    await loadLastRead();
    notifyListeners();
  }

  /// Reads the saved last-read sura and ayah from SharedPreferences.
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

  /// Saves this ayah as the last place the user stopped reading.
  Future<void> saveLastReadAyah(int ayahIndex) async {
    await saveLastRead(suraIndex: index, ayahIndex: ayahIndex);
    lastReadSuraIndex = index;
    lastReadAyahIndex = ayahIndex;
    notifyListeners();
  }

  /// Returns true when this ayah is the saved last-read position in this sura.
  bool isHighlighted(int ayahIndex) {
    return lastReadSuraIndex == index && lastReadAyahIndex == ayahIndex;
  }

  /// Whether this sura has a saved last-read ayah to scroll to.
  bool get hasLastReadInThisSura {
    return lastReadSuraIndex == index &&
        lastReadAyahIndex != null &&
        lastReadAyahIndex! >= 0 &&
        lastReadAyahIndex! < verses.length;
  }
}
