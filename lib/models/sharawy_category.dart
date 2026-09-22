/// One Sha'rawy category shown in the الشعراوي tab.
class SharawyCategory {
  SharawyCategory({
    required this.id,
    required this.titleAr,
  });

  /// Stable id used to load category audios (e.g. quran_story).
  final String id;

  /// Arabic display name (e.g. قصص القران).
  final String titleAr;
}
