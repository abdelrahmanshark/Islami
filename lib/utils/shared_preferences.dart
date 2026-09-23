import 'package:islami/models/user_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesKay {
  static const String azanEnabled = 'azanEnabled';
  static const String moshafLastPage = 'moshafLastPage';
  static const String moshafDarkTheme = 'moshafDarkTheme';
  static const String moshafMemorizedPages = 'moshafMemorizedPages';
  static const String moshafMemorizedAyahs = 'moshafMemorizedAyahs';
  static const String prayerDate = 'prayerDate';
  static const String prayerFajr = 'prayerFajr';
  static const String prayerDhuhr = 'prayerDhuhr';
  static const String prayerAsr = 'prayerAsr';
  static const String prayerMaghrib = 'prayerMaghrib';
  static const String prayerIsha = 'prayerIsha';
  static const String cachedTimeResponse = 'cachedTimeResponse';
  static const String userLatitude = 'userLatitude';
  static const String userLongitude = 'userLongitude';
  static const String userCity = 'userCity';
  static const String userCountry = 'userCountry';
  static const String downloadedQuranAudio = 'downloadedQuranAudio';
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

/// Saved raw prayer times used to reschedule Adhan alarms.
class SavedPrayerTimings {
  SavedPrayerTimings({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final String date;
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
}

/// Persists today's five salah times for background alarm scheduling.
Future<void> savePrayerTimings({
  required String date,
  required String fajr,
  required String dhuhr,
  required String asr,
  required String maghrib,
  required String isha,
}) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setString(SharedPreferencesKay.prayerDate, date);
  await pref.setString(SharedPreferencesKay.prayerFajr, fajr);
  await pref.setString(SharedPreferencesKay.prayerDhuhr, dhuhr);
  await pref.setString(SharedPreferencesKay.prayerAsr, asr);
  await pref.setString(SharedPreferencesKay.prayerMaghrib, maghrib);
  await pref.setString(SharedPreferencesKay.prayerIsha, isha);
}

/// Returns saved prayer times, or null if any value is missing.
Future<SavedPrayerTimings?> getSavedPrayerTimings() async {
  final pref = await SharedPreferences.getInstance();
  final date = pref.getString(SharedPreferencesKay.prayerDate);
  final fajr = pref.getString(SharedPreferencesKay.prayerFajr);
  final dhuhr = pref.getString(SharedPreferencesKay.prayerDhuhr);
  final asr = pref.getString(SharedPreferencesKay.prayerAsr);
  final maghrib = pref.getString(SharedPreferencesKay.prayerMaghrib);
  final isha = pref.getString(SharedPreferencesKay.prayerIsha);

  if (date == null ||
      fajr == null ||
      dhuhr == null ||
      asr == null ||
      maghrib == null ||
      isha == null) {
    return null;
  }

  return SavedPrayerTimings(
    date: date,
    fajr: fajr,
    dhuhr: dhuhr,
    asr: asr,
    maghrib: maghrib,
    isha: isha,
  );
}

/// Saves the last Moshaf page the user stopped reading at (1–604).
Future<void> saveMoshafLastPage(int page) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setInt(SharedPreferencesKay.moshafLastPage, page);
}

/// Clears the saved Moshaf bookmark page.
Future<void> clearMoshafLastPage() async {
  final pref = await SharedPreferences.getInstance();
  await pref.remove(SharedPreferencesKay.moshafLastPage);
}

/// Returns the saved Moshaf page, or null if none exists.
Future<int?> getMoshafLastPage() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getInt(SharedPreferencesKay.moshafLastPage);
}

/// Returns whether Mushaf dark theme is on. Defaults to light (false).
Future<bool> getMoshafDarkTheme() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getBool(SharedPreferencesKay.moshafDarkTheme) ?? false;
}

/// Saves the Mushaf dark/light theme preference.
Future<void> saveMoshafDarkTheme(bool isDark) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setBool(SharedPreferencesKay.moshafDarkTheme, isDark);
}

/// Returns Mushaf pages marked as memorized (empty when none saved).
Future<Set<int>> getMoshafMemorizedPages() async {
  final pref = await SharedPreferences.getInstance();
  final saved =
      pref.getStringList(SharedPreferencesKay.moshafMemorizedPages) ?? [];
  return saved.map(int.parse).toSet();
}

/// Saves the set of Mushaf pages marked as memorized.
Future<void> saveMoshafMemorizedPages(Set<int> pages) async {
  final pref = await SharedPreferences.getInstance();
  final sorted = pages.toList()..sort();
  await pref.setStringList(
    SharedPreferencesKay.moshafMemorizedPages,
    sorted.map((page) => page.toString()).toList(),
  );
}

/// Returns Mushaf ayah IDs marked as memorized (empty when none saved).
Future<Set<int>> getMoshafMemorizedAyahs() async {
  final pref = await SharedPreferences.getInstance();
  final saved =
      pref.getStringList(SharedPreferencesKay.moshafMemorizedAyahs) ?? [];
  return saved.map(int.parse).toSet();
}

/// Saves the set of Mushaf ayah IDs marked as memorized.
Future<void> saveMoshafMemorizedAyahs(Set<int> ayahIds) async {
  final pref = await SharedPreferences.getInstance();
  final sorted = ayahIds.toList()..sort();
  await pref.setStringList(
    SharedPreferencesKay.moshafMemorizedAyahs,
    sorted.map((id) => id.toString()).toList(),
  );
}

/// Saves the user's coordinates and place names locally.
Future<void> saveUserLocation(UserLocation location) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setDouble(SharedPreferencesKay.userLatitude, location.latitude);
  await pref.setDouble(SharedPreferencesKay.userLongitude, location.longitude);
  await pref.setString(SharedPreferencesKay.userCity, location.city);
  await pref.setString(SharedPreferencesKay.userCountry, location.country);
}

/// Returns the saved location, or null when nothing was stored yet.
Future<UserLocation?> getSavedUserLocation() async {
  final pref = await SharedPreferences.getInstance();
  final double? latitude = pref.getDouble(SharedPreferencesKay.userLatitude);
  final double? longitude = pref.getDouble(SharedPreferencesKay.userLongitude);

  if (latitude == null || longitude == null) {
    return null;
  }

  return UserLocation(
    latitude: latitude,
    longitude: longitude,
    city: pref.getString(SharedPreferencesKay.userCity) ?? '',
    country: pref.getString(SharedPreferencesKay.userCountry) ?? '',
  );
}
