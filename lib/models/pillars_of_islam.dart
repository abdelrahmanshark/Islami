/// Single lecture (audio) inside a pillars of Islam section.
class PillarsOfIslamLecture {
  PillarsOfIslamLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  PillarsOfIslamLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of lectures under a pillar.
class PillarsOfIslamSection {
  PillarsOfIslamSection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  PillarsOfIslamSection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<PillarsOfIslamLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<PillarsOfIslamLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) =>
              PillarsOfIslamLecture.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

/// One of the five pillars (e.g. الشهادتان) with its sections.
class PillarsOfIslamPillar {
  PillarsOfIslamPillar({
    required this.title,
    required this.sections,
  });

  /// Builds a pillar with its sections list from JSON.
  PillarsOfIslamPillar.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String title;
  final List<PillarsOfIslamSection> sections;

  /// Converts a JSON list into section models.
  static List<PillarsOfIslamSection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) =>
              PillarsOfIslamSection.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}

/// Root model for assets/json/sharawe/pillars_of_islam.json.
class PillarsOfIslam {
  PillarsOfIslam({
    required this.category,
    required this.pillars,
  });

  /// Builds the full pillars of Islam response from JSON.
  PillarsOfIslam.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        pillars = _parsePillars(json['pillars']);

  final String category;
  final List<PillarsOfIslamPillar> pillars;

  /// Converts a JSON list into pillar models.
  static List<PillarsOfIslamPillar> _parsePillars(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) =>
              PillarsOfIslamPillar.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
