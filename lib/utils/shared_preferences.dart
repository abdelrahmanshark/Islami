import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesKay {
  static const String kay = 'MostRecently';
  static const String azanEnabled = 'azanEnabled';
}

/// Returns whether azan sound is enabled. Defaults to true when unset.
Future<bool> getAzanEnabled() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getBool(SharedPreferencesKay.azanEnabled) ?? true;
}

/// Saves the azan sound on/off preference.
Future<void> saveAzanEnabled(bool enabled) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setBool(SharedPreferencesKay.azanEnabled, enabled);
}

Future<void> saveSuraIndexToSharedPreferences(int index) async {
  final pref = await SharedPreferences.getInstance();

  List<String> mostRecent =
      pref.getStringList(SharedPreferencesKay.kay) ?? [];

  if (mostRecent.contains("$index")) {
    mostRecent.remove("$index");
  }

  mostRecent.insert(0, "$index");

  if (mostRecent.length > 5) {
    mostRecent.removeLast();
  }

  await pref.setStringList(
    SharedPreferencesKay.kay,
    mostRecent,
  );
}
