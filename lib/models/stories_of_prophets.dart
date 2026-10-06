/// Single lecture (audio) inside a stories of prophets section.
class StoriesOfProphetsLecture {
  StoriesOfProphetsLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  StoriesOfProphetsLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of stories of prophets (e.g. قصة سيدنا ادم عليه السلام).
class StoriesOfProphetsSection {
  StoriesOfProphetsSection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  StoriesOfProphetsSection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<StoriesOfProphetsLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<StoriesOfProphetsLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) =>
              StoriesOfProphetsLecture.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

/// Root model for assets/json/sharawe/storys_of_phrophets.json.
class StoriesOfProphets {
  StoriesOfProphets({
    required this.category,
    required this.sections,
  });

  /// Builds the full stories of prophets response from JSON.
  StoriesOfProphets.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String category;
  final List<StoriesOfProphetsSection> sections;

  /// Converts a JSON list into section models.
  static List<StoriesOfProphetsSection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) =>
              StoriesOfProphetsSection.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
