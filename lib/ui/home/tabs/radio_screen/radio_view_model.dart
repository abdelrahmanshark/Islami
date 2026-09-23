import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/data/radio/radio_repository.dart';
import 'package:islami/data/sermons/sermons_local_data_source.dart';
import 'package:islami/data/sharawy/sharawy_local_data_source.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/radio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/models/radio_response.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/models/sermon.dart';
import 'package:islami/models/sharawy_category.dart';
import 'package:islami/models/sharawy_pillar.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/network_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../../services/audio_player_service.dart';
import 'package:islami/models/quran_resources.dart';

class RadioViewModel extends ChangeNotifier {
  RadioViewModel({
    RadioRepository? radioRepository,
    SermonsLocalDataSource? sermonsLocalDataSource,
    SharawyLocalDataSource? sharawyLocalDataSource,
    DownloadedAudioRepository? downloadedAudioRepository,
  }) : _radioRepository = radioRepository ?? RadioRepositoryImpl(),
       _sermonsLocalDataSource =
           sermonsLocalDataSource ?? SermonsLocalDataSource(),
       _sharawyLocalDataSource =
           sharawyLocalDataSource ?? SharawyLocalDataSource(),
       _downloadedAudioRepository =
           downloadedAudioRepository ?? DownloadedAudioRepositoryImpl() {
    _restorePlaybackState();
    getRadios();
    getReciters();
    getSermons();
    getSharawyCategories();
    _listenForReciterCompletion();
  }

  final RadioRepository _radioRepository;
  final SermonsLocalDataSource _sermonsLocalDataSource;
  final SharawyLocalDataSource _sharawyLocalDataSource;
  final DownloadedAudioRepository _downloadedAudioRepository;
  final AudioPlayerService _audioService = AudioPlayerService.instance;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  static const List<double> _playbackSpeeds = [1.0, 1.25, 1.5, 2.0];

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
  double playbackSpeed = 1.0;
  int currentSura = 1;
  late final player = _audioService.player;
  int toggleSwitchIndex = 0;
  bool isRepeatEnabled = false;
  bool isAutoNextEnabled = false;
  bool isReciterPlaying = false; // drives play/pause icon on reciter cards

  // Restore ids from the singleton so UI survives leaving the Radio tab.
  void _restorePlaybackState() {
    selectedRadioId = _audioService.selectedRadioId;
    selectedRadioForSoundId = _audioService.selectedRadioForSoundId;
    selectedReciterId = _audioService.selectedReciterId;
    selectedSermonAudioUrl = _audioService.selectedSermonAudioUrl;
    selectedSharawyAudioUrl = _audioService.selectedSharawyAudioUrl;
    playbackSpeed = _audioService.playbackSpeed;
    currentSura = _audioService.currentSura;
    isRepeatEnabled = _audioService.isRepeatEnabled;
    isAutoNextEnabled = _audioService.isAutoNextEnabled;
    isReciterPlaying =
        selectedReciterId != null && _audioService.player.playing;
  }

  // Persist radio play selection on the singleton.
  void _setSelectedRadio(Radios? radio) {
    selectedRadio = radio;
    selectedRadioId = radio?.id;
    _audioService.selectedRadioId = radio?.id;
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
  }

  // Persist sermon play selection on the singleton.
  void _setSelectedSermon(Sermon? sermon) {
    selectedSermon = sermon;
    selectedSermonAudioUrl = sermon?.audioUrl;
    _audioService.selectedSermonAudioUrl = sermon?.audioUrl;
  }

  // Persist sha'rawy play selection on the singleton.
  void _setSelectedSharawyLecture(QuranStoryLecture? lecture) {
    selectedSharawyLecture = lecture;
    selectedSharawyAudioUrl = lecture?.mp3Url;
    _audioService.selectedSharawyAudioUrl = lecture?.mp3Url;
  }

  // Persist current sura on the singleton.
  void _setCurrentSura(int sura) {
    currentSura = sura;
    _audioService.currentSura = sura;
  }

  // Persist playback speed on the singleton.
  void _setPlaybackSpeed(double speed) {
    playbackSpeed = speed;
    _audioService.playbackSpeed = speed;
  }

  // Called when user picks a sura for the current reciter.
  void updateCurrentSura(int sura) {
    _setCurrentSura(sura);
  }

  // Resets sura search results to the full list of 114 suras.
  void resetSuraSearch() {
    filterSearch = List.generate(114, (index) => index);
    notifyListeners();
  }

  // Plays a specific sura with the given reciter (does not toggle pause).
  // Returns false when blocked by a call, or when offline without a local file.
  Future<bool> playReciterSura(Reciters reciter, int suraNumber) async {
    try {
      if (!await _audioService.ensureCanPlay()) {
        notifyListeners();
        return false;
      }
      _setCurrentSura(suraNumber);
      final Uri playbackUri = await _resolveReciterPlaybackUri(
        reciter: reciter,
        suraNumber: suraNumber,
      );
      if (!await _canPlayUri(playbackUri)) {
        notifyListeners();
        return false;
      }
      await player.setLoopMode(
        isRepeatEnabled ? LoopMode.one : LoopMode.off,
      );
      await player.setAudioSource(
        _audioService.buildUriAudioSource(
          playbackUri,
          tag: MediaItem(
            id: 'sura_$currentSura',
            title: 'سورة $currentSura',
            artist: reciter.name ?? 'قارئ',
          ),
        ),
      );
      _setSelectedRadio(null);
      _setSelectedSermon(null);
      _setSelectedSharawyLecture(null);
      _setSelectedReciter(reciter);
      _audioService.currentSura = currentSura;
      final bool started = await _audioService.play();
      isReciterPlaying = started;
      notifyListeners();
      return started;
    } catch (e) {
      log(e.toString());
      notifyListeners();
      return false;
    }
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
      filteredRadios = radios;
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
      filteredReciters = reciters;
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
      filteredSermons = sermons;
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
    filteredSharawyCategories = sharawyCategories;
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
    if (selectedSharawyAudioUrl != null &&
        selectedSharawyAudioUrl == lecture.mp3Url) {
      if (player.playing) {
        await player.pause();
        notifyListeners();
        return true;
      }
      if (!await NetworkUtils.hasInternetConnection()) {
        notifyListeners();
        return false;
      }
      final bool started = await _audioService.play();
      notifyListeners();
      return started;
    }

    if (!await _audioService.ensureCanPlay()) {
      notifyListeners();
      return false;
    }

    if (!await NetworkUtils.hasInternetConnection()) {
      notifyListeners();
      return false;
    }

    try {
      await player.setLoopMode(LoopMode.off);
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(lecture.mp3Url),
          tag: MediaItem(
            id: 'sharawy_${lecture.mp3Url}',
            title: lecture.title,
            artist: 'الشعراوي',
          ),
        ),
      );
      await player.setSpeed(playbackSpeed);
      final bool started = await _audioService.play();
      if (!started) {
        notifyListeners();
        return false;
      }
      _setSelectedRadio(null);
      _setSelectedReciter(null);
      _setSelectedSermon(null);
      _setSelectedSharawyLecture(lecture);
      notifyListeners();
      return true;
    } catch (e) {
      log(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Seeks the currently playing Sha'rawy lecture to [position].
  Future<void> seekSharawyLecture(Duration position) async {
    await player.seek(position);
  }

  // Stops Sha'rawy audio and clears the current selection.
  Future<void> stopSharawyLecture() async {
    await player.stop();
    _setSelectedSharawyLecture(null);
    notifyListeners();
  }

  // Cycles playback speed: 1x → 1.25x → 1.5x → 2x → 1x.
  Future<void> cyclePlaybackSpeed() async {
    final currentIndex = _playbackSpeeds.indexOf(playbackSpeed);
    final nextIndex =
        currentIndex < 0 ? 0 : (currentIndex + 1) % _playbackSpeeds.length;
    _setPlaybackSpeed(_playbackSpeeds[nextIndex]);
    await player.setSpeed(playbackSpeed);
    notifyListeners();
  }

  // Formats the current speed label for the speed button.
  String get playbackSpeedLabel {
    if (playbackSpeed == playbackSpeed.roundToDouble()) {
      return '${playbackSpeed.toInt()}x';
    }
    return '${playbackSpeed}x';
  }

  /// Plays or pauses a radio station.
  /// Returns false when blocked by a call, or when offline.
  Future<bool> playRadio(Radios radio) async {
    if (selectedRadioId != null && selectedRadioId == radio.id) {
      await player.pause();
      _setSelectedRadio(null);
      notifyListeners();
      return true;
    }

    if (!await _audioService.ensureCanPlay()) {
      notifyListeners();
      return false;
    }

    if (!await NetworkUtils.hasInternetConnection()) {
      notifyListeners();
      return false;
    }

    try {
      // Radio should not inherit reciter loop mode.
      await player.setLoopMode(LoopMode.off);
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(radio.url ?? ''),
          tag: MediaItem(
            id: 'radio_${radio.id}',
            title: radio.name ?? 'راديو',
            artist: 'Islami',
          ),
        ),
      );
      final bool started = await _audioService.play();
      if (!started) {
        notifyListeners();
        return false;
      }
      _setSelectedReciter(null);
      _setSelectedSermon(null);
      _setSelectedSharawyLecture(null);
      _setSelectedRadio(radio);
      notifyListeners();
      return true;
    } catch (e) {
      log(e.toString());
      notifyListeners();
      return false;
    }
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
      if (selectedSharawyAudioUrl != null || selectedSermonAudioUrl != null) {
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
    await player.stop();
    _setSelectedReciter(null);
    isReciterPlaying = false;
    notifyListeners();
  }

  // Plays or pauses a reciter audio (keeps selection on pause).
  // Returns false when blocked by a call, or when offline without a local file.
  Future<bool> playReciter(Reciters reciter) async {
    if (selectedReciterId != null && selectedReciterId == reciter.id) {
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

    try {
      if (!await _audioService.ensureCanPlay()) {
        notifyListeners();
        return false;
      }
      final Uri playbackUri = await _resolveReciterPlaybackUri(
        reciter: reciter,
        suraNumber: currentSura,
      );
      if (!await _canPlayUri(playbackUri)) {
        notifyListeners();
        return false;
      }
      await player.setLoopMode(
        isRepeatEnabled ? LoopMode.one : LoopMode.off,
      );
      await player.setAudioSource(
        _audioService.buildUriAudioSource(
          playbackUri,
          tag: MediaItem(
            id: 'sura_$currentSura',
            title: 'سورة $currentSura',
            artist: reciter.name ?? 'قارئ',
          ),
        ),
      );
      // Update selection before play so the card UI refreshes immediately.
      _setSelectedRadio(null);
      _setSelectedSermon(null);
      _setSelectedSharawyLecture(null);
      _setSelectedReciter(reciter);
      _audioService.currentSura = currentSura;
      final bool started = await _audioService.play();
      isReciterPlaying = started;
      notifyListeners();
      return started;
    } catch (e) {
      log(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Plays or pauses a sermon audio (keeps selection on pause).
  // Returns false when blocked by a call, or when offline.
  Future<bool> playSermon(Sermon sermon) async {
    if (selectedSermonAudioUrl != null &&
        selectedSermonAudioUrl == sermon.audioUrl) {
      if (player.playing) {
        await player.pause();
        notifyListeners();
        return true;
      }
      if (!await NetworkUtils.hasInternetConnection()) {
        notifyListeners();
        return false;
      }
      final bool started = await _audioService.play();
      notifyListeners();
      return started;
    }

    if (!await _audioService.ensureCanPlay()) {
      notifyListeners();
      return false;
    }

    if (!await NetworkUtils.hasInternetConnection()) {
      notifyListeners();
      return false;
    }

    try {
      await player.setLoopMode(LoopMode.off);
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(sermon.audioUrl),
          tag: MediaItem(
            id: 'sermon_${sermon.audioUrl}',
            title: sermon.titleAr,
            artist: 'Islami',
          ),
        ),
      );
      await player.setSpeed(playbackSpeed);
      final bool started = await _audioService.play();
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
    } catch (e) {
      log(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Stops sermon audio and clears the current selection.
  Future<void> stopSermon() async {
    await player.stop();
    _setSelectedSermon(null);
    notifyListeners();
  }

  /// Plays the next sura. Returns false when blocked by a call or offline.
  Future<bool> recitersNext(Reciters reciter) async {
    if (currentSura >= 114) {
      return true;
    }

    if (!await _audioService.ensureCanPlay()) {
      notifyListeners();
      return false;
    }

    _setCurrentSura(currentSura + 1);
    final Uri playbackUri = await _resolveReciterPlaybackUri(
      reciter: reciter,
      suraNumber: currentSura,
    );
    if (!await _canPlayUri(playbackUri)) {
      _setCurrentSura(currentSura - 1);
      notifyListeners();
      return false;
    }

    await player.setAudioSource(
      _audioService.buildUriAudioSource(
        playbackUri,
        tag: MediaItem(
          id: 'sura_$currentSura',
          title: 'سورة $currentSura',
          artist: reciter.name ?? 'قارئ',
        ),
      ),
    );
    final bool started = await _audioService.play();
    if (!started) {
      _setCurrentSura(currentSura - 1);
      notifyListeners();
      return false;
    }
    _setSelectedRadio(null);
    _setSelectedSermon(null);
    _setSelectedSharawyLecture(null);
    _setSelectedReciter(reciter);
    isReciterPlaying = true;
    notifyListeners();
    return true;
  }

  /// Plays the previous sura. Returns false when blocked by a call or offline.
  Future<bool> recitersBack(Reciters reciter) async {
    if (currentSura <= 1) {
      return true;
    }

    if (!await _audioService.ensureCanPlay()) {
      notifyListeners();
      return false;
    }

    _setCurrentSura(currentSura - 1);
    final Uri playbackUri = await _resolveReciterPlaybackUri(
      reciter: reciter,
      suraNumber: currentSura,
    );
    if (!await _canPlayUri(playbackUri)) {
      _setCurrentSura(currentSura + 1);
      notifyListeners();
      return false;
    }

    await player.setAudioSource(
      _audioService.buildUriAudioSource(
        playbackUri,
        tag: MediaItem(
          id: 'sura_$currentSura',
          title: 'سورة $currentSura',
          artist: reciter.name ?? 'قارئ',
        ),
      ),
    );
    final bool started = await _audioService.play();
    if (!started) {
      _setCurrentSura(currentSura + 1);
      notifyListeners();
      return false;
    }
    _setSelectedRadio(null);
    _setSelectedSermon(null);
    _setSelectedSharawyLecture(null);
    _setSelectedReciter(reciter);
    isReciterPlaying = true;
    notifyListeners();
    return true;
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
    return NetworkUtils.hasInternetConnection();
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

  String formatAudioTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void filterRadio(String newText) {
    if (newText.isEmpty) {
      filteredRadios = radios;
    } else {
      final normalizedQuery = normalizeArabic(newText);
      filteredRadios = radios.where((radio) {
        final name = radio.name;
        if (name == null) return false;
        return normalizeArabic(name).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  void filterReciter(String newText) {
    if (newText.isEmpty) {
      filteredReciters = reciters;
    } else {
      final normalizedQuery = normalizeArabic(newText);
      filteredReciters = reciters.where((reciter) {
        final name = reciter.name;
        if (name == null) return false;
        return normalizeArabic(name).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Filters sermons by Arabic title using normalized Arabic search.
  void filterSermon(String newText) {
    if (newText.isEmpty) {
      filteredSermons = sermons;
    } else {
      final normalizedQuery = normalizeArabic(newText);
      filteredSermons = sermons.where((sermon) {
        return normalizeArabic(sermon.titleAr).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Filters Sha'rawy categories by Arabic title using normalized Arabic search.
  void filterSharawyCategory(String newText) {
    if (newText.isEmpty) {
      filteredSharawyCategories = sharawyCategories;
    } else {
      final normalizedQuery = normalizeArabic(newText);
      filteredSharawyCategories = sharawyCategories.where((category) {
        return normalizeArabic(category.titleAr).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Filters Sha'rawy pillars by Arabic title using normalized Arabic search.
  void filterSharawyPillar(String newText) {
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

  void onSearch(String newText) {
    List<int> suraResultSearch = [];
    final normalizedQuery = normalizeArabic(newText);

    for (int i = 0; i < QuranResources.englishQuranSuras.length; i++) {
      if (QuranResources.englishQuranSuras[i].toUpperCase().contains(
            newText.toUpperCase(),
          ) ||
          normalizeArabic(QuranResources.arabicQuranSuras[i])
              .contains(normalizedQuery)) {
        suraResultSearch.add(i);
      }
    }

    filterSearch = suraResultSearch;
    notifyListeners();
  }

  void resetReciterSearch() {
    filteredReciters = reciters;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }
}
