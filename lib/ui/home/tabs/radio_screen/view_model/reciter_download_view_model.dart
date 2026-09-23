import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/quran_audio_download_service.dart';
import 'package:islami/utils/network_utils.dart';

/// Selection and download state for a single reciter's surah list.
class ReciterDownloadViewModel extends ChangeNotifier {
  ReciterDownloadViewModel({
    required this.reciter,
    DownloadedAudioRepository? downloadedAudioRepository,
    QuranAudioDownloadService? downloadService,
  }) : _downloadedAudioRepository =
            downloadedAudioRepository ?? DownloadedAudioRepositoryImpl() {
    _downloadService = downloadService ??
        QuranAudioDownloadService(
          downloadedAudioRepository: _downloadedAudioRepository,
        );
    loadDownloadedSuras();
  }

  final Reciters reciter;
  final DownloadedAudioRepository _downloadedAudioRepository;
  late final QuranAudioDownloadService _downloadService;

  final Set<int> selectedSuraIds = <int>{};
  final Set<int> downloadedSuraIds = <int>{};

  bool isDownloading = false;
  bool wasCancelled = false;
  int downloadCompletedCount = 0;
  int downloadTotalCount = 0;
  int skippedAlreadyDownloadedCount = 0;
  int unavailableCount = 0;
  String? downloadErrorMessage;

  bool _cancelRequested = false;

  /// Number of surahs currently selected for download.
  int get selectedCount => selectedSuraIds.length;

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
    final List<int> selected = selectedSuraIds.toList()..sort();
    final List<int> toDownload = await _filterAlreadyDownloaded(selected);
    if (toDownload.isEmpty) {
      notifyListeners();
      return 0;
    }
    return _downloadSuras(toDownload);
  }

  /// Downloads every sura that is not already on the device.
  Future<int> downloadAllSuras() async {
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
    return _downloadSuras(toDownload);
  }

  /// Stops the current download batch after the active file finishes aborting.
  void cancelDownload() {
    if (!isDownloading) return;
    _cancelRequested = true;
    _downloadService.cancelActiveDownload();
    notifyListeners();
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

  /// Runs sequential downloads and returns how many succeeded.
  Future<int> _downloadSuras(List<int> suraIds) async {
    if (isDownloading || suraIds.isEmpty) return 0;

    isDownloading = true;
    wasCancelled = false;
    _cancelRequested = false;
    downloadCompletedCount = 0;
    downloadTotalCount = suraIds.length;
    // Keep skip count from filtering; reset only unavailable for this run.
    unavailableCount = 0;
    downloadErrorMessage = null;
    notifyListeners();

    if (!await NetworkUtils.hasInternetConnection()) {
      isDownloading = false;
      unavailableCount = suraIds.length;
      downloadErrorMessage = NetworkUtils.noInternetMessage;
      notifyListeners();
      return 0;
    }

    int successCount = 0;

    try {
      for (final int suraId in suraIds) {
        if (_cancelRequested) {
          wasCancelled = true;
          break;
        }

        try {
          await _downloadService.downloadSura(
            reciter: reciter,
            suraId: suraId,
          );
          downloadedSuraIds.add(suraId);
          selectedSuraIds.remove(suraId);
          successCount++;
        } on DownloadCancelledException {
          wasCancelled = true;
          break;
        } on AlreadyDownloadedException {
          // File appeared on device during the batch — skip and continue.
          downloadedSuraIds.add(suraId);
          selectedSuraIds.remove(suraId);
          skippedAlreadyDownloadedCount++;
        } on AudioUnavailableException catch (e) {
          log('Audio unavailable for sura $suraId: $e');
          unavailableCount++;
          downloadErrorMessage = AudioUnavailableException.userMessage;
          selectedSuraIds.remove(suraId);
        } catch (e) {
          if (_cancelRequested) {
            wasCancelled = true;
            break;
          }
          log('Failed to download sura $suraId: $e');
          unavailableCount++;
          downloadErrorMessage = NetworkUtils.isNetworkError(e)
              ? NetworkUtils.noInternetMessage
              : AudioUnavailableException.userMessage;
          selectedSuraIds.remove(suraId);
        }
        downloadCompletedCount++;
        notifyListeners();
      }
    } finally {
      isDownloading = false;
      _cancelRequested = false;
      notifyListeners();
    }

    return successCount;
  }
}
