/// Single lecture (audio) inside a women in Islam section.
class WomenInIslamLecture {
  WomenInIslamLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  WomenInIslamLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of women in Islam lectures.
class WomenInIslamSection {
  WomenInIslamSection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  WomenInIslamSection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<WomenInIslamLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<WomenInIslamLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => WomenInIslamLecture.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

/// Root model for assets/json/sharawe/wemen_in_islam.json.
class WomenInIslam {
  WomenInIslam({
    required this.category,
    required this.sections,
  });

  /// Builds the full women in Islam response from JSON.
  WomenInIslam.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String category;
  final List<WomenInIslamSection> sections;

  /// Converts a JSON list into section models.
  static List<WomenInIslamSection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => WomenInIslamSection.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
