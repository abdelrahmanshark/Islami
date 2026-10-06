import 'dart:ui';

import 'package:islami/models/user_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesKay {
  static const String azanEnabled = 'azanEnabled';
  static const String moshafLastPage = 'moshafLastPage';
  static const String moshafLastReadPage = 'moshafLastReadPage';
  static const String moshafDarkTheme = 'moshafDarkTheme';
  static const String moshafLightPageColor = 'moshafLightPageColor';
  static const String moshafLightBackgroundColor = 'moshafLightBackgroundColor';
  static const String moshafDarkPageColor = 'moshafDarkPageColor';
  static const String moshafDarkBackgroundColor = 'moshafDarkBackgroundColor';
  static const String moshafMemorizedPages = 'moshafMemorizedPages';
  static const String moshafMemorizedAyahs = 'moshafMemorizedAyahs';
  static const String prayerDate = 'prayerDate';
  static const String prayerFajr = 'prayerFajr';
  static const String prayerDhuhr = 'prayerDhuhr';
  static const String prayerAsr = 'prayerAsr';
  static const String prayerMaghrib = 'prayerMaghrib';
  static const String prayerIsha = 'prayerIsha';
  static const String cachedTimeResponse = 'cachedTimeResponse';
  static const String cachedUpcomingPrayerDays = 'cachedUpcomingPrayerDays';
  // Read by Android (AdhanScheduler.kt) as "flutter.adhanSchedule".
  static const String adhanSchedule = 'adhanSchedule';
  static const String userLatitude = 'userLatitude';
  static const String userLongitude = 'userLongitude';
  static const String userCity = 'userCity';
  static const String userCountry = 'userCountry';
  static const String userCountryCode = 'userCountryCode';
  static const String downloadedQuranAudio = 'downloadedQuranAudio';
  static const String favoriteRadioIds = 'favoriteRadioIds';
  static const String favoriteReciterIds = 'favoriteReciterIds';
  static const String favoriteHadithIds = 'favoriteHadithIds';
  static const String favoriteAzkarCategories = 'favoriteAzkarCategories';
  static const String tasbihRoundCounts = 'tasbihRoundCounts';
  static const String tasbihTotalCounts = 'tasbihTotalCounts';
  static const String tasbihActiveIndex = 'tasbihActiveIndex';
  // Saved text of each search field.
  static const String radioSearch = 'radioSearch';
  static const String reciterSearch = 'reciterSearch';
  static const String reciterSuraSearch = 'reciterSuraSearch';
  static const String sermonSearch = 'sermonSearch';
  static const String sharawyCategorySearch = 'sharawyCategorySearch';
  static const String sharawyPillarSearch = 'sharawyPillarSearch';
  static const String sharawySectionSearch = 'sharawySectionSearch';
  static const String sharawyLectureSearch = 'sharawyLectureSearch';
  static const String hadithSearch = 'hadithSearch';
  static const String azkarSearch = 'azkarSearch';
  static const String downloadsReciterSearch = 'downloadsReciterSearch';
  static const String downloadsSuraSearch = 'downloadsSuraSearch';
  static const String moshafIndexSurahSearch = 'moshafIndexSurahSearch';
}

/// Returns the saved text of the search field stored under [key] ('' when none).
Future<String> getSearchText(String key) async {
  final pref = await SharedPreferences.getInstance();
  return pref.getString(key) ?? '';
}

/// Saves the text of the search field stored under [key].
/// Empty text removes the saved value, so the list shows unfiltered.
Future<void> saveSearchText(String key, String text) async {
  final pref = await SharedPreferences.getInstance();
  if (text.isEmpty) {
    await pref.remove(key);
  } else {
    await pref.setString(key, text);
  }
}

/// Re-reads values written by another isolate (background alarm / download task).
Future<void> reloadPreferences() async {
  final pref = await SharedPreferences.getInstance();
  await pref.reload();
}

/// Saves the Adhan alarm list (JSON) that Android schedules natively.
Future<void> saveAdhanSchedule(String scheduleJson) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setString(SharedPreferencesKay.adhanSchedule, scheduleJson);
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

/// Saves the page the user was on when leaving the Mushaf (auto-saved).
Future<void> saveMoshafLastReadPage(int page) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setInt(SharedPreferencesKay.moshafLastReadPage, page);
}

/// Returns the last page the user was reading, or null if none exists.
Future<int?> getMoshafLastReadPage() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getInt(SharedPreferencesKay.moshafLastReadPage);
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

/// Returns the Mushaf color saved under [key], or [defaultColor] when unset.
Future<Color> getMoshafColor(String key, Color defaultColor) async {
  final pref = await SharedPreferences.getInstance();
  final int? savedValue = pref.getInt(key);
  if (savedValue == null) return defaultColor;
  return Color(savedValue);
}

/// Saves a Mushaf color (page text or background) under [key].
Future<void> saveMoshafColor(String key, Color color) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setInt(key, color.toARGB32());
}

/// Removes the saved Mushaf color under [key], so the default is used again.
Future<void> clearMoshafColor(String key) async {
  final pref = await SharedPreferences.getInstance();
  await pref.remove(key);
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

/// Returns favorite radio ids, newest first (empty when none saved).
Future<List<int>> getFavoriteRadioIds() async {
  return _getIdList(SharedPreferencesKay.favoriteRadioIds);
}

/// Saves favorite radio ids, newest first.
Future<void> saveFavoriteRadioIds(List<int> ids) async {
  await _saveIdList(SharedPreferencesKay.favoriteRadioIds, ids);
}

/// Returns favorite reciter ids, newest first (empty when none saved).
Future<List<int>> getFavoriteReciterIds() async {
  return _getIdList(SharedPreferencesKay.favoriteReciterIds);
}

/// Saves favorite reciter ids, newest first.
Future<void> saveFavoriteReciterIds(List<int> ids) async {
  await _saveIdList(SharedPreferencesKay.favoriteReciterIds, ids);
}

/// Returns favorite hadith ids, newest first (empty when none saved).
Future<List<int>> getFavoriteHadithIds() async {
  return _getIdList(SharedPreferencesKay.favoriteHadithIds);
}

/// Saves favorite hadith ids, newest first.
Future<void> saveFavoriteHadithIds(List<int> ids) async {
  await _saveIdList(SharedPreferencesKay.favoriteHadithIds, ids);
}

/// Returns favorite azkar category titles, newest first (empty when none saved).
Future<List<String>> getFavoriteAzkarCategories() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getStringList(SharedPreferencesKay.favoriteAzkarCategories) ?? [];
}

/// Saves favorite azkar category titles, newest first.
Future<void> saveFavoriteAzkarCategories(List<String> titles) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setStringList(SharedPreferencesKay.favoriteAzkarCategories, titles);
}

/// Returns the current-round count of each sebha zikr (empty when none saved).
Future<List<int>> getTasbihRoundCounts() async {
  return _getIdList(SharedPreferencesKay.tasbihRoundCounts);
}

/// Returns the total count of each sebha zikr (empty when none saved).
Future<List<int>> getTasbihTotalCounts() async {
  return _getIdList(SharedPreferencesKay.tasbihTotalCounts);
}

/// Returns the index of the selected sebha zikr. Defaults to 0.
Future<int> getTasbihActiveIndex() async {
  final pref = await SharedPreferences.getInstance();
  return pref.getInt(SharedPreferencesKay.tasbihActiveIndex) ?? 0;
}

/// Saves the sebha counters and the selected zikr index.
Future<void> saveTasbihProgress({
  required List<int> roundCounts,
  required List<int> totalCounts,
  required int activeIndex,
}) async {
  final pref = await SharedPreferences.getInstance();
  await _saveIdList(SharedPreferencesKay.tasbihRoundCounts, roundCounts);
  await _saveIdList(SharedPreferencesKay.tasbihTotalCounts, totalCounts);
  await pref.setInt(SharedPreferencesKay.tasbihActiveIndex, activeIndex);
}

/// Reads a list of ids saved as strings under [key].
Future<List<int>> _getIdList(String key) async {
  final pref = await SharedPreferences.getInstance();
  final saved = pref.getStringList(key) ?? [];
  return saved.map(int.parse).toList();
}

/// Saves a list of ids as strings under [key], keeping their order.
Future<void> _saveIdList(String key, List<int> ids) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setStringList(key, ids.map((id) => id.toString()).toList());
}

/// Saves the user's coordinates and place names locally.
Future<void> saveUserLocation(UserLocation location) async {
  final pref = await SharedPreferences.getInstance();
  await pref.setDouble(SharedPreferencesKay.userLatitude, location.latitude);
  await pref.setDouble(SharedPreferencesKay.userLongitude, location.longitude);
  await pref.setString(SharedPreferencesKay.userCity, location.city);
  await pref.setString(SharedPreferencesKay.userCountry, location.country);
  await pref.setString(
    SharedPreferencesKay.userCountryCode,
    location.countryCode,
  );
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
    countryCode: pref.getString(SharedPreferencesKay.userCountryCode) ?? '',
  );
}
