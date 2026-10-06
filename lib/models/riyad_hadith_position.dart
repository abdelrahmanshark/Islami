import 'package:islami/models/riyad_assalihin.dart';

/// Where a hadith sits inside its chapter.
/// Used for the favorites list and to open a chapter at a specific hadith.
class RiyadHadithPosition {
  RiyadHadithPosition({required this.chapter, required this.hadithIndex});

  final RiyadChapterModel chapter;
  final int hadithIndex;

  /// The hadith at [hadithIndex] inside [chapter].
  RiyadHadithModel get hadith => chapter.hadiths[hadithIndex];
}
