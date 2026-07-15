import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesKay {
  static const String kay = 'MostRecently';
}

void saveSuraIndex(int index) async {
  final pref = await SharedPreferences.getInstance();
  List<String> mostRecent = pref.getStringList(SharedPreferencesKay.kay) ?? [];
  if (mostRecent.contains("$index")) {
    mostRecent.remove("$index");
    mostRecent.insert(0, "$index");
  } else {
    mostRecent.insert(0, "$index");
  }
  if (mostRecent.length > 5) {
    mostRecent.removeLast();
  }

  await pref.setStringList(SharedPreferencesKay.kay, mostRecent);
}
