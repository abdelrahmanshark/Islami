/// One tafsir source entry for an ayah (e.g. التفسير الميسر).
class TafserEntry {
  final String type;
  final String text;

  const TafserEntry({
    required this.type,
    required this.text,
  });

  factory TafserEntry.fromJson(Map<String, dynamic> json) {
    return TafserEntry(
      type: json['type'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

/// One ayah with its Arabic text and tafsir entries.
class TafserAyah {
  final int ayahNumber;
  final String text;
  final List<TafserEntry> tafsir;

  const TafserAyah({
    required this.ayahNumber,
    required this.text,
    required this.tafsir,
  });

  factory TafserAyah.fromJson(Map<String, dynamic> json) {
    final rawTafsir = json['tafsir'] as List<dynamic>? ?? [];
    return TafserAyah(
      ayahNumber: json['ayah_number'] as int,
      text: json['text'] as String? ?? '',
      tafsir: rawTafsir
          .map((e) => TafserEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Full surah tafsir loaded from assets/json/tafser.
class TafserSurah {
  final String surah;
  final int number;
  final List<TafserAyah> ayahs;

  const TafserSurah({
    required this.surah,
    required this.number,
    required this.ayahs,
  });

  factory TafserSurah.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'] as List<dynamic>? ?? [];
    return TafserSurah(
      surah: json['surah'] as String? ?? '',
      number: json['number'] as int,
      ayahs: rawAyahs
          .map((e) => TafserAyah.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns the ayah with [ayahNumber], or null if missing.
  TafserAyah? ayahByNumber(int ayahNumber) {
    for (final ayah in ayahs) {
      if (ayah.ayahNumber == ayahNumber) return ayah;
    }
    return null;
  }
}
