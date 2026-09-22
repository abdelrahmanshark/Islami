import 'package:islami/data/jews_in_quran/jews_in_quran_local_data_source.dart';
import 'package:islami/data/pillars_of_islam/pillars_of_islam_local_data_source.dart';
import 'package:islami/data/prophet_seerah/prophet_seerah_local_data_source.dart';
import 'package:islami/data/quran_stories/quran_stories_local_data_source.dart';
import 'package:islami/data/religion_and_life_program/religion_and_life_program_local_data_source.dart';
import 'package:islami/data/sharawy_lectures/sharawy_lectures_local_data_source.dart';
import 'package:islami/data/stories_of_prophets/stories_of_prophets_local_data_source.dart';
import 'package:islami/data/women_in_islam/women_in_islam_local_data_source.dart';
import 'package:islami/models/jews_in_quran.dart';
import 'package:islami/models/pillars_of_islam.dart';
import 'package:islami/models/prophet_seerah.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/models/religion_and_life_program.dart';
import 'package:islami/models/sharawy_category.dart';
import 'package:islami/models/sharawy_lectures.dart';
import 'package:islami/models/sharawy_pillar.dart';
import 'package:islami/models/stories_of_prophets.dart';
import 'package:islami/models/women_in_islam.dart';

/// Loads Sha'rawy categories and their lecture lists from local assets.
class SharawyLocalDataSource {
  SharawyLocalDataSource({
    QuranStoriesLocalDataSource? quranStoriesLocalDataSource,
    ProphetSeerahLocalDataSource? prophetSeerahLocalDataSource,
    WomenInIslamLocalDataSource? womenInIslamLocalDataSource,
    ReligionAndLifeProgramLocalDataSource?
        religionAndLifeProgramLocalDataSource,
    SharawyLecturesLocalDataSource? sharawyLecturesLocalDataSource,
    PillarsOfIslamLocalDataSource? pillarsOfIslamLocalDataSource,
    JewsInQuranLocalDataSource? jewsInQuranLocalDataSource,
    StoriesOfProphetsLocalDataSource? storiesOfProphetsLocalDataSource,
  })  : _quranStoriesLocalDataSource =
            quranStoriesLocalDataSource ?? QuranStoriesLocalDataSource(),
        _prophetSeerahLocalDataSource =
            prophetSeerahLocalDataSource ?? ProphetSeerahLocalDataSource(),
        _womenInIslamLocalDataSource =
            womenInIslamLocalDataSource ?? WomenInIslamLocalDataSource(),
        _religionAndLifeProgramLocalDataSource =
            religionAndLifeProgramLocalDataSource ??
                ReligionAndLifeProgramLocalDataSource(),
        _sharawyLecturesLocalDataSource =
            sharawyLecturesLocalDataSource ?? SharawyLecturesLocalDataSource(),
        _pillarsOfIslamLocalDataSource =
            pillarsOfIslamLocalDataSource ?? PillarsOfIslamLocalDataSource(),
        _jewsInQuranLocalDataSource =
            jewsInQuranLocalDataSource ?? JewsInQuranLocalDataSource(),
        _storiesOfProphetsLocalDataSource =
            storiesOfProphetsLocalDataSource ??
                StoriesOfProphetsLocalDataSource();

  final QuranStoriesLocalDataSource _quranStoriesLocalDataSource;
  final ProphetSeerahLocalDataSource _prophetSeerahLocalDataSource;
  final WomenInIslamLocalDataSource _womenInIslamLocalDataSource;
  final ReligionAndLifeProgramLocalDataSource
      _religionAndLifeProgramLocalDataSource;
  final SharawyLecturesLocalDataSource _sharawyLecturesLocalDataSource;
  final PillarsOfIslamLocalDataSource _pillarsOfIslamLocalDataSource;
  final JewsInQuranLocalDataSource _jewsInQuranLocalDataSource;
  final StoriesOfProphetsLocalDataSource _storiesOfProphetsLocalDataSource;

  static const String quranStoryCategoryId = 'quran_story';
  static const String prophetSeerahCategoryId = 'prophet_seerah';
  static const String womenInIslamCategoryId = 'women_in_islam';
  static const String religionAndLifeProgramCategoryId =
      'religion_and_life_program';
  static const String sharawyLecturesCategoryId = 'sharawy_lectures';
  static const String pillarsOfIslamCategoryId = 'pillars_of_islam';
  static const String jewsInQuranCategoryId = 'jews_in_quran';
  static const String storiesOfProphetsCategoryId = 'stories_of_prophets';

  /// Returns the available Sha'rawy categories (more will be added later).
  List<SharawyCategory> fetchCategories() {
    return [
      SharawyCategory(
        id: quranStoryCategoryId,
        titleAr: 'قصص القران',
      ),
      SharawyCategory(
        id: prophetSeerahCategoryId,
        titleAr: 'السيرة النبوية',
      ),
      SharawyCategory(
        id: womenInIslamCategoryId,
        titleAr: 'النساء في الاسلام',
      ),
      SharawyCategory(
        id: religionAndLifeProgramCategoryId,
        titleAr: 'برنامج الدين والحياة',
      ),
      SharawyCategory(
        id: sharawyLecturesCategoryId,
        titleAr: 'محاضرات وخطب',
      ),
      SharawyCategory(
        id: pillarsOfIslamCategoryId,
        titleAr: 'اركان الاسلام',
      ),
      SharawyCategory(
        id: jewsInQuranCategoryId,
        titleAr: 'اليهود في القران',
      ),
      SharawyCategory(
        id: storiesOfProphetsCategoryId,
        titleAr: 'قصص الأنبياء',
      ),
    ];
  }

  /// Loads sections for the given category id (e.g. رجال في القران).
  Future<List<QuranStorySection>> fetchSections(String categoryId) async {
    if (categoryId == quranStoryCategoryId) {
      final stories = await _quranStoriesLocalDataSource.fetchQuranStories();
      return stories.sections;
    }
    if (categoryId == prophetSeerahCategoryId) {
      final seerah = await _prophetSeerahLocalDataSource.fetchProphetSeerah();
      return _mapProphetSections(seerah.sections);
    }
    if (categoryId == womenInIslamCategoryId) {
      final womenInIslam =
          await _womenInIslamLocalDataSource.fetchWomenInIslam();
      return _mapWomenInIslamSections(womenInIslam.sections);
    }
    if (categoryId == religionAndLifeProgramCategoryId) {
      final program = await _religionAndLifeProgramLocalDataSource
          .fetchReligionAndLifeProgram();
      return _mapReligionAndLifeProgramSections(program.sections);
    }
    if (categoryId == sharawyLecturesCategoryId) {
      final lectures =
          await _sharawyLecturesLocalDataSource.fetchSharawyLectures();
      return _mapSharawyLecturesSections(lectures.sections);
    }
    // Pillars of Islam uses fetchPillars() (pillars → sections → lectures).
    if (categoryId == pillarsOfIslamCategoryId) {
      return [];
    }
    if (categoryId == jewsInQuranCategoryId) {
      final jewsInQuran =
          await _jewsInQuranLocalDataSource.fetchJewsInQuran();
      return _mapJewsInQuranSections(jewsInQuran.sections);
    }
    if (categoryId == storiesOfProphetsCategoryId) {
      final stories =
          await _storiesOfProphetsLocalDataSource.fetchStoriesOfProphets();
      return _mapStoriesOfProphetsSections(stories.sections);
    }
    return [];
  }

  /// Maps prophet seerah sections to the shared Sharawy section model used by UI.
  List<QuranStorySection> _mapProphetSections(
    List<ProphetSeerahSection> sections,
  ) {
    return sections
        .map(
          (section) => QuranStorySection(
            title: section.title,
            lectures: section.lectures
                .map(
                  (lecture) => QuranStoryLecture(
                    title: lecture.title,
                    mp3Url: lecture.mp3Url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Maps women in Islam sections to the shared Sharawy section model used by UI.
  List<QuranStorySection> _mapWomenInIslamSections(
    List<WomenInIslamSection> sections,
  ) {
    return sections
        .map(
          (section) => QuranStorySection(
            title: section.title,
            lectures: section.lectures
                .map(
                  (lecture) => QuranStoryLecture(
                    title: lecture.title,
                    mp3Url: lecture.mp3Url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Maps religion and life program sections to the shared Sharawy section model.
  List<QuranStorySection> _mapReligionAndLifeProgramSections(
    List<ReligionAndLifeProgramSection> sections,
  ) {
    return sections
        .map(
          (section) => QuranStorySection(
            title: section.title,
            lectures: section.lectures
                .map(
                  (lecture) => QuranStoryLecture(
                    title: lecture.title,
                    mp3Url: lecture.mp3Url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Maps Sharawy lectures sections to the shared Sharawy section model used by UI.
  List<QuranStorySection> _mapSharawyLecturesSections(
    List<SharawyLecturesSection> sections,
  ) {
    return sections
        .map(
          (section) => QuranStorySection(
            title: section.title,
            lectures: section.lectures
                .map(
                  (lecture) => QuranStoryLecture(
                    title: lecture.title,
                    mp3Url: lecture.mp3Url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Whether this category uses pillars → sections → lectures navigation.
  bool categoryHasPillars(String categoryId) {
    return categoryId == pillarsOfIslamCategoryId;
  }

  /// Loads pillars for categories that use the extra hierarchy level.
  Future<List<SharawyPillar>> fetchPillars(String categoryId) async {
    if (categoryId == pillarsOfIslamCategoryId) {
      final pillars =
          await _pillarsOfIslamLocalDataSource.fetchPillarsOfIslam();
      return _mapPillarsOfIslamPillars(pillars.pillars);
    }
    return [];
  }

  /// Maps pillars of Islam to the shared Sharawy pillar presentation model.
  List<SharawyPillar> _mapPillarsOfIslamPillars(
    List<PillarsOfIslamPillar> pillars,
  ) {
    return pillars
        .map(
          (pillar) => SharawyPillar(
            title: pillar.title,
            sections: _mapPillarsOfIslamSections(pillar.sections),
          ),
        )
        .toList();
  }

  /// Maps pillars of Islam sections to the shared Sharawy section model used by UI.
  List<QuranStorySection> _mapPillarsOfIslamSections(
    List<PillarsOfIslamSection> sections,
  ) {
    return sections
        .map(
          (section) => QuranStorySection(
            title: section.title,
            lectures: section.lectures
                .map(
                  (lecture) => QuranStoryLecture(
                    title: lecture.title,
                    mp3Url: lecture.mp3Url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Maps Jews in Quran sections to the shared Sharawy section model used by UI.
  List<QuranStorySection> _mapJewsInQuranSections(
    List<JewsInQuranSection> sections,
  ) {
    return sections
        .map(
          (section) => QuranStorySection(
            title: section.title,
            lectures: section.lectures
                .map(
                  (lecture) => QuranStoryLecture(
                    title: lecture.title,
                    mp3Url: lecture.mp3Url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  /// Maps stories of prophets sections to the shared Sharawy section model.
  List<QuranStorySection> _mapStoriesOfProphetsSections(
    List<StoriesOfProphetsSection> sections,
  ) {
    return sections
        .map(
          (section) => QuranStorySection(
            title: section.title,
            lectures: section.lectures
                .map(
                  (lecture) => QuranStoryLecture(
                    title: lecture.title,
                    mp3Url: lecture.mp3Url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }
}
