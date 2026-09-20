class AppAssets {
  static const String hadithCard = 'assets/images/hadith_card.png';
  static const String detailsBg = 'assets/images/details_bg.png';
  static const String header = 'assets/images/header.png';
  static const String quranMR = 'assets/images/quran_mostrec.png';
  static const String hadithBg = 'assets/images/hadith_bg.png';
  static const String quranBg = 'assets/images/quran_bg.png';
  static const String radioBg = 'assets/images/radio_bg.png';
  static const String sebhaBg = 'assets/images/sebha_bg.png';
  static const String timeBg = 'assets/images/time_bg.png';
  static const String hadithIc = 'assets/icons/hadith_ic.svg';
  static const String quranIc = 'assets/icons/quran_ic.svg';
  static const String radioIc = 'assets/icons/radio_ic.svg';
  static const String sebhaIc = 'assets/icons/sebha_ic.svg';
  static const String timeIc = 'assets/icons/time_ic.svg';
  static const String suraNumVector = 'assets/icons/sura_num_vector.svg';
  static const String sebhaBody = "assets/images/sebha_body.png";
  static const String sebhaTitle = "assets/images/sebha_title.png";
  static const String inActiveRadioCard =
      "assets/images/inactive_radio_card.png";
  static const String activeRadioCard = "assets/images/active_radio_card.png";
  static const String prayTimeBg = "assets/images/pray_time_bg.png";
  static const String azan = 'assets/audio/azan.mp3';
  static const String azkarJson = 'assets/json/azkar.json';
  static const String quranJson = 'assets/json/quran.json';
  static const String quranWithJuzHizbRubJson =
      'assets/json/quran_with_juz_hizb_rub.json';
  static const String quranImagesFolder = 'assets/quran_images';
  static const String quranImagesDarkFolder = 'assets/quran_images_dark';
  static const String morningAzkar = 'assets/images/morning_azkar.png';
  static const String eveningAzkar = 'assets/images/evening_azkar.png';

  /// Returns the asset path for Quran page [pageNumber] (1–604).
  static String quranPageImage(int pageNumber, {bool isDark = false}) {
    final padded = pageNumber.toString().padLeft(3, '0');
    final folder = isDark ? quranImagesDarkFolder : quranImagesFolder;
    return '$folder/$padded.webp';
  }
}
