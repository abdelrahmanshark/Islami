/// Single lecture (audio) inside a religion and life program section.
class ReligionAndLifeProgramLecture {
  ReligionAndLifeProgramLecture({
    required this.title,
    required this.mp3Url,
  });

  /// Builds a lecture from one JSON object.
  ReligionAndLifeProgramLecture.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        mp3Url = json['mp3_url'] as String? ?? '';

  final String title;
  final String mp3Url;
}

/// One section of religion and life program lectures.
class ReligionAndLifeProgramSection {
  ReligionAndLifeProgramSection({
    required this.title,
    required this.lectures,
  });

  /// Builds a section with its lectures list from JSON.
  ReligionAndLifeProgramSection.fromJson(Map<String, dynamic> json)
      : title = json['title'] as String? ?? '',
        lectures = _parseLectures(json['lectures']);

  final String title;
  final List<ReligionAndLifeProgramLecture> lectures;

  /// Converts a JSON list into lecture models.
  static List<ReligionAndLifeProgramLecture> _parseLectures(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => ReligionAndLifeProgramLecture.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}

/// Root model for assets/json/sharawe/religion_and_life_program.json.
class ReligionAndLifeProgram {
  ReligionAndLifeProgram({
    required this.category,
    required this.sections,
  });

  /// Builds the full religion and life program response from JSON.
  ReligionAndLifeProgram.fromJson(Map<String, dynamic> json)
      : category = json['category'] as String? ?? '',
        sections = _parseSections(json['sections']);

  final String category;
  final List<ReligionAndLifeProgramSection> sections;

  /// Converts a JSON list into section models.
  static List<ReligionAndLifeProgramSection> _parseSections(dynamic list) {
    if (list == null) return [];
    return (list as List)
        .map(
          (item) => ReligionAndLifeProgramSection.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
