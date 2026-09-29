/// Single hadith inside a Riyad Assalihin chapter.
class RiyadHadithModel {
  RiyadHadithModel({
    required this.id,
    required this.text,
  });

  final int id;
  final String text;

  /// Builds a hadith from one JSON object.
  factory RiyadHadithModel.fromJson(Map<String, dynamic> json) {
    return RiyadHadithModel(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
    );
  }

  /// Converts the hadith back to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }
}

/// One chapter of Riyad Assalihin with its hadiths.
class RiyadChapterModel {
  RiyadChapterModel({
    required this.id,
    required this.title,
    required this.hadiths,
  });

  final int id;
  final String title;
  final List<RiyadHadithModel> hadiths;

  /// Builds a chapter and its hadiths list from JSON.
  factory RiyadChapterModel.fromJson(Map<String, dynamic> json) {
    List<RiyadHadithModel> hadiths = [];
    final List<dynamic> hadithsJson = json['hadiths'] as List<dynamic>? ?? [];
    for (final item in hadithsJson) {
      hadiths.add(RiyadHadithModel.fromJson(item as Map<String, dynamic>));
    }

    return RiyadChapterModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      hadiths: hadiths,
    );
  }

  /// Converts the chapter back to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hadiths': hadiths.map((hadith) => hadith.toJson()).toList(),
    };
  }
}

/// Root model for assets/json/riyad_assalihin.json.
class RiyadAssalihinModel {
  RiyadAssalihinModel({required this.chapters});

  final List<RiyadChapterModel> chapters;

  /// Builds the full Riyad Assalihin data from JSON.
  factory RiyadAssalihinModel.fromJson(Map<String, dynamic> json) {
    List<RiyadChapterModel> chapters = [];
    final List<dynamic> chaptersJson = json['chapters'] as List<dynamic>? ?? [];
    for (final item in chaptersJson) {
      chapters.add(RiyadChapterModel.fromJson(item as Map<String, dynamic>));
    }

    return RiyadAssalihinModel(chapters: chapters);
  }

  /// Converts the full data back to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }
}
