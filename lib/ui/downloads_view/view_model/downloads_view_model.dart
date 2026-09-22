import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/downloaded_reciter_summary.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/utils/arabic_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// State for the Downloads tab (reciters with offline surahs).
class DownloadsViewModel extends ChangeNotifier {
  DownloadsViewModel({
    DownloadedAudioRepository? downloadedAudioRepository,
  }) : _downloadedAudioRepository =
            downloadedAudioRepository ?? DownloadedAudioRepositoryImpl() {
    _restorePlaybackState();
    _listenForPlayerState();
    loadDownloads();
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

  /// Reciter currently selected for offline playback.
  int? playingReciterId;

  /// Sura currently selected for offline playback.
  int? playingSuraId;

  /// Whether the selected offline sura is actively playing.
  bool isPlaying = false;

  /// Repeat one sura (same as reciters tab).
  bool isRepeatEnabled = false;

  /// Auto-play next downloaded sura when the current one ends.
  bool isAutoNextEnabled = false;

  /// Shared audio player used by the downloads player card.
  AudioPlayer get player => _audioService.player;

  /// Loads valid downloads and builds the reciter list.
  Future<void> loadDownloads() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _allDownloads = await _downloadedAudioRepository.getValidDownloads();
      filteredReciters = buildReciterSummaries(_allDownloads);
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
    final List<DownloadedReciterSummary> all =
        buildReciterSummaries(_allDownloads);
    if (query.trim().isEmpty) {
      filteredReciters = all;
    } else {
      final String normalizedQuery = normalizeArabic(query);
      filteredReciters = all.where((reciter) {
        return normalizeArabic(reciter.reciterName).contains(normalizedQuery);
      }).toList();
    }
    notifyListeners();
  }

  /// Opens a reciter's downloaded surah list.
  void selectReciter(DownloadedReciterSummary reciter) {
    selectedReciter = reciter;
    _applySelectedReciter(reciter.reciterId);
    notifyListeners();
  }

  /// Returns to the reciter list.
  void clearSelectedReciter() {
    selectedReciter = null;
    filteredSuras = <DownloadedAudio>[];
    filteredReciters = buildReciterSummaries(_allDownloads);
    notifyListeners();
  }

  /// Filters downloaded surahs for the selected reciter.
  void filterSuras(String query) {
    if (selectedReciter == null) return;

    final List<DownloadedAudio> forReciter = _downloadsForReciter(
      selectedReciter!.reciterId,
    );

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
    notifyListeners();
  }

  /// Plays a downloaded sura (does not toggle pause — card handles that).
  Future<void> playDownloadedSura(DownloadedAudio download) async {
    try {
      await _startDownload(download);
    } catch (e) {
      log(e.toString());
      isPlaying = false;
      playingReciterId = null;
      playingSuraId = null;
    }
    notifyListeners();
  }

  /// Plays or pauses the active downloaded reciter (card play button).
  Future<void> playSelectedReciter() async {
    if (selectedReciter == null) return;

    final int reciterId = selectedReciter!.reciterId;
    final bool isSameReciter = playingReciterId == reciterId;

    if (isSameReciter && playingSuraId != null) {
      if (isPlaying) {
        await player.pause();
        isPlaying = false;
      } else {
        // Do not await play() — it completes only when playback ends.
        player.play();
        isPlaying = true;
      }
      notifyListeners();
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

  /// Stops playback and clears the downloads selection.
  Future<void> stopPlayback() async {
    await player.stop();
    isPlaying = false;
    playingReciterId = null;
    playingSuraId = null;
    _audioService.selectedReciterId = null;
    notifyListeners();
  }

  /// Seeks the currently playing download.
  Future<void> seekPlayback(Duration position) async {
    await player.seek(position);
  }

  /// Formats a duration as mm:ss for the slider labels.
  String formatAudioTime(Duration duration) {
    final String minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
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
        await player.stop();
        isPlaying = false;
        playingReciterId = null;
        playingSuraId = null;
        _audioService.selectedReciterId = null;
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
        _applySelectedReciter(selectedReciter!.reciterId);
        if (filteredSuras.isEmpty) {
          selectedReciter = null;
          filteredReciters = buildReciterSummaries(_allDownloads);
        }
      } else {
        filteredReciters = buildReciterSummaries(_allDownloads);
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
          await player.stop();
          isPlaying = false;
          playingReciterId = null;
          playingSuraId = null;
          _audioService.selectedReciterId = null;
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
      filteredReciters = buildReciterSummaries(_allDownloads);
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
  Future<void> _startDownload(DownloadedAudio download) async {
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

    // Clear other audio modes so only this download is active.
    _audioService.selectedRadioId = null;
    _audioService.selectedRadioForSoundId = null;
    _audioService.selectedSermonAudioUrl = null;
    _audioService.selectedSharawyAudioUrl = null;
    _audioService.selectedReciterId = download.reciterId;
    _audioService.currentSura = download.suraId;

    playingReciterId = download.reciterId;
    playingSuraId = download.suraId;
    isPlaying = true;

    // Do not await play() — it completes only when playback ends.
    player.play();
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
    playingReciterId = _audioService.selectedReciterId;
    playingSuraId = _audioService.currentSura;
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
    filteredSuras = _downloadsForReciter(reciterId);

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
    super.dispose();
  }
}
