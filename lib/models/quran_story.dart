/// Single lecture (story audio) inside a Quran stories section.
class QuranStoryLecture {
  QuranStoryLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  QuranStoryLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of Quran stories (e.g. رجال في القران).
class QuranStorySection {
  QuranStorySection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  QuranStorySection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<QuranStoryLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<QuranStoryLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map((item) => QuranStoryLecture.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// Root model for assets/json/sharawe/quran_storys.json.
class QuranStories {
  QuranStories({
    required this.category,
    required this.sections,
  });

  /// Builds the full Quran stories response from JSON.
  QuranStories.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String category;
  final List<QuranStorySection> sections;

  /// Converts a JSON list into section models.
  static List<QuranStorySection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map((item) => QuranStorySection.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
