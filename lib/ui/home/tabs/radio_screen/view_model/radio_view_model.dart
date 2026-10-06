import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/data/sermons/sermons_local_data_source.dart';
import 'package:islami/data/sharawy/sharawy_local_data_source.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/radio_repository.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/models/radio_response.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/models/sermon.dart';
import 'package:islami/models/sharawy_category.dart';
import 'package:islami/models/sharawy_pillar.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/utils/app_animations.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/network_utils.dart';
import 'package:islami/utils/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

@injectable
class RadioViewModel extends ChangeNotifier {
  RadioViewModel(
    this._radioRepository,
    this._sermonsLocalDataSource,
    this._sharawyLocalDataSource,
    this._downloadedAudioRepository,
    this._audioService,
  ) {
    _restorePlaybackState();
    _loadFavorites();
    _loadSearchTexts();
    getRadios();
    getReciters();
    getSermons();
    getSharawyCategories();
    _listenForReciterCompletion();
    _audioService.addListener(_onActiveAudioChanged);
  }

  final RadioRepository _radioRepository;
  final SermonsLocalDataSource _sermonsLocalDataSource;
  final SharawyLocalDataSource _sharawyLocalDataSource;
  final DownloadedAudioRepository _downloadedAudioRepository;
  final AudioPlayerService _audioService;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  List<int> filterSearch = List.generate(114, (index) => index);
  bool radioIsLoading = false;
  bool reciterIsLoading = false;
  bool sermonIsLoading = false;
  bool sharawySectionIsLoading = false;
  List<Radios> radios = [];
  List<Radios> filteredRadios = [];
  List<Reciters> reciters = [];
  List<Reciters> filteredReciters = [];
  List<Sermon> sermons = [];
  List<Sermon> filteredSermons = [];
  List<SharawyCategory> sharawyCategories = [];
  List<SharawyCategory> filteredSharawyCategories = [];
  List<SharawyPillar> sharawyPillars = [];
  List<SharawyPillar> filteredSharawyPillars = [];
  List<QuranStorySection> sharawySections = [];
  List<QuranStorySection> filteredSharawySections = [];
  List<QuranStoryLecture> sharawyLectures = [];
  List<QuranStoryLecture> filteredSharawyLectures = [];
  String radioFailureMsg = '';
  String reciterFailureMsg = '';
  String sermonFailureMsg = '';
  String sharawyFailureMsg = '';
  Radios? selectedRadio;
  Radios? selectedRadioForSound;
  Reciters? selectedReciter;
  Sermon? selectedSermon;
  QuranStoryLecture? selectedSharawyLecture;
  SharawyCategory? selectedSharawyCategory;
  SharawyPillar? selectedSharawyPillar;
  QuranStorySection? selectedSharawySection;
  int? selectedRadioId; // source of truth for playing radio
  int? selectedRadioForSoundId; // source of truth for muted radio
  int? selectedReciterId; // source of truth for playing reciter
  String? selectedSermonAudioUrl; // source of truth for playing sermon
  String? selectedSharawyAudioUrl; // source of truth for playing sha'rawy
  int currentSura = 1;
  late final player = _audioService.player;
  int toggleSwitchIndex = 0;
  bool isRepeatEnabled = false;
  bool isAutoNextEnabled = false;
  bool isReciterPlaying = false; // drives play/pause icon on reciter cards
  // Card whose new audio is still loading (shows a spinner on its play button).
  String? loadingAudioKey;
  // Play request that owns [loadingAudioKey]; only it may clear the spinner.
  int? _loadingRequestId;

  // Favorites are saved ids, newest first, so a new favorite goes to the top.
  List<int> favoriteRadioIds = [];
  List<int> favoriteReciterIds = [];
  static const int allListTabIndex = 0;
  static const int favoritesListTabIndex = 1;
  int radioListTabIndex = allListTabIndex;
  int reciterListTabIndex = allListTabIndex;
  // Text of each search field, saved in SharedPreferences.
  String radioSearchQuery = '';
  String reciterSearchQuery = '';
  String suraSearchQuery = '';
  String sermonSearchQuery = '';
  String sharawyCategorySearchQuery = '';
  String sharawyPillarSearchQuery = '';
  String sharawySectionSearchQuery = '';
  String sharawyLectureSearchQuery = '';
  // Cards shrinking away before moving to their new place in the list.
  Set<int> leavingRadioIds = {};
  Set<int> leavingReciterIds = {};
  // Card that grows in at its new place right after moving.
  int? enteringRadioId;
  int? enteringReciterId;

  // Where the playing Sha'rawy lecture lives, so the mini player can reopen it.
  SharawyCategory? _playingSharawyCategory;
  SharawyPillar? _playingSharawyPillar;
  QuranStorySection? _playingSharawySection;

  // Audio type whose list should scroll to its playing card (mini player tap).
  ActiveAudioType? _pendingScrollType;

  // Restore ids from the singleton so UI survives leaving the Radio tab.
  void _restorePlaybackState() {
    // A playing download also uses selectedReciterId, so skip it here.
    if (_audioService.activeAudioType != ActiveAudioType.download) {
      selectedRadioId = _audioService.selectedRadioId;
      selectedReciterId = _audioService.selectedReciterId;
      selectedSermonAudioUrl = _audioService.selectedSermonAudioUrl;
      selectedSharawyAudioUrl = _audioService.selectedSharawyAudioUrl;
    }
    selectedRadioForSoundId = _audioService.selectedRadioForSoundId;
    currentSura = _audioService.currentSura;
    isRepeatEnabled = _audioService.isRepeatEnabled;
    isAutoNextEnabled = _audioService.isAutoNextEnabled;
    isReciterPlaying =
        selectedReciterId != null && _audioService.player.playing;
  }

  // Tells the shared service which Radio-tab audio is active (drives the mini player).
  void _syncActiveAudioType() {
    ActiveAudioType? type;
    if (selectedRadioId != null) {
      type = ActiveAudioType.radio;
    } else if (selectedReciterId != null) {
      type = ActiveAudioType.reciter;
    } else if (selectedSermonAudioUrl != null) {
      type = ActiveAudioType.sermon;
    } else if (selectedSharawyAudioUrl != null) {
      type = ActiveAudioType.sharawy;
    }
    // Nothing selected here: do not clear a download owned by the Downloads tab.
    if (type == null &&
        _audioService.activeAudioType == ActiveAudioType.download) {
      return;
    }
    _audioService.setActiveAudioType(type);
  }

  // Clears the Radio-tab selection when a downloaded sura starts playing.
  void _onActiveAudioChanged() {
    if (_audioService.activeAudioType != ActiveAudioType.download) return;
    final bool hasSelection = selectedRadioId != null ||
        selectedReciterId != null ||
        selectedSermonAudioUrl != null ||
        selectedSharawyAudioUrl != null;
    if (!hasSelection) return;

    selectedRadio = null;
    selectedRadioId = null;
    selectedReciter = null;
    selectedReciterId = null;
    isReciterPlaying = false;
    selectedSermon = null;
    selectedSermonAudioUrl = null;
    selectedSharawyLecture = null;
    selectedSharawyAudioUrl = null;
    notifyListeners();
  }

  // Persist radio play selection on the singleton.
  void _setSelectedRadio(Radios? radio) {
    selectedRadio = radio;
    selectedRadioId = radio?.id;
    _audioService.selectedRadioId = radio?.id;
    _syncActiveAudioType();
  }

  // Persist mute selection on the singleton.
  void _setSelectedRadioForSound(Radios? radio) {
    selectedRadioForSound = radio;
    selectedRadioForSoundId = radio?.id;
    _audioService.selectedRadioForSoundId = radio?.id;
  }

  // Persist reciter play selection on the singleton.
  void _setSelectedReciter(Reciters? reciter) {
    selectedReciter = reciter;
    selectedReciterId = reciter?.id;
    _audioService.selectedReciterId = reciter?.id;
    if (reciter == null) {
      isReciterPlaying = false;
    }
    _syncActiveAudioType();
  }

  // Persist sermon play selection on the singleton.
  void _setSelectedSermon(Sermon? sermon) {
    selectedSermon = sermon;
    selectedSermonAudioUrl = sermon?.audioUrl;
    _audioService.selectedSermonAudioUrl = sermon?.audioUrl;
    _syncActiveAudioType();
  }

  // Loading keys: one unique key per card so only that card shows a spinner.
  String _radioKey(Radios radio) => 'radio_${radio.id}';
  String _reciterKey(Reciters reciter) => 'reciter_${reciter.id}';
  String _sermonKey(Sermon sermon) => 'sermon_${sermon.audioUrl}';
  String _sharawyKey(QuranStoryLecture lecture) => 'sharawy_${lecture.mp3Url}';

  /// True while [radio]'s audio is loading after a tap.
  bool isRadioLoading(Radios radio) => loadingAudioKey == _radioKey(radio);

  /// True while [reciter]'s audio is loading after a tap.
  bool isReciterLoading(Reciters reciter) =>
      loadingAudioKey == _reciterKey(reciter);

  /// True while [sermon]'s audio is loading after a tap.
  bool isSermonLoading(Sermon sermon) => loadingAudioKey == _sermonKey(sermon);

  /// True while [lecture]'s audio is loading after a tap.
  bool isSharawyLectureLoading(QuranStoryLecture lecture) =>
      loadingAudioKey == _sharawyKey(lecture);

  // Shows the spinner on the card with [key] for play request [requestId].
  void _startLoading(String key, int requestId) {
    loadingAudioKey = key;
    _loadingRequestId = requestId;
    notifyListeners();
  }

  // Hides the spinner, only if [requestId] still owns it
  // (a newer request may have moved the spinner to another card).
  void _finishLoading(int requestId) {
    if (_loadingRequestId != requestId) return;
    _clearLoading();
    notifyListeners();
  }

  // Hides the spinner right away (used by the stop buttons).
  void _clearLoading() {
    loadingAudioKey = null;
    _loadingRequestId = null;
  }

  // Persist sha'rawy play selection on the singleton.
  void _setSelectedSharawyLecture(QuranStoryLecture? lecture) {
    selectedSharawyLecture = lecture;
    selectedSharawyAudioUrl = lecture?.mp3Url;
    _audioService.selectedSharawyAudioUrl = lecture?.mp3Url;
    _syncActiveAudioType();
  }

  /// Called each time the Radio tab is shown: re-reads settings shared with
  /// the Downloads tab. The tab stays alive between switches, so its search
  /// bars and filtered lists are kept as the user left them.
  void onTabOpened() {
    isRepeatEnabled = _audioService.isRepeatEnabled;
    isAutoNextEnabled = _audioService.isAutoNextEnabled;
    notifyListeners();
  }

  /// Arabic name of [currentSura], e.g. "سورة الفاتحة".
  String get currentSuraName {
    if (currentSura < 1 || currentSura > QuranResources.arabicQuranSuras.length) {
      return 'سورة $currentSura';
    }
    return 'سورة ${QuranResources.arabicQuranSuras[currentSura - 1]}';
  }

  /// Title of the selected Radio-tab audio, shown in the mini player.
  String get activeAudioTitle {
    if (selectedRadio != null) {
      return selectedRadio!.name ?? 'راديو';
    }
    if (selectedReciter != null) {
      return '$currentSuraName - ${selectedReciter!.name ?? ''}';
    }
    if (selectedSermon != null) {
      return selectedSermon!.titleAr;
    }
    if (selectedSharawyLecture != null) {
      return selectedSharawyLecture!.title;
    }
    return '';
  }

  /// Opens the Radio-tab segment that holds the active audio (mini player tap),
  /// then asks its list to scroll to the playing card.
  /// Each level is skipped when it is already showing.
  Future<void> showActiveAudio() async {
    final ActiveAudioType? activeType = _audioService.activeAudioType;
    if (activeType == ActiveAudioType.radio) {
      await _openToggleIndex(0);
      // The playing radio may be hidden by the favorites tab.
      if (activeRadioIndex == null) {
        radioListTabIndex = allListTabIndex;
        _updateFilteredRadios();
      }
    } else if (activeType == ActiveAudioType.reciter) {
      resetSuraSearch();
      await _openToggleIndex(1);
    } else if (activeType == ActiveAudioType.sermon) {
      await _openToggleIndex(2);
    } else if (activeType == ActiveAudioType.sharawy) {
      await _openToggleIndex(3);
      await _openPlayingSharawySection();
      // No lectures list to scroll (the playing section is unknown).
      if (selectedSharawySection == null) return;
    } else {
      return;
    }
    _pendingScrollType = activeType;
    notifyListeners();
  }

  // Switches the segment only when needed, then waits until it is built.
  Future<void> _openToggleIndex(int index) async {
    if (toggleSwitchIndex == index) return;
    changeToggleIndex(index);
    await WidgetsBinding.instance.endOfFrame;
  }

  /// True when the list of [type] audio should scroll to its playing card.
  bool shouldScrollToActive(ActiveAudioType type) {
    return _pendingScrollType == type;
  }

  /// Called by the list once it scrolled to the playing card.
  void onScrolledToActive() {
    _pendingScrollType = null;
  }

  /// Index of the playing radio in [filteredRadios] (matched by API id).
  int? get activeRadioIndex {
    if (selectedRadioId == null) return null;
    return _indexOrNull(
      filteredRadios.indexWhere((radio) => radio.id == selectedRadioId),
    );
  }

  /// Index of the playing sermon in [filteredSermons] (matched by audio url).
  int? get activeSermonIndex {
    if (selectedSermonAudioUrl == null) return null;
    return _indexOrNull(
      filteredSermons.indexWhere(
        (sermon) => sermon.audioUrl == selectedSermonAudioUrl,
      ),
    );
  }

  /// Index of the playing lecture in [filteredSharawyLectures] (by mp3 url).
  int? get activeSharawyLectureIndex {
    if (selectedSharawyAudioUrl == null) return null;
    return _indexOrNull(
      filteredSharawyLectures.indexWhere(
        (lecture) => lecture.mp3Url == selectedSharawyAudioUrl,
      ),
    );
  }

  /// Index of the playing sura in [filterSearch] when [reciter] is playing.
  int? activeSuraIndexFor(Reciters reciter) {
    if (selectedReciterId == null || selectedReciterId != reciter.id) {
      return null;
    }
    return _indexOrNull(filterSearch.indexOf(currentSura - 1));
  }

  // indexWhere / indexOf return -1 when not found; use null instead.
  int? _indexOrNull(int index) {
    if (index < 0) return null;
    return index;
  }

  // Reopens category → (pillar) → section of the playing Sha'rawy lecture.
  Future<void> _openPlayingSharawySection() async {
    final SharawyCategory? category = _playingSharawyCategory;
    final QuranStorySection? section = _playingSharawySection;
    if (category == null || section == null) return;
    // Already inside the section that holds the playing lecture.
    final bool isSectionOpen = selectedSharawySection != null &&
        sharawyLectures.any(
          (lecture) => lecture.mp3Url == selectedSharawyAudioUrl,
        );
    if (isSectionOpen) return;

    await openSharawyCategory(category);
    final SharawyPillar? pillar = _playingSharawyPillar;
    if (pillar != null) {
      openSharawyPillar(pillar);
    }
    openSharawySection(section);
  }

  // Persist current sura on the singleton.
  void _setCurrentSura(int sura) {
    currentSura = sura;
    _audioService.currentSura = sura;
  }

  // Called when user picks a sura for the current reciter.
  void updateCurrentSura(int sura) {
    _setCurrentSura(sura);
  }

  // Clears the sura search so the full list of 114 suras shows.
  void resetSuraSearch() {
    suraSearchQuery = '';
    saveSearchText(SharedPreferencesKay.reciterSuraSearch, '');
    _updateSuraSearch();
    notifyListeners();
  }

  // Plays a specific sura with the given reciter (does not toggle pause).
  // Returns false when blocked by a call, or when offline without a local file.
  Future<bool> playReciterSura(Reciters reciter, int suraNumber) async {
    final int requestId = _audioService.startPlayRequest();
    _setCurrentSura(suraNumber);
    return _loadAndPlayReciterSura(
      reciter: reciter,
      suraNumber: suraNumber,
      requestId: requestId,
    );
  }

  /// Loads [suraNumber] of [reciter] and starts it (shared by all reciter
  /// play methods). Returns false on a real failure (call, offline, player
  /// error); returns true when it played or a newer request replaced it.
  Future<bool> _loadAndPlayReciterSura({
    required Reciters reciter,
    required int suraNumber,
    required int requestId,
  }) async {
    _startLoading(_reciterKey(reciter), requestId);
    // TEMP AUDIO DEBUG
    final Stopwatch debugWatch = Stopwatch()..start();
    try {
      if (!await _audioService.ensureCanPlay()) {
        notifyListeners();
        return false;
      }
      final Uri playbackUri = await _resolveReciterPlaybackUri(
        reciter: reciter,
        suraNumber: suraNumber,
      );
      if (!await _canPlayUri(playbackUri)) {
        notifyListeners();
        return false;
      }
      _audioService.debugAudio('reciter req=$requestId pre-load checks took '
          '${debugWatch.elapsedMilliseconds}ms');
      // A newer request or a stop replaced this one: leave the player alone.
      if (_audioService.isStalePlayRequest(requestId)) return true;
      await player.setLoopMode(
        isRepeatEnabled ? LoopMode.one : LoopMode.off,
      );
      final Stopwatch debugLoadWatch = Stopwatch()..start();
      _audioService.debugAudio('reciter req=$requestId setAudioSource start '
          '(playing=${player.playing}, state=${player.processingState.name})');
      await player.setAudioSource(
        _audioService.buildUriAudioSource(
          playbackUri,
          tag: MediaItem(
            id: 'sura_$suraNumber',
            title: 'سورة $suraNumber',
            artist: reciter.name ?? 'قارئ',
          ),
        ),
      );
      _audioService.debugAudio('reciter req=$requestId setAudioSource end '
          'after ${debugLoadWatch.elapsedMilliseconds}ms '
          '(total ${debugWatch.elapsedMilliseconds}ms, '
          'playing=${player.playing})');
      if (_audioService.isStalePlayRequest(requestId)) return true;
      await _audioService.applyPlaybackSpeed();
      // Update selection before play so the card UI refreshes immediately.
      _setCurrentSura(suraNumber);
      _setSelectedRadio(null);
      _setSelectedSermon(null);
      _setSelectedSharawyLecture(null);
      _setSelectedReciter(reciter);
      final bool started = await _audioService.play();
      if (_audioService.isStalePlayRequest(requestId)) return true;
      isReciterPlaying = started;
      notifyListeners();
      _audioService.debugAudio('reciter req=$requestId done, started=$started '
          'total ${debugWatch.elapsedMilliseconds}ms');
      return started;
    } on PlayerInterruptedException catch (e) {
      _audioService.debugAudio('reciter req=$requestId '
          'PlayerInterruptedException after '
          '${debugWatch.elapsedMilliseconds}ms: ${e.message}');
      // Loading was replaced by a newer audio or a stop: not a failure.
      notifyListeners();
      return true;
    } catch (e) {
      return _handlePlayError(e, requestId);
    } finally {
      _finishLoading(requestId);
    }
  }

  /// Handles an unexpected play error for [requestId].
  /// Returns true (no failure shown) when a newer request already replaced
  /// this one; otherwise marks a real player failure and returns false.
  bool _handlePlayError(Object error, int requestId) {
    log(error.toString());
    _audioService.debugAudio('req=$requestId play ERROR: $error');
    notifyListeners();
    if (_audioService.isStalePlayRequest(requestId)) {
      return true;
    }
    _audioService.markPlaybackFailed();
    return false;
  }

  void changeToggleIndex(int index) {
    toggleSwitchIndex = index;
    notifyListeners();
  }

  TextStyle switcherTextStyle(int index) {
    if (toggleSwitchIndex == index) {
      return AppStyles.blackBold18.copyWith(fontSize: 17);
    } else {
      return AppStyles.whiteBold16;
    }
  }

  // Re-bind selected radio objects to the new API list by id.
  void _syncSelectedRadiosFromList() {
    if (selectedRadioId != null) {
      for (final radio in radios) {
        if (radio.id == selectedRadioId) {
          selectedRadio = radio;
          break;
        }
      }
    }
    if (selectedRadioForSoundId != null) {
      for (final radio in radios) {
        if (radio.id == selectedRadioForSoundId) {
          selectedRadioForSound = radio;
          break;
        }
      }
    }
  }

  // Re-bind selected reciter to the new API list by id.
  void _syncSelectedReciterFromList() {
    if (selectedReciterId == null) return;
    for (final reciter in reciters) {
      if (reciter.id == selectedReciterId) {
        selectedReciter = reciter;
        break;
      }
    }
  }

  // Re-bind selected sermon to the local list by audioUrl.
  void _syncSelectedSermonFromList() {
    if (selectedSermonAudioUrl == null) return;
    for (final sermon in sermons) {
      if (sermon.audioUrl == selectedSermonAudioUrl) {
        selectedSermon = sermon;
        break;
      }
    }
  }

  // Re-bind selected sha'rawy lecture to the loaded list by mp3Url.
  void _syncSelectedSharawyLectureFromList() {
    if (selectedSharawyAudioUrl == null) return;
    for (final lecture in sharawyLectures) {
      if (lecture.mp3Url == selectedSharawyAudioUrl) {
        selectedSharawyLecture = lecture;
        break;
      }
    }
  }

  Future<void> getRadios() async {
    radioIsLoading = true;
    radioFailureMsg = '';
    notifyListeners();

    if (!await NetworkUtils.hasInternetConnection()) {
      radioIsLoading = false;
      radioFailureMsg = NetworkUtils.noInternetMessage;
      notifyListeners();
      return;
    }

    try {
      radios = await _radioRepository.getRadios();
      _updateFilteredRadios();
      _syncSelectedRadiosFromList();
      radioIsLoading = false;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      radioIsLoading = false;
      radioFailureMsg = await NetworkUtils.failureMessageFor(e);
      notifyListeners();
    }
  }

  Future<void> getReciters() async {
    reciterIsLoading = true;
    reciterFailureMsg = '';
    notifyListeners();

    if (!await NetworkUtils.hasInternetConnection()) {
      reciterIsLoading = false;
      reciterFailureMsg = NetworkUtils.noInternetMessage;
      notifyListeners();
      return;
    }

    try {
      reciters = await _radioRepository.getReciters();
      _updateFilteredReciters();
      // Rematch restored download folders to real API reciter ids.
      await _downloadedAudioRepository.restoreExistingDownloads(
        knownReciters: reciters,
      );
      _syncSelectedReciterFromList();
      reciterIsLoading = false;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      reciterIsLoading = false;
      reciterFailureMsg = await NetworkUtils.failureMessageFor(e);
      notifyListeners();
    }
  }

  Future<void> getSermons() async {
    sermonIsLoading = true;
    notifyListeners();
    try {
      sermons = await _sermonsLocalDataSource.fetchSermons();
      _updateFilteredSermons();
      _syncSelectedSermonFromList();
      sermonIsLoading = false;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      sermonIsLoading = false;
      sermonFailureMsg = 'حدث خطأ ما';
      notifyListeners();
    }
  }

  // Loads the Sha'rawy category list (static for now).
  void getSharawyCategories() {
    sharawyCategories = _sharawyLocalDataSource.fetchCategories();
    _updateFilteredSharawyCategories();
    sharawyFailureMsg = '';
    notifyListeners();
  }

  /// True when the opened category uses pillars → sections → lectures.
  bool get isSharawyPillarsCategory {
    final categoryId = selectedSharawyCategory?.id;
    if (categoryId == null) return false;
    return _sharawyLocalDataSource.categoryHasPillars(categoryId);
  }

  // Opens a category and loads pillars or sections depending on hierarchy.
  Future<void> openSharawyCategory(SharawyCategory category) async {
    selectedSharawyCategory = category;
    selectedSharawyPillar = null;
    selectedSharawySection = null;
    sharawyPillars = [];
    filteredSharawyPillars = [];
    sharawySections = [];
    filteredSharawySections = [];
    sharawyLectures = [];
    filteredSharawyLectures = [];
    _setSharawyPillarSearch('');
    _setSharawySectionSearch('');
    _setSharawyLectureSearch('');
    sharawySectionIsLoading = true;
    sharawyFailureMsg = '';
    notifyListeners();
    try {
      if (_sharawyLocalDataSource.categoryHasPillars(category.id)) {
        sharawyPillars =
            await _sharawyLocalDataSource.fetchPillars(category.id);
        filteredSharawyPillars = sharawyPillars;
      } else {
        sharawySections =
            await _sharawyLocalDataSource.fetchSections(category.id);
        filteredSharawySections = sharawySections;
      }
      sharawySectionIsLoading = false;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      sharawySectionIsLoading = false;
      sharawyFailureMsg = 'حدث خطأ ما';
      notifyListeners();
    }
  }

  // Returns from pillars/sections list back to categories list.
  void closeSharawyCategory() {
    selectedSharawyCategory = null;
    selectedSharawyPillar = null;
    selectedSharawySection = null;
    sharawyPillars = [];
    filteredSharawyPillars = [];
    sharawySections = [];
    filteredSharawySections = [];
    sharawyLectures = [];
    filteredSharawyLectures = [];
    sharawyFailureMsg = '';
    notifyListeners();
  }

  // Opens a pillar and shows its sections (pillars-of-Islam only).
  void openSharawyPillar(SharawyPillar pillar) {
    selectedSharawyPillar = pillar;
    selectedSharawySection = null;
    sharawySections = pillar.sections;
    filteredSharawySections = sharawySections;
    sharawyLectures = [];
    filteredSharawyLectures = [];
    _setSharawySectionSearch('');
    _setSharawyLectureSearch('');
    notifyListeners();
  }

  // Returns from sections list back to pillars list.
  void closeSharawyPillar() {
    selectedSharawyPillar = null;
    selectedSharawySection = null;
    sharawySections = [];
    filteredSharawySections = [];
    sharawyLectures = [];
    filteredSharawyLectures = [];
    notifyListeners();
  }

  // Opens a section and shows its lectures.
  void openSharawySection(QuranStorySection section) {
    selectedSharawySection = section;
    sharawyLectures = section.lectures;
    filteredSharawyLectures = sharawyLectures;
    _setSharawyLectureSearch('');
    _syncSelectedSharawyLectureFromList();
    notifyListeners();
  }

  // Returns from lectures list back to sections list.
  void closeSharawySection() {
    selectedSharawySection = null;
    sharawyLectures = [];
    filteredSharawyLectures = [];
    notifyListeners();
  }

  // Plays or pauses a Sha'rawy lecture audio (keeps selection on pause).
  // Returns false when blocked by a call, or when offline.
  Future<bool> playSharawyLecture(QuranStoryLecture lecture) async {
    final String key = _sharawyKey(lecture);
    // Ignore repeat taps while this lecture is still loading.
    if (loadingAudioKey == key) return true;
    // While another card is loading, the player holds that audio, so this
    // lecture must be loaded again instead of resumed.
    if (loadingAudioKey == null &&
        selectedSharawyAudioUrl != null &&
        selectedSharawyAudioUrl == lecture.mp3Url) {
      if (player.playing) {
        await player.pause();
        notifyListeners();
        return true;
      }
      if (!await _audioService.ensureOnline()) {
        notifyListeners();
        return false;
      }
      final bool started = await _audioService.play();
      notifyListeners();
      return started;
    }

    final int requestId = _audioService.startPlayRequest();
    _startLoading(key, requestId);
    try {
      if (!await _audioService.ensureCanPlay()) {
        notifyListeners();
        return false;
      }
      if (!await _audioService.ensureOnline()) {
        notifyListeners();
        return false;
      }
      // A newer request or a stop replaced this one: leave the player alone.
      if (_audioService.isStalePlayRequest(requestId)) return true;
      await player.setLoopMode(LoopMode.off);
      await player.setAudioSource(
        _audioService.buildUriAudioSource(
          Uri.parse(lecture.mp3Url),
          tag: MediaItem(
            id: 'sharawy_${lecture.mp3Url}',
            title: lecture.title,
            artist: 'الشعراوي',
          ),
        ),
      );
      if (_audioService.isStalePlayRequest(requestId)) return true;
      await _audioService.applyPlaybackSpeed();
      final bool started = await _audioService.play();
      if (_audioService.isStalePlayRequest(requestId)) return true;
      if (!started) {
        notifyListeners();
        return false;
      }
      _setSelectedRadio(null);
      _setSelectedReciter(null);
      _setSelectedSermon(null);
      _setSelectedSharawyLecture(lecture);
      _playingSharawyCategory = selectedSharawyCategory;
      _playingSharawyPillar = selectedSharawyPillar;
      _playingSharawySection = selectedSharawySection;
      notifyListeners();
      return true;
    } on PlayerInterruptedException {
      // Loading was replaced by a newer audio or a stop: not a failure.
      notifyListeners();
      return true;
    } catch (e) {
      return _handlePlayError(e, requestId);
    } finally {
      _finishLoading(requestId);
    }
  }

  // Seeks the currently playing Sha'rawy lecture to [position].
  Future<void> seekSharawyLecture(Duration position) async {
    await player.seek(position);
  }

  // Stops Sha'rawy audio and clears the current selection.
  Future<void> stopSharawyLecture() async {
    _audioService.cancelPlayRequests();
    _clearLoading();
    await player.stop();
    _setSelectedSharawyLecture(null);
    notifyListeners();
  }

  // Cycles playback speed: 1x → 1.25x → 1.5x → 2x → 1x.
  Future<void> cyclePlaybackSpeed() async {
    await _audioService.cyclePlaybackSpeed();
    notifyListeners();
  }

  // Current speed label for the speed button, e.g. "1.5x".
  String get playbackSpeedLabel => _audioService.playbackSpeedLabel;

  /// Plays or pauses a radio station (keeps selection on pause).
  /// Returns false when blocked by a call, or when offline.
  Future<bool> playRadio(Radios radio) async {
    final String key = _radioKey(radio);
    // TEMP AUDIO DEBUG
    _audioService.debugAudio('playRadio START "${radio.name}" id=${radio.id} '
        '(selectedRadioId=$selectedRadioId, loading=$loadingAudioKey, '
        'playing=${player.playing}, state=${player.processingState.name})');
    // Ignore repeat taps while this radio is still loading.
    if (loadingAudioKey == key) {
      _audioService.debugAudio('playRadio ignored: already loading');
      return true;
    }
    // While another card is loading, the player holds that audio, so this
    // radio must be loaded again instead of resumed.
    if (loadingAudioKey == null &&
        selectedRadioId != null &&
        selectedRadioId == radio.id) {
      if (player.playing) {
        await player.pause();
        notifyListeners();
        return true;
      }
      if (!await _audioService.ensureOnline()) {
        notifyListeners();
        return false;
      }
      final bool started = await _audioService.play();
      notifyListeners();
      return started;
    }

    final int requestId = _audioService.startPlayRequest();
    _startLoading(key, requestId);
    // TEMP AUDIO DEBUG
    final Stopwatch debugWatch = Stopwatch()..start();
    try {
      if (!await _audioService.ensureCanPlay()) {
        notifyListeners();
        return false;
      }
      if (!await _audioService.ensureOnline()) {
        notifyListeners();
        return false;
      }
      _audioService.debugAudio('radio req=$requestId pre-load checks took '
          '${debugWatch.elapsedMilliseconds}ms');
      // A newer request or a stop replaced this one: leave the player alone.
      if (_audioService.isStalePlayRequest(requestId)) {
        return true;
      }
      // Live radio streams all report the same track info (index 0, no
      // duration), so the notification keeps the old title unless the
      // background player is reset before loading the new station.
      if (selectedRadioId != null) {
        final Stopwatch debugStopWatch = Stopwatch()..start();
        await player.stop();
        _audioService.debugAudio('radio req=$requestId player.stop() took '
            '${debugStopWatch.elapsedMilliseconds}ms');
        if (_audioService.isStalePlayRequest(requestId)) {
          return true;
        }
      }
      // Radio should not inherit reciter loop mode or lecture speed.
      await player.setLoopMode(LoopMode.off);
      await player.setSpeed(1.0);
      final Stopwatch debugLoadWatch = Stopwatch()..start();
      _audioService.debugAudio('radio req=$requestId setAudioSource start '
          '(playing=${player.playing}, state=${player.processingState.name})');
      // Notification metadata is the MediaItem tag; just_audio_background
      // pushes it to the notification as part of setAudioSource.
      await player.setAudioSource(
        _audioService.buildUriAudioSource(
          Uri.parse(radio.url ?? ''),
          tag: MediaItem(
            id: 'radio_${radio.id}',
            title: radio.name ?? 'راديو',
            artist: 'Islami',
          ),
        ),
      );
      _audioService.debugAudio('radio req=$requestId setAudioSource end '
          'after ${debugLoadWatch.elapsedMilliseconds}ms '
          '(total ${debugWatch.elapsedMilliseconds}ms, '
          'playing=${player.playing})');
      if (_audioService.isStalePlayRequest(requestId)) {
        return true;
      }
      final bool started = await _audioService.play();
      if (_audioService.isStalePlayRequest(requestId)) {
        return true;
      }
      if (!started) {
        notifyListeners();
        return false;
      }
      _setSelectedReciter(null);
      _setSelectedSermon(null);
      _setSelectedSharawyLecture(null);
      _setSelectedRadio(radio);
      notifyListeners();
      _audioService.debugAudio('radio req=$requestId done, total '
          '${debugWatch.elapsedMilliseconds}ms');
      return true;
    } on PlayerInterruptedException catch (e) {
      _audioService.debugAudio('radio req=$requestId '
          'PlayerInterruptedException after '
          '${debugWatch.elapsedMilliseconds}ms: ${e.message}');
      // Loading was replaced by a newer audio or a stop: not a failure.
      notifyListeners();
      return true;
    } catch (e) {
      return _handlePlayError(e, requestId);
    } finally {
      _finishLoading(requestId);
    }
  }

  // Stops the radio stream and clears the current selection.
  Future<void> stopRadio() async {
    _audioService.cancelPlayRequests();
    _clearLoading();
    await player.stop();
    _setSelectedRadio(null);
    notifyListeners();
  }

  // Listens for track end so auto-next can play the next surah.
  void _listenForReciterCompletion() {
    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          isAutoNextEnabled &&
          selectedReciter != null) {
        recitersNext(selectedReciter!);
      }
      // Keep play/pause icons in sync with player state.
      if (selectedReciterId != null) {
        final wasPlaying = isReciterPlaying;
        isReciterPlaying = state.playing;
        if (wasPlaying != isReciterPlaying) {
          notifyListeners();
        }
      }
      if (selectedRadioId != null ||
          selectedSharawyAudioUrl != null ||
          selectedSermonAudioUrl != null) {
        notifyListeners();
      }
    });
  }

  // Turns repeat on/off; enabling it disables auto-next.
  Future<void> toggleRepeat() async {
    if (isRepeatEnabled) {
      isRepeatEnabled = false;
      await player.setLoopMode(LoopMode.off);
    } else {
      isRepeatEnabled = true;
      isAutoNextEnabled = false;
      await player.setLoopMode(LoopMode.one);
    }
    _audioService.isRepeatEnabled = isRepeatEnabled;
    _audioService.isAutoNextEnabled = isAutoNextEnabled;
    notifyListeners();
  }

  // Turns auto-next on/off; enabling it disables repeat.
  Future<void> toggleAutoNext() async {
    if (isAutoNextEnabled) {
      isAutoNextEnabled = false;
      await player.setLoopMode(LoopMode.off);
    } else {
      isAutoNextEnabled = true;
      isRepeatEnabled = false;
      await player.setLoopMode(LoopMode.off);
    }
    _audioService.isRepeatEnabled = isRepeatEnabled;
    _audioService.isAutoNextEnabled = isAutoNextEnabled;
    notifyListeners();
  }

  Future<void> muteSound(Radios radio) async {
    if (selectedRadioForSoundId != null &&
        selectedRadioForSoundId == radio.id) {
      await player.setVolume(1);
      _setSelectedRadioForSound(null);
    } else {
      await player.setVolume(0);
      _setSelectedRadioForSound(radio);
    }
    notifyListeners();
  }

  // Stops reciter audio and clears the current selection.
  Future<void> stopReciter() async {
    _audioService.cancelPlayRequests();
    _clearLoading();
    await player.stop();
    _setSelectedReciter(null);
    isReciterPlaying = false;
    notifyListeners();
  }

  // Plays or pauses a reciter audio (keeps selection on pause).
  // Returns false when blocked by a call, or when offline without a local file.
  Future<bool> playReciter(Reciters reciter) async {
    // TEMP AUDIO DEBUG
    _audioService.debugAudio('playReciter START "${reciter.name}" '
        'id=${reciter.id} sura=$currentSura '
        '(selectedReciterId=$selectedReciterId, loading=$loadingAudioKey, '
        'playing=${player.playing}, state=${player.processingState.name})');
    // Ignore repeat taps while this reciter is still loading.
    if (isReciterLoading(reciter)) {
      _audioService.debugAudio('playReciter ignored: already loading');
      return true;
    }
    // While another card is loading, the player holds that audio, so this
    // reciter must be loaded again instead of resumed.
    if (loadingAudioKey == null &&
        selectedReciterId != null &&
        selectedReciterId == reciter.id) {
      if (isReciterPlaying) {
        await player.pause();
        isReciterPlaying = false;
        notifyListeners();
        return true;
      }

      final Uri playbackUri = await _resolveReciterPlaybackUri(
        reciter: reciter,
        suraNumber: currentSura,
      );
      if (!await _canPlayUri(playbackUri)) {
        notifyListeners();
        return false;
      }
      final bool started = await _audioService.play();
      isReciterPlaying = started;
      notifyListeners();
      return started;
    }

    final int requestId = _audioService.startPlayRequest();
    return _loadAndPlayReciterSura(
      reciter: reciter,
      suraNumber: currentSura,
      requestId: requestId,
    );
  }

  // Plays or pauses a sermon audio (keeps selection on pause).
  // Returns false when blocked by a call, or when offline.
  Future<bool> playSermon(Sermon sermon) async {
    final String key = _sermonKey(sermon);
    // Ignore repeat taps while this sermon is still loading.
    if (loadingAudioKey == key) return true;
    // While another card is loading, the player holds that audio, so this
    // sermon must be loaded again instead of resumed.
    if (loadingAudioKey == null &&
        selectedSermonAudioUrl != null &&
        selectedSermonAudioUrl == sermon.audioUrl) {
      if (player.playing) {
        await player.pause();
        notifyListeners();
        return true;
      }
      if (!await _audioService.ensureOnline()) {
        notifyListeners();
        return false;
      }
      final bool started = await _audioService.play();
      notifyListeners();
      return started;
    }

    final int requestId = _audioService.startPlayRequest();
    _startLoading(key, requestId);
    try {
      if (!await _audioService.ensureCanPlay()) {
        notifyListeners();
        return false;
      }
      if (!await _audioService.ensureOnline()) {
        notifyListeners();
        return false;
      }
      // A newer request or a stop replaced this one: leave the player alone.
      if (_audioService.isStalePlayRequest(requestId)) return true;
      await player.setLoopMode(LoopMode.off);
      await player.setAudioSource(
        _audioService.buildUriAudioSource(
          Uri.parse(sermon.audioUrl),
          tag: MediaItem(
            id: 'sermon_${sermon.audioUrl}',
            title: sermon.titleAr,
            artist: 'Islami',
          ),
        ),
      );
      if (_audioService.isStalePlayRequest(requestId)) return true;
      await _audioService.applyPlaybackSpeed();
      final bool started = await _audioService.play();
      if (_audioService.isStalePlayRequest(requestId)) return true;
      if (!started) {
        notifyListeners();
        return false;
      }
      _setSelectedRadio(null);
      _setSelectedReciter(null);
      _setSelectedSharawyLecture(null);
      _setSelectedSermon(sermon);
      notifyListeners();
      return true;
    } on PlayerInterruptedException {
      // Loading was replaced by a newer audio or a stop: not a failure.
      notifyListeners();
      return true;
    } catch (e) {
      return _handlePlayError(e, requestId);
    } finally {
      _finishLoading(requestId);
    }
  }

  // Stops sermon audio and clears the current selection.
  Future<void> stopSermon() async {
    _audioService.cancelPlayRequests();
    _clearLoading();
    await player.stop();
    _setSelectedSermon(null);
    notifyListeners();
  }

  /// Plays the next sura. Returns false when blocked by a call or offline.
  Future<bool> recitersNext(Reciters reciter) async {
    if (currentSura >= 114) {
      return true;
    }
    return _playAdjacentSura(reciter, currentSura + 1);
  }

  /// Plays the previous sura. Returns false when blocked by a call or offline.
  Future<bool> recitersBack(Reciters reciter) async {
    if (currentSura <= 1) {
      return true;
    }
    return _playAdjacentSura(reciter, currentSura - 1);
  }

  /// Moves to [suraNumber] right away (so fast taps keep counting) and plays
  /// it; restores the previous sura when this latest request really fails.
  Future<bool> _playAdjacentSura(Reciters reciter, int suraNumber) async {
    final int requestId = _audioService.startPlayRequest();
    final int previousSura = currentSura;
    _setCurrentSura(suraNumber);
    final bool played = await _loadAndPlayReciterSura(
      reciter: reciter,
      suraNumber: suraNumber,
      requestId: requestId,
    );
    if (!played && !_audioService.isStalePlayRequest(requestId)) {
      _setCurrentSura(previousSura);
      notifyListeners();
    }
    return played;
  }

  /// Prefers a local MediaStore file when available; otherwise the remote URL.
  Future<Uri> _resolveReciterPlaybackUri({
    required Reciters reciter,
    required int suraNumber,
  }) async {
    final String remoteUrl =
        '${reciter.server}${suraNumber.toString().padLeft(3, '0')}.mp3';
    String? localUri;
    final int? reciterId = reciter.id;
    if (reciterId != null) {
      final DownloadedAudio? download =
          await _downloadedAudioRepository.getDownload(
        suraId: suraNumber,
        reciterId: reciterId,
        reciterName: reciter.name,
      );
      localUri = download?.localUri;
    }
    return _audioService.resolvePlaybackUri(
      remoteUrl: remoteUrl,
      localUri: localUri,
    );
  }

  /// True when [uri] is a local file/content URI.
  bool _isLocalUri(Uri uri) {
    return uri.scheme == 'file' || uri.scheme == 'content';
  }

  /// Allows playback for local files always; remote URLs need internet.
  Future<bool> _canPlayUri(Uri uri) async {
    if (_isLocalUri(uri)) {
      return true;
    }
    return _audioService.ensureOnline();
  }

  /// Re-fetches the online list for the current radio tab segment.
  Future<void> refreshCurrentOnlineData() async {
    if (toggleSwitchIndex == 0) {
      await getRadios();
    } else if (toggleSwitchIndex == 1) {
      await getReciters();
    }
  }

  Future<void> seekReciter(Duration position) async {
    await player.seek(position);
  }

  // Seeks the currently playing sermon to [position].
  Future<void> seekSermon(Duration position) async {
    await player.seek(position);
  }

  /// Formats as mm:ss, or h:mm:ss when the track is 1 hour or longer.
  String formatAudioTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // Filters radios by name using normalized Arabic search.
  void filterRadio(String newText) {
    radioSearchQuery = newText;
    saveSearchText(SharedPreferencesKay.radioSearch, newText);
    _updateFilteredRadios();
    notifyListeners();
  }

  // Filters reciters by name using normalized Arabic search.
  void filterReciter(String newText) {
    reciterSearchQuery = newText;
    saveSearchText(SharedPreferencesKay.reciterSearch, newText);
    _updateFilteredReciters();
    notifyListeners();
  }

  // Restores the saved search texts, then re-filters the loaded lists.
  // Sha'rawy pillars/sections/lectures are skipped: opening them clears
  // their search, and they are not open after a restart.
  Future<void> _loadSearchTexts() async {
    radioSearchQuery = await getSearchText(SharedPreferencesKay.radioSearch);
    reciterSearchQuery =
        await getSearchText(SharedPreferencesKay.reciterSearch);
    suraSearchQuery =
        await getSearchText(SharedPreferencesKay.reciterSuraSearch);
    sermonSearchQuery = await getSearchText(SharedPreferencesKay.sermonSearch);
    sharawyCategorySearchQuery =
        await getSearchText(SharedPreferencesKay.sharawyCategorySearch);
    _updateFilteredRadios();
    _updateFilteredReciters();
    _updateSuraSearch();
    _updateFilteredSermons();
    _updateFilteredSharawyCategories();
    notifyListeners();
  }

  // Loads saved favorites, then re-orders any already loaded lists.
  Future<void> _loadFavorites() async {
    favoriteRadioIds = await getFavoriteRadioIds();
    favoriteReciterIds = await getFavoriteReciterIds();
    _updateFilteredRadios();
    _updateFilteredReciters();
    notifyListeners();
  }

  /// True when [radio] is in the favorites.
  bool isRadioFavorite(Radios radio) {
    return favoriteRadioIds.contains(radio.id);
  }

  /// True when [reciter] is in the favorites.
  bool isReciterFavorite(Reciters reciter) {
    return favoriteReciterIds.contains(reciter.id);
  }

  // Switches the radios list between "all" and "favorites".
  void changeRadioListTab(int index) {
    if (radioListTabIndex == index) return;
    radioListTabIndex = index;
    _updateFilteredRadios();
    notifyListeners();
  }

  // Switches the reciters list between "all" and "favorites".
  void changeReciterListTab(int index) {
    if (reciterListTabIndex == index) return;
    reciterListTabIndex = index;
    _updateFilteredReciters();
    notifyListeners();
  }

  /// Adds or removes [radio] from favorites. Its card shrinks away first,
  /// then the list is re-ordered and the card grows in at its new place.
  Future<void> toggleFavoriteRadio(Radios radio) async {
    final int? id = radio.id;
    if (id == null || leavingRadioIds.contains(id)) return;

    if (favoriteRadioIds.contains(id)) {
      favoriteRadioIds.remove(id);
    } else {
      favoriteRadioIds.insert(0, id);
    }
    saveFavoriteRadioIds(favoriteRadioIds);
    leavingRadioIds.add(id);
    notifyListeners();

    await Future.delayed(AppAnimations.listMove);
    leavingRadioIds.remove(id);
    enteringRadioId = id;
    _updateFilteredRadios();
    notifyListeners();

    // Stops the card from replaying its grow animation when rebuilt later.
    await Future.delayed(AppAnimations.listMove);
    if (enteringRadioId == id) enteringRadioId = null;
  }

  /// Adds or removes [reciter] from favorites. Its card shrinks away first,
  /// then the list is re-ordered and the card grows in at its new place.
  Future<void> toggleFavoriteReciter(Reciters reciter) async {
    final int? id = reciter.id;
    if (id == null || leavingReciterIds.contains(id)) return;

    if (favoriteReciterIds.contains(id)) {
      favoriteReciterIds.remove(id);
    } else {
      favoriteReciterIds.insert(0, id);
    }
    saveFavoriteReciterIds(favoriteReciterIds);
    leavingReciterIds.add(id);
    notifyListeners();

    await Future.delayed(AppAnimations.listMove);
    leavingReciterIds.remove(id);
    enteringReciterId = id;
    _updateFilteredReciters();
    notifyListeners();

    // Stops the card from replaying its grow animation when rebuilt later.
    await Future.delayed(AppAnimations.listMove);
    if (enteringReciterId == id) enteringReciterId = null;
  }

  // Rebuilds [filteredRadios] from the search text, tab, and favorites.
  void _updateFilteredRadios() {
    filteredRadios = _favoritesFirst<Radios>(
      items: radios,
      favoriteIds: favoriteRadioIds,
      searchQuery: radioSearchQuery,
      onlyFavorites: radioListTabIndex == favoritesListTabIndex,
      idOf: (radio) => radio.id,
      nameOf: (radio) => radio.name,
    );
  }

  // Rebuilds [filteredReciters] from the search text, tab, and favorites.
  void _updateFilteredReciters() {
    filteredReciters = _favoritesFirst<Reciters>(
      items: reciters,
      favoriteIds: favoriteReciterIds,
      searchQuery: reciterSearchQuery,
      onlyFavorites: reciterListTabIndex == favoritesListTabIndex,
      idOf: (reciter) => reciter.id,
      nameOf: (reciter) => reciter.name,
    );
  }

  /// Returns the items matching [searchQuery]: favorites first (newest first),
  /// then the rest in their original order. Generic (`<T>`) so radios and
  /// reciters share the same logic; [idOf] and [nameOf] read each item.
  List<T> _favoritesFirst<T>({
    required List<T> items,
    required List<int> favoriteIds,
    required String searchQuery,
    required bool onlyFavorites,
    required int? Function(T item) idOf,
    required String? Function(T item) nameOf,
  }) {
    final String normalizedQuery = normalizeArabic(searchQuery);
    final List<T> matches = items.where((item) {
      if (searchQuery.isEmpty) return true;
      final String? name = nameOf(item);
      if (name == null) return false;
      return normalizeArabic(name).contains(normalizedQuery);
    }).toList();

    final List<T> favorites = [];
    for (final int favoriteId in favoriteIds) {
      for (final T item in matches) {
        if (idOf(item) == favoriteId) {
          favorites.add(item);
          break;
        }
      }
    }
    if (onlyFavorites) return favorites;

    final List<T> others = matches.where((item) {
      return !favoriteIds.contains(idOf(item));
    }).toList();
    return [...favorites, ...others];
  }

  // Filters sermons by Arabic title using normalized Arabic search.
  void filterSermon(String newText) {
    sermonSearchQuery = newText;
    saveSearchText(SharedPreferencesKay.sermonSearch, newText);
    _updateFilteredSermons();
    notifyListeners();
  }

  // Rebuilds [filteredSermons] from [sermonSearchQuery].
  void _updateFilteredSermons() {
    if (sermonSearchQuery.isEmpty) {
      filteredSermons = sermons;
    } else {
      final normalizedQuery = normalizeArabic(sermonSearchQuery);
      filteredSermons = sermons.where((sermon) {
        return normalizeArabic(sermon.titleAr).contains(normalizedQuery);
      }).toList();
    }
  }

  // Filters Sha'rawy categories by Arabic title using normalized Arabic search.
  void filterSharawyCategory(String newText) {
    sharawyCategorySearchQuery = newText;
    saveSearchText(SharedPreferencesKay.sharawyCategorySearch, newText);
    _updateFilteredSharawyCategories();
    notifyListeners();
  }

  // Rebuilds [filteredSharawyCategories] from [sharawyCategorySearchQuery].
  void _updateFilteredSharawyCategories() {
    if (sharawyCategorySearchQuery.isEmpty) {
      filteredSharawyCategories = sharawyCategories;
    } else {
      final normalizedQuery = normalizeArabic(sharawyCategorySearchQuery);
      filteredSharawyCategories = sharawyCategories.where((category) {
        return normalizeArabic(category.titleAr).contains(normalizedQuery);
      }).toList();
    }
  }

  // Stores and saves the Sha'rawy pillars search text.
  void _setSharawyPillarSearch(String text) {
    sharawyPillarSearchQuery = text;
    saveSearchText(SharedPreferencesKay.sharawyPillarSearch, text);
  }

  // Stores and saves the Sha'rawy sections search text.
  void _setSharawySectionSearch(String text) {
    sharawySectionSearchQuery = text;
    saveSearchText(SharedPreferencesKay.sharawySectionSearch, text);
  }

  // Stores and saves the Sha'rawy lectures search text.
  void _setSharawyLectureSearch(String text) {
    sharawyLectureSearchQuery = text;
    saveSearchText(SharedPreferencesKay.sharawyLectureSearch, text);
  }

  // Filters Sha'rawy pillars by Arabic title using normalized Arabic search.
  void filterSharawyPillar(String newText) {
    _setSharawyPillarSearch(newText);
    if (newText.isEmpty) {
      filteredSharawyPillars = sharawyPillars;
    } else {
      final normalizedQuery = normalizeArabic(newText);
      filteredSharawyPillars = sharawyPillars.where((pillar) {
        return normalizeArabic(pillar.title).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Filters Sha'rawy sections by Arabic title using normalized Arabic search.
  void filterSharawySection(String newText) {
    _setSharawySectionSearch(newText);
    if (newText.isEmpty) {
      filteredSharawySections = sharawySections;
    } else {
      final normalizedQuery = normalizeArabic(newText);
      filteredSharawySections = sharawySections.where((section) {
        return normalizeArabic(section.title).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Filters Sha'rawy lectures by Arabic title using normalized Arabic search.
  void filterSharawyLecture(String newText) {
    _setSharawyLectureSearch(newText);
    if (newText.isEmpty) {
      filteredSharawyLectures = sharawyLectures;
    } else {
      final normalizedQuery = normalizeArabic(newText);
      filteredSharawyLectures = sharawyLectures.where((lecture) {
        return normalizeArabic(lecture.title).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Filters the reciter's sura list by Arabic or English sura name.
  void onSearch(String newText) {
    suraSearchQuery = newText;
    saveSearchText(SharedPreferencesKay.reciterSuraSearch, newText);
    _updateSuraSearch();
    notifyListeners();
  }

  // Rebuilds [filterSearch] (sura indexes) from [suraSearchQuery].
  void _updateSuraSearch() {
    List<int> suraResultSearch = [];
    final normalizedQuery = normalizeArabic(suraSearchQuery);

    for (int i = 0; i < QuranResources.englishQuranSuras.length; i++) {
      if (QuranResources.englishQuranSuras[i].toUpperCase().contains(
            suraSearchQuery.toUpperCase(),
          ) ||
          normalizeArabic(QuranResources.arabicQuranSuras[i])
              .contains(normalizedQuery)) {
        suraResultSearch.add(i);
      }
    }

    filterSearch = suraResultSearch;
  }

  void resetReciterSearch() {
    reciterSearchQuery = '';
    saveSearchText(SharedPreferencesKay.reciterSearch, '');
    _updateFilteredReciters();
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioService.removeListener(_onActiveAudioChanged);
    super.dispose();
  }
}
