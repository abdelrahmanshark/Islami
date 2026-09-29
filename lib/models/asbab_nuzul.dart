/// One reason of revelation (سبب النزول) from a single source.
class AsbabReason {
  static const String wahidiSource = 'الواحدي';

  final String source;
  final String text;

  const AsbabReason({
    required this.source,
    required this.text,
  });

  factory AsbabReason.fromJson(Map<String, dynamic> json) {
    return AsbabReason(
      source: json['source'] as String? ?? '',
      text: _htmlToPlainText(json['text'] as String? ?? ''),
    );
  }

  /// Converts the HTML text stored in asbab.json into readable plain text.
  static String _htmlToPlainText(String html) {
    return html
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'<br\s*/?>\n?'), '\n')
        .replaceAll(RegExp(r'</(p|tr|div|table)>'), '\n')
        .replaceAll('</td>', ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

/// A group of ayahs in one surah that share the same reasons of revelation.
class AsbabEntry {
  final int surah;
  final List<int> ayahs;
  final List<AsbabReason> reasons;

  const AsbabEntry({
    required this.surah,
    required this.ayahs,
    required this.reasons,
  });

  factory AsbabEntry.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'] as List<dynamic>? ?? [];
    final rawReasons = json['reasons'] as List<dynamic>? ?? [];
    return AsbabEntry(
      surah: json['surah'] as int,
      ayahs: rawAyahs.map((e) => e as int).toList(),
      reasons: rawReasons
          .map((e) => AsbabReason.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
