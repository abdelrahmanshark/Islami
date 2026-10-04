import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/downloaded_reciter_summary.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:islami/utils/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// State for the Downloads tab (reciters with offline surahs).
///
/// Lives for the whole app; the tab calls [onTabOpened] to load downloads.
class DownloadsViewModel extends ChangeNotifier {
  DownloadsViewModel({
    DownloadedAudioRepository? downloadedAudioRepository,
  }) : _downloadedAudioRepository =
            downloadedAudioRepository ?? DownloadedAudioRepositoryImpl() {
    _restorePlaybackState();
    _listenForPlayerState();
    _audioService.addListener(_onActiveAudioChanged);
    _loadReciterSearch();
  }

  final DownloadedAudioRepository _downloadedAudioRepository;
  final AudioPlayerService _audioService = AudioPlayerService.instance;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  List<DownloadedAudio> _allDownloads = <DownloadedAudio>[];
  List<DownloadedReciterSummary> filteredReciters =
      <DownloadedReciterSummary>[];
  List<DownloadedAudio> filteredSuras = <DownloadedAudio>[];

  DownloadedReciterSummary? selectedReciter;
  bool isLoading = false;
  String? errorMessage;

  // Text of the reciters / suras search field, saved in SharedPreferences.
  String reciterSearchQuery = '';
  String suraSearchQuery = '';

  /// True when at least one downloaded sura exists on the device.
  bool get hasDownloads => _allDownloads.isNotEmpty;

  /// Reciter currently selected for offline playback.
  int? playingReciterId;

  /// Sura currently selected for offline playback.
  int? playingSuraId;

  /// Reciter name of the playing offline sura (for the mini player title).
  String playingReciterName = '';

  /// Whether the selected offline sura is actively playing.
  bool isPlaying = false;

  /// Repeat one sura (same as reciters tab).
  bool isRepeatEnabled = false;

  /// Auto-play next downloaded sura when the current one ends.
  bool isAutoNextEnabled = false;

  // Set by a mini player tap; cleared once the sura list scrolled.
  bool _scrollToPlayingPending = false;

  /// Shared audio player used by the downloads player card.
  AudioPlayer get player => _audioService.player;

  /// Title of the playing offline sura, shown in the mini player.
  String get playingAudioTitle {
    final int? suraId = playingSuraId;
    if (suraId == null) return '';
    return 'سورة ${_suraTitle(suraId)} - $playingReciterName';
  }

  /// Called each time the Downloads tab opens: re-reads settings shared with
  /// the Radio tab and reloads files (new ones may come from the Radio tab).
  /// The spinner only shows on the first load; later reloads update the
  /// list in place so it does not flicker or lose its scroll position.
  Future<void> onTabOpened() async {
    isRepeatEnabled = _audioService.isRepeatEnabled;
    isAutoNextEnabled = _audioService.isAutoNextEnabled;
    await loadDownloads(showLoading: _allDownloads.isEmpty);
  }

  /// Opens the reciter whose offline sura is playing (mini player tap),
  /// then asks the sura list to scroll to the playing sura.
  /// The reciter is only reopened when the playing sura is not already listed.
  void showPlayingReciter() {
    final int? reciterId = playingReciterId;
    if (reciterId == null) return;
    final bool isPlayingSuraListed =
        selectedReciter?.reciterId == reciterId && playingSuraIndex != null;
    if (!isPlayingSuraListed) {
      _setSuraSearch('');
      for (final DownloadedReciterSummary summary
          in buildReciterSummaries(_allDownloads)) {
        if (summary.reciterId == reciterId) {
          selectedReciter = summary;
          _applySelectedReciter(reciterId);
          break;
        }
      }
    }
    _scrollToPlayingPending = true;
    notifyListeners();
  }

  /// True when the sura list should scroll to the playing sura.
  bool get shouldScrollToPlaying => _scrollToPlayingPending;

  /// Called by the sura list once it scrolled to the playing sura.
  void onScrolledToPlaying() {
    _scrollToPlayingPending = false;
  }

  /// Index of the playing sura in [filteredSuras] (matched by reciter/sura id).
  int? get playingSuraIndex {
    final int index = filteredSuras.indexWhere(isSelectedDownload);
    if (index < 0) return null;
    return index;
  }

  /// Loads valid downloads and builds the reciter list.
  /// Pass [showLoading] false to refresh silently without the spinner.
  Future<void> loadDownloads({bool showLoading = true}) async {
    isLoading = showLoading;
    errorMessage = null;
    notifyListeners();

    try {
      _allDownloads = await _downloadedAudioRepository.getValidDownloads();
      _updateFilteredReciters();
      if (selectedReciter != null) {
        _applySelectedReciter(selectedReciter!.reciterId);
      }
      isLoading = false;
      notifyListeners();
    } catch (e) {
      log(e.toString());
      isLoading = false;
      errorMessage = 'تعذر تحميل التحميلات';
      notifyListeners();
    }
  }

  /// Rescans device storage (Music/Islami/Quran) and refreshes the list.
  Future<void> rescanDownloads() async {
    await loadDownloads();
  }

  /// Filters reciters that have downloads by name.
  void filterReciters(String query) {
    reciterSearchQuery = query;
    saveSearchText(SharedPreferencesKay.downloadsReciterSearch, query);
    _updateFilteredReciters();
    notifyListeners();
  }

  /// Restores the saved reciters search text and re-filters the list.
  /// The suras search is not restored: opening a reciter clears it.
  Future<void> _loadReciterSearch() async {
    reciterSearchQuery =
        await getSearchText(SharedPreferencesKay.downloadsReciterSearch);
    _updateFilteredReciters();
    notifyListeners();
  }

  /// Rebuilds [filteredReciters] from all downloads and [reciterSearchQuery].
  void _updateFilteredReciters() {
    final List<DownloadedReciterSummary> all =
        buildReciterSummaries(_allDownloads);
    if (reciterSearchQuery.trim().isEmpty) {
      filteredReciters = all;
    } else {
      final String normalizedQuery = normalizeArabic(reciterSearchQuery);
      filteredReciters = all.where((reciter) {
        return normalizeArabic(reciter.reciterName).contains(normalizedQuery);
      }).toList();
    }
  }

  /// Opens a reciter's downloaded surah list (starts with an empty search).
  void selectReciter(DownloadedReciterSummary reciter) {
    selectedReciter = reciter;
    _setSuraSearch('');
    _applySelectedReciter(reciter.reciterId);
    notifyListeners();
  }

  /// Returns to the reciter list, filtered by the saved reciters search.
  void clearSelectedReciter() {
    selectedReciter = null;
    filteredSuras = <DownloadedAudio>[];
    _updateFilteredReciters();
    notifyListeners();
  }

  /// Filters downloaded surahs for the selected reciter.
  void filterSuras(String query) {
    _setSuraSearch(query);
    if (selectedReciter == null) return;
    _updateFilteredSuras(selectedReciter!.reciterId);
    notifyListeners();
  }

  /// Stores and saves the suras search text.
  void _setSuraSearch(String query) {
    suraSearchQuery = query;
    saveSearchText(SharedPreferencesKay.downloadsSuraSearch, query);
  }

  /// Rebuilds [filteredSuras] for [reciterId] from [suraSearchQuery].
  void _updateFilteredSuras(int reciterId) {
    final List<DownloadedAudio> forReciter = _downloadsForReciter(reciterId);
    final String query = suraSearchQuery;

    if (query.trim().isEmpty) {
      filteredSuras = forReciter;
    } else {
      final String normalizedQuery = normalizeArabic(query);
      filteredSuras = forReciter.where((item) {
        final int index = item.suraId - 1;
        if (index < 0 || index >= QuranResources.arabicQuranSuras.length) {
          return false;
        }
        final String arabic = QuranResources.arabicQuranSuras[index];
        final String english = QuranResources.englishQuranSuras[index];
        return normalizeArabic(arabic).contains(normalizedQuery) ||
            english.toUpperCase().contains(query.toUpperCase());
      }).toList();
    }
  }

  /// Plays a downloaded sura (does not toggle pause — card handles that).
  Future<void> playDownloadedSura(DownloadedAudio download) async {
    final int requestId = _audioService.startPlayRequest();
    try {
      await _startDownload(download, requestId);
    } on PlayerInterruptedException {
      // Loading was replaced by a newer audio or a stop: nothing to clear.
    } catch (e) {
      log(e.toString());
      // Only the latest request may clear the selection.
      if (!_audioService.isStalePlayRequest(requestId)) {
        _clearPlayingSelection();
      }
    }
    notifyListeners();
  }

  /// Pauses or resumes the playing offline sura (mini player button).
  Future<void> togglePlayback() async {
    if (playingSuraId == null) return;
    if (isPlaying) {
      await player.pause();
      isPlaying = false;
    } else {
      isPlaying = await _audioService.play();
    }
    notifyListeners();
  }

  /// Plays or pauses the active downloaded reciter (card play button).
  Future<void> playSelectedReciter() async {
    if (selectedReciter == null) return;

    final int reciterId = selectedReciter!.reciterId;
    final bool isSameReciter = playingReciterId == reciterId;

    if (isSameReciter && playingSuraId != null) {
      await togglePlayback();
      return;
    }

    final List<DownloadedAudio> downloads = _downloadsForReciter(reciterId);
    if (downloads.isEmpty) return;

    // Prefer current sura if it exists offline; otherwise first download.
    DownloadedAudio target = downloads.first;
    if (playingSuraId != null) {
      for (final DownloadedAudio item in downloads) {
        if (item.suraId == playingSuraId) {
          target = item;
          break;
        }
      }
    }

    await playDownloadedSura(target);
  }

  /// Plays the next downloaded sura for the active reciter.
  Future<void> playNextDownload() async {
    final DownloadedAudio? next = _adjacentDownload(goForward: true);
    if (next == null) return;
    await playDownloadedSura(next);
  }

  /// Plays the previous downloaded sura for the active reciter.
  Future<void> playPreviousDownload() async {
    final DownloadedAudio? previous = _adjacentDownload(goForward: false);
    if (previous == null) return;
    await playDownloadedSura(previous);
  }

  /// Turns repeat on/off; enabling it disables auto-next.
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

  /// Turns auto-next on/off; enabling it disables repeat.
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

  /// Cycles playback speed: 1x → 1.25x → 1.5x → 2x → 1x.
  Future<void> cyclePlaybackSpeed() async {
    await _audioService.cyclePlaybackSpeed();
    notifyListeners();
  }

  /// Current speed label for the speed button, e.g. "1.5x".
  String get playbackSpeedLabel => _audioService.playbackSpeedLabel;

  /// Stops playback and clears the downloads selection.
  Future<void> stopPlayback() async {
    _audioService.cancelPlayRequests();
    await player.stop();
    _clearPlayingSelection();
    notifyListeners();
  }

  /// Seeks the currently playing download.
  Future<void> seekPlayback(Duration position) async {
    await player.seek(position);
  }

  /// Formats as mm:ss, or h:mm:ss when the track is 1 hour or longer.
  String formatAudioTime(Duration duration) {
    final int hours = duration.inHours;
    final String minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Whether [download] is the currently selected offline track.
  bool isSelectedDownload(DownloadedAudio download) {
    return playingReciterId == download.reciterId &&
        playingSuraId == download.suraId;
  }

  /// Whether [download] is selected and currently playing.
  bool isPlayingDownload(DownloadedAudio download) {
    return isSelectedDownload(download) && isPlaying;
  }

  /// Deletes one downloaded sura file and its metadata.
  Future<bool> deleteDownload(DownloadedAudio download) async {
    try {
      // Stop playback if this track is currently playing.
      if (isSelectedDownload(download)) {
        _audioService.cancelPlayRequests();
        await player.stop();
        _clearPlayingSelection();
      }

      await _downloadedAudioRepository.removeDownload(
        suraId: download.suraId,
        reciterId: download.reciterId,
        deleteFile: true,
      );

      _allDownloads.removeWhere(
        (item) =>
            item.suraId == download.suraId &&
            item.reciterId == download.reciterId,
      );

      if (selectedReciter != null) {
        final int reciterId = selectedReciter!.reciterId;
        _applySelectedReciter(reciterId);
        // Checks all downloads, not filteredSuras (the search may hide some).
        if (_downloadsForReciter(reciterId).isEmpty) {
          selectedReciter = null;
          filteredSuras = <DownloadedAudio>[];
          _updateFilteredReciters();
        }
      } else {
        _updateFilteredReciters();
      }

      notifyListeners();
      return true;
    } catch (e) {
      log(e.toString());
      errorMessage = 'تعذر حذف التحميل';
      notifyListeners();
      return false;
    }
  }

  /// Deletes every downloaded sura for the selected reciter.
  Future<bool> deleteSelectedReciterDownloads() async {
    if (selectedReciter == null) return false;

    final int reciterId = selectedReciter!.reciterId;
    final List<DownloadedAudio> toDelete = _downloadsForReciter(reciterId);

    try {
      for (final DownloadedAudio download in toDelete) {
        if (isSelectedDownload(download)) {
          _audioService.cancelPlayRequests();
          await player.stop();
          _clearPlayingSelection();
        }

        await _downloadedAudioRepository.removeDownload(
          suraId: download.suraId,
          reciterId: download.reciterId,
          deleteFile: true,
        );
      }

      _allDownloads.removeWhere((item) => item.reciterId == reciterId);
      selectedReciter = null;
      filteredSuras = <DownloadedAudio>[];
      _updateFilteredReciters();
      notifyListeners();
      return true;
    } catch (e) {
      log(e.toString());
      errorMessage = 'تعذر حذف التحميلات';
      notifyListeners();
      return false;
    }
  }

  /// Starts a download track and syncs shared audio selection.
  /// Does nothing once a newer play request or a stop replaced [requestId].
  Future<void> _startDownload(DownloadedAudio download, int requestId) async {
    if (!await _audioService.ensureCanPlay()) {
      isPlaying = false;
      return;
    }
    if (_audioService.isStalePlayRequest(requestId)) return;

    final String suraTitle = _suraTitle(download.suraId);
    await player.setLoopMode(
      isRepeatEnabled ? LoopMode.one : LoopMode.off,
    );
    await player.setAudioSource(
      _audioService.buildUriAudioSource(
        Uri.parse(download.localUri),
        tag: MediaItem(
          id: 'download_${download.reciterId}_${download.suraId}',
          title: 'سورة $suraTitle',
          artist: download.reciterName,
        ),
      ),
    );
    if (_audioService.isStalePlayRequest(requestId)) return;
    await _audioService.applyPlaybackSpeed();

    // Clear other audio modes so only this download is active.
    _audioService.selectedRadioId = null;
    _audioService.selectedRadioForSoundId = null;
    _audioService.selectedSermonAudioUrl = null;
    _audioService.selectedSharawyAudioUrl = null;
    _audioService.selectedReciterId = download.reciterId;
    _audioService.currentSura = download.suraId;

    playingReciterId = download.reciterId;
    playingSuraId = download.suraId;
    playingReciterName = download.reciterName;
    _audioService.setActiveAudioType(ActiveAudioType.download);

    final bool started = await _audioService.play();
    isPlaying = started;
  }

  /// Clears the offline play selection and hides the mini player.
  void _clearPlayingSelection() {
    isPlaying = false;
    playingReciterId = null;
    playingSuraId = null;
    playingReciterName = '';
    _audioService.selectedReciterId = null;
    if (_audioService.activeAudioType == ActiveAudioType.download) {
      _audioService.setActiveAudioType(null);
    }
  }

  /// Clears the downloads selection when Radio-tab audio starts playing.
  void _onActiveAudioChanged() {
    final ActiveAudioType? activeType = _audioService.activeAudioType;
    if (activeType == null || activeType == ActiveAudioType.download) return;
    if (playingReciterId == null && playingSuraId == null) return;

    isPlaying = false;
    playingReciterId = null;
    playingSuraId = null;
    playingReciterName = '';
    notifyListeners();
  }

  /// Finds next or previous downloaded sura for the playing reciter.
  DownloadedAudio? _adjacentDownload({required bool goForward}) {
    final int? reciterId = playingReciterId ?? selectedReciter?.reciterId;
    if (reciterId == null) return null;

    final List<DownloadedAudio> downloads = _downloadsForReciter(reciterId);
    if (downloads.isEmpty) return null;

    if (playingSuraId == null) {
      return goForward ? downloads.first : downloads.last;
    }

    final int currentIndex = downloads.indexWhere(
      (item) => item.suraId == playingSuraId,
    );
    if (currentIndex < 0) {
      return goForward ? downloads.first : downloads.last;
    }

    if (goForward) {
      if (currentIndex >= downloads.length - 1) return null;
      return downloads[currentIndex + 1];
    }

    if (currentIndex <= 0) return null;
    return downloads[currentIndex - 1];
  }

  /// Sorted offline suras for one reciter.
  List<DownloadedAudio> _downloadsForReciter(int reciterId) {
    return _allDownloads
        .where((item) => item.reciterId == reciterId)
        .toList()
      ..sort((a, b) => a.suraId.compareTo(b.suraId));
  }

  /// Restores play selection from the shared audio service.
  void _restorePlaybackState() {
    // selectedReciterId is shared with online reciters; restore only downloads.
    if (_audioService.activeAudioType == ActiveAudioType.download) {
      playingReciterId = _audioService.selectedReciterId;
      playingSuraId = _audioService.currentSura;
    }
    isPlaying = playingReciterId != null && player.playing;
    isRepeatEnabled = _audioService.isRepeatEnabled;
    isAutoNextEnabled = _audioService.isAutoNextEnabled;
  }

  /// Keeps play/pause icons in sync and handles auto-next.
  void _listenForPlayerState() {
    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (playingReciterId == null || playingSuraId == null) return;

      if (state.processingState == ProcessingState.completed &&
          isAutoNextEnabled) {
        playNextDownload();
        return;
      }

      final bool wasPlaying = isPlaying;
      isPlaying = state.playing;
      if (wasPlaying != isPlaying) {
        notifyListeners();
      }
    });
  }

  /// Arabic sura name for media notifications.
  String _suraTitle(int suraId) {
    final int index = suraId - 1;
    if (index < 0 || index >= QuranResources.arabicQuranSuras.length) {
      return '$suraId';
    }
    return QuranResources.arabicQuranSuras[index];
  }

  /// Fills [filteredSuras] for the given reciter id.
  void _applySelectedReciter(int reciterId) {
    _updateFilteredSuras(reciterId);

    for (final DownloadedReciterSummary summary
        in buildReciterSummaries(_allDownloads)) {
      if (summary.reciterId == reciterId) {
        selectedReciter = summary;
        break;
      }
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioService.removeListener(_onActiveAudioChanged);
    super.dispose();
  }
}
