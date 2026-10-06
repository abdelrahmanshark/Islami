/// Single lecture (seerah audio) inside a prophet seerah section.
class ProphetSeerahLecture {
  ProphetSeerahLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  ProphetSeerahLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of prophet seerah (e.g. محمد صلى الله عليه وسلم).
class ProphetSeerahSection {
  ProphetSeerahSection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  ProphetSeerahSection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<ProphetSeerahLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<ProphetSeerahLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => ProphetSeerahLecture.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

/// Root model for assets/json/sharawe/prophet_mohamed.json.
class ProphetSeerah {
  ProphetSeerah({
    required this.category,
    required this.sections,
  });

  /// Builds the full prophet seerah response from JSON.
  ProphetSeerah.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String category;
  final List<ProphetSeerahSection> sections;

  /// Converts a JSON list into section models.
  static List<ProphetSeerahSection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => ProphetSeerahSection.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
