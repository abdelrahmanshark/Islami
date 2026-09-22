/// Single lecture (audio) inside a Sharawy lectures section.
class SharawyLecturesLecture {
  SharawyLecturesLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  SharawyLecturesLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of Sharawy lectures and sermons.
class SharawyLecturesSection {
  SharawyLecturesSection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  SharawyLecturesSection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<SharawyLecturesLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<SharawyLecturesLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) =>
              SharawyLecturesLecture.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

/// Root model for assets/json/sharawe/sharawy_lectures.json.
class SharawyLectures {
  SharawyLectures({
    required this.category,
    required this.sections,
  });

  /// Builds the full Sharawy lectures response from JSON.
  SharawyLectures.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String category;
  final List<SharawyLecturesSection> sections;

  /// Converts a JSON list into section models.
  static List<SharawyLecturesSection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) =>
              SharawyLecturesSection.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
