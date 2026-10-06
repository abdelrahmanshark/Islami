import 'package:islami/models/quran_story.dart';

/// Presentation model for a Sha'rawy pillar (used by pillars-of-Islam UI).
class SharawyPillar {
  SharawyPillar({
    required this.title,
    required this.sections,
  });

  /// Arabic pillar name (e.g. الشهادتان).
  final String title;

  /// Sections under this pillar, using the shared section/lecture models.
  final List<QuranStorySection> sections;
}
