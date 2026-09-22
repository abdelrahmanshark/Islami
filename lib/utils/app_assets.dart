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
  static const String sermonsJson = 'assets/data/sermons.json';
  static const String quranStoriesJson =
      'assets/json/sharawe/quran_storys.json';
  static const String prophetSeerahJson =
      'assets/json/sharawe/prophet_mohamed.json';
  static const String womenInIslamJson =
      'assets/json/sharawe/wemen_in_islam.json';
  static const String religionAndLifeProgramJson =
      'assets/json/sharawe/religion_and_life_program.json';
  static const String sharawyLecturesJson =
      'assets/json/sharawe/sharawy_lectures.json';
  static const String pillarsOfIslamJson =
      'assets/json/sharawe/pillars_of_islam.json';
  static const String jewsInQuranJson =
      'assets/json/sharawe/jews_in_quran.json';
  static const String storiesOfProphetsJson =
      'assets/json/sharawe/storys_of_phrophets.json';
  static const String quranJson = 'assets/json/quran.json';

  static const String quranWithJuzHizbRubJson =
      'assets/json/quran_with_juz_hizb_rub.json';
  static const String quranImagesFolder = 'assets/quran_images';
  static const String quranImagesDarkFolder = 'assets/quran_images_dark';
  static const String quranCoordinatesFolder =
      'assets/json/quran_coordinates';
  static const String tafserFolder = 'assets/json/tafser';
  static const String morningAzkar = 'assets/images/morning_azkar.png';
  static const String eveningAzkar = 'assets/images/evening_azkar.png';

  /// Surah tafsir file names ordered by surah number (1–114).
  static const List<String> _tafserFileNames = [
    '001_al-fatiha.json',
    '002_al-baqarah.json',
    '003_aal-e-imran.json',
    '004_an-nisa.json',
    '005_al-maidah.json',
    '006_al-anam.json',
    '007_al-araf.json',
    '008_al-anfal.json',
    '009_at-tawbah.json',
    '010_yunus.json',
    '011_hud.json',
    '012_yusuf.json',
    '013_ar-rad.json',
    '014_ibrahim.json',
    '015_al-hijr.json',
    '016_an-nahl.json',
    '017_al-isra.json',
    '018_al-kahf.json',
    '019_maryam.json',
    '020_ta-ha.json',
    '021_al-anbiya.json',
    '022_al-hajj.json',
    '023_al-muminun.json',
    '024_an-nur.json',
    '025_al-furqan.json',
    '026_ash-shuara.json',
    '027_an-naml.json',
    '028_al-qasas.json',
    '029_al-ankabut.json',
    '030_ar-rum.json',
    '031_luqman.json',
    '032_as-sajdah.json',
    '033_al-ahzab.json',
    '034_saba.json',
    '035_fatir.json',
    '036_ya-sin.json',
    '037_as-saffat.json',
    '038_sad.json',
    '039_az-zumar.json',
    '040_ghafir.json',
    '041_fussilat.json',
    '042_ash-shura.json',
    '043_az-zukhruf.json',
    '044_ad-dukhkhan.json',
    '045_al-jathiya.json',
    '046_al-ahqaf.json',
    '047_muhammad.json',
    '048_al-fath.json',
    '049_al-hujurat.json',
    '050_qaf.json',
    '051_adh-dhariyat.json',
    '052_at-tur.json',
    '053_an-najm.json',
    '054_al-qamar.json',
    '055_ar-rahman.json',
    '056_al-waqiah.json',
    '057_al-hadid.json',
    '058_al-mujadila.json',
    '059_al-hashr.json',
    '060_al-mumtahina.json',
    '061_as-saff.json',
    '062_al-jumua.json',
    '063_al-munafiqoon.json',
    '064_at-taghabun.json',
    '065_at-talaq.json',
    '066_at-tahrim.json',
    '067_al-mulk.json',
    '068_al-qalam.json',
    '069_al-haqqah.json',
    '070_al-maarij.json',
    '071_nooh.json',
    '072_al-jinn.json',
    '073_al-muzzammil.json',
    '074_al-muddathir.json',
    '075_al-qiyamah.json',
    '076_al-insan.json',
    '077_al-mursalat.json',
    '078_an-naba.json',
    '079_an-naziat.json',
    '080_abasa.json',
    '081_at-takwir.json',
    '082_al-infitar.json',
    '083_al-mutaffifin.json',
    '084_al-inshiqaq.json',
    '085_al-buruj.json',
    '086_at-tariq.json',
    '087_al-ala.json',
    '088_al-ghashiyah.json',
    '089_al-fajr.json',
    '090_al-balad.json',
    '091_ash-shams.json',
    '092_al-layl.json',
    '093_ad-duha.json',
    '094_ash-sharh.json',
    '095_at-tin.json',
    '096_al-alaq.json',
    '097_al-qadr.json',
    '098_al-bayyina.json',
    '099_az-zalzalah.json',
    '100_al-adiyat.json',
    '101_al-qariah.json',
    '102_at-takathur.json',
    '103_al-asr.json',
    '104_al-humazah.json',
    '105_al-fil.json',
    '106_quraish.json',
    '107_al-maun.json',
    '108_al-kawthar.json',
    '109_al-kafirun.json',
    '110_an-nasr.json',
    '111_al-masad.json',
    '112_al-ikhlas.json',
    '113_al-falaq.json',
    '114_an-nas.json',
  ];

  /// Returns the asset path for Quran page [pageNumber] (1–604).
  static String quranPageImage(int pageNumber, {bool isDark = false}) {
    final padded = pageNumber.toString().padLeft(3, '0');
    final folder = isDark ? quranImagesDarkFolder : quranImagesFolder;
    return '$folder/$padded.webp';
  }

  /// Returns the ayah-polygon JSON path for Quran page [pageNumber] (1–604).
  static String quranPageCoordinates(int pageNumber) {
    final padded = pageNumber.toString().padLeft(3, '0');
    return '$quranCoordinatesFolder/$padded.json';
  }

  /// Returns the tafsir JSON path for [surahNumber] (1–114).
  static String tafserSurah(int surahNumber) {
    return '$tafserFolder/${_tafserFileNames[surahNumber - 1]}';
  }
}
