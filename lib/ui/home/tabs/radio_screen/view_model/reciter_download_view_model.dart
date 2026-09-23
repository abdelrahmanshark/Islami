import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/quran_download_manager.dart';

/// Selection and download UI state for a single reciter's surah list.
class ReciterDownloadViewModel extends ChangeNotifier {
  ReciterDownloadViewModel({
    required this.reciter,
    DownloadedAudioRepository? downloadedAudioRepository,
    QuranDownloadManager? downloadManager,
  })  : _downloadedAudioRepository =
            downloadedAudioRepository ?? DownloadedAudioRepositoryImpl(),
        _downloadManager = downloadManager ?? QuranDownloadManager.instance {
    _downloadManager.addListener(_onManagerChanged);
    loadDownloadedSuras();
  }

  final Reciters reciter;
  final DownloadedAudioRepository _downloadedAudioRepository;
  final QuranDownloadManager _downloadManager;

  final Set<int> selectedSuraIds = <int>{};
  final Set<int> downloadedSuraIds = <int>{};

  int skippedAlreadyDownloadedCount = 0;
  int unavailableCount = 0;
  String? downloadErrorMessage;

  /// True while this reciter (or any batch owned by the manager for it) runs.
  bool get isDownloading =>
      _downloadManager.isDownloadingReciter(reciter.id);

  bool get wasCancelled => _downloadManager.wasCancelled;

  int get downloadCompletedCount => _downloadManager.downloadCompletedCount;

  int get downloadTotalCount => _downloadManager.downloadTotalCount;

  bool get isDownloadAll => _downloadManager.isDownloadAll;

  /// Number of surahs currently selected for download.
  int get selectedCount => selectedSuraIds.length;

  /// Relays global manager updates and refreshes local downloaded marks.
  void _onManagerChanged() {
    final int? completedSuraId = _downloadManager.lastCompletedSuraId;
    if (completedSuraId != null &&
        _downloadManager.activeReciterId == reciter.id) {
      downloadedSuraIds.add(completedSuraId);
      selectedSuraIds.remove(completedSuraId);
    }

    if (!_downloadManager.isDownloading &&
        _downloadManager.activeReciterId == reciter.id) {
      loadDownloadedSuras();
    }
    notifyListeners();
  }

  /// Loads which surahs are already downloaded for this reciter.
  Future<void> loadDownloadedSuras() async {
    final int? reciterId = reciter.id;
    if (reciterId == null) return;

    try {
      final List<DownloadedAudio> items =
          await _downloadedAudioRepository.getValidDownloadsForReciter(
        reciterId,
        reciterName: reciter.name,
      );
      downloadedSuraIds
        ..clear()
        ..addAll(items.map((item) => item.suraId));
      notifyListeners();
    } catch (e) {
      log(e.toString());
    }
  }

  /// Toggles sura selection (sura numbers 1–114).
  /// Returns false when the sura is already downloaded (selection blocked).
  bool toggleSuraSelection(int suraId) {
    if (downloadedSuraIds.contains(suraId)) {
      return false;
    }
    if (selectedSuraIds.contains(suraId)) {
      selectedSuraIds.remove(suraId);
    } else {
      selectedSuraIds.add(suraId);
    }
    notifyListeners();
    return true;
  }

  /// True when [suraId] is selected.
  bool isSuraSelected(int suraId) => selectedSuraIds.contains(suraId);

  /// True when [suraId] is already downloaded.
  bool isSuraDownloaded(int suraId) => downloadedSuraIds.contains(suraId);

  /// Selects every sura that is not already downloaded.
  void selectAllSuras() {
    selectedSuraIds
      ..clear()
      ..addAll(
        List<int>.generate(114, (index) => index + 1)
            .where((suraId) => !downloadedSuraIds.contains(suraId)),
      );
    notifyListeners();
  }

  /// Downloads the currently selected surahs, skipping ones already on device.
  Future<int> downloadSelected() async {
    if (_downloadManager.isDownloading) return 0;

    final List<int> selected = selectedSuraIds.toList()..sort();
    final List<int> toDownload = await _filterAlreadyDownloaded(selected);
    if (toDownload.isEmpty) {
      notifyListeners();
      return 0;
    }

    final int count = await _downloadManager.downloadSuras(
      reciter: reciter,
      suraIds: toDownload,
      downloadAll: false,
      alreadySkippedCount: skippedAlreadyDownloadedCount,
    );
    _syncResultFromManager();
    await loadDownloadedSuras();
    return count;
  }

  /// Downloads every sura that is not already on the device.
  Future<int> downloadAllSuras() async {
    if (_downloadManager.isDownloading) return 0;

    skippedAlreadyDownloadedCount = 0;
    unavailableCount = 0;
    downloadErrorMessage = null;

    final List<int> toDownload = List<int>.generate(114, (index) => index + 1)
        .where((suraId) => !downloadedSuraIds.contains(suraId))
        .toList();
    if (toDownload.isEmpty) {
      notifyListeners();
      return 0;
    }

    final int count = await _downloadManager.downloadSuras(
      reciter: reciter,
      suraIds: toDownload,
      downloadAll: true,
      alreadySkippedCount: 0,
    );
    _syncResultFromManager();
    await loadDownloadedSuras();
    return count;
  }

  /// Stops the current download batch via the global manager.
  void cancelDownload() {
    _downloadManager.cancelDownload();
  }

  /// Skips only the active sura during a download-all batch.
  void cancelCurrentSuraDownload() {
    _downloadManager.cancelCurrentSuraDownload();
  }

  /// Stops every remaining sura in a download-all batch.
  void cancelAllDownloads() {
    _downloadManager.cancelAllDownloads();
  }

  /// Copies result counters from the manager for snackbar helpers.
  void _syncResultFromManager() {
    skippedAlreadyDownloadedCount =
        _downloadManager.skippedAlreadyDownloadedCount;
    unavailableCount = _downloadManager.unavailableCount;
    downloadErrorMessage = _downloadManager.downloadErrorMessage;
  }

  /// Removes already-downloaded suras from [suraIds] and updates skip count.
  Future<List<int>> _filterAlreadyDownloaded(List<int> suraIds) async {
    await loadDownloadedSuras();

    skippedAlreadyDownloadedCount = 0;
    unavailableCount = 0;
    downloadErrorMessage = null;

    final int? reciterId = reciter.id;
    final List<int> toDownload = <int>[];

    for (final int suraId in suraIds) {
      bool alreadyOnDevice = downloadedSuraIds.contains(suraId);

      if (!alreadyOnDevice && reciterId != null) {
        alreadyOnDevice = await _downloadedAudioRepository.isDownloaded(
          suraId: suraId,
          reciterId: reciterId,
          reciterName: reciter.name,
        );
      }

      if (alreadyOnDevice) {
        downloadedSuraIds.add(suraId);
        selectedSuraIds.remove(suraId);
        skippedAlreadyDownloadedCount++;
        continue;
      }

      toDownload.add(suraId);
    }

    return toDownload;
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onManagerChanged);
    super.dispose();
  }
}
