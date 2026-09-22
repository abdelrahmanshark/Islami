/// Single sermon entry from assets/data/sermons.json.
class Sermon {
  Sermon({
    required this.titleEn,
    required this.titleAr,
    required this.audioUrl,
  });

  /// Builds a sermon from one JSON object.
  Sermon.fromJson(Map<String, dynamic> json)
      : titleEn = json['titleEn'] as String? ?? '',
        titleAr = json['titleAr'] as String? ?? '',
        audioUrl = json['audioUrl'] as String? ?? '';

  final String titleEn;
  final String titleAr;
  final String audioUrl;
}
