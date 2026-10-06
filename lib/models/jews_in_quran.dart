/// Single lecture (audio) inside a Jews in Quran section.
class JewsInQuranLecture {
  JewsInQuranLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  JewsInQuranLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of Jews in Quran (e.g. نعم الله على اليهود).
class JewsInQuranSection {
  JewsInQuranSection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  JewsInQuranSection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<JewsInQuranLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<JewsInQuranLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => JewsInQuranLecture.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

/// Root model for assets/json/sharawe/jews_in_quran.json.
class JewsInQuran {
  JewsInQuran({
    required this.category,
    required this.sections,
  });

  /// Builds the full Jews in Quran response from JSON.
  JewsInQuran.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String category;
  final List<JewsInQuranSection> sections;

  /// Converts a JSON list into section models.
  static List<JewsInQuranSection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => JewsInQuranSection.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
