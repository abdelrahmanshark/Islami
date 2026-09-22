import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/quran_audio_download_service.dart';

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
  void toggleSuraSelection(int suraId) {
    if (selectedSuraIds.contains(suraId)) {
      selectedSuraIds.remove(suraId);
    } else {
      selectedSuraIds.add(suraId);
    }
    notifyListeners();
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

  /// Downloads the currently selected surahs.
  Future<int> downloadSelected() async {
    final List<int> toDownload = selectedSuraIds.toList()..sort();
    return _downloadSuras(toDownload);
  }

  /// Downloads every sura that is not already on the device.
  Future<int> downloadAllSuras() async {
    final List<int> toDownload = List<int>.generate(114, (index) => index + 1)
        .where((suraId) => !downloadedSuraIds.contains(suraId))
        .toList();
    return _downloadSuras(toDownload);
  }

  /// Stops the current download batch after the active file finishes aborting.
  void cancelDownload() {
    if (!isDownloading) return;
    _cancelRequested = true;
    _downloadService.cancelActiveDownload();
    notifyListeners();
  }

  /// Runs sequential downloads and returns how many succeeded.
  Future<int> _downloadSuras(List<int> suraIds) async {
    if (isDownloading || suraIds.isEmpty) return 0;

    isDownloading = true;
    wasCancelled = false;
    _cancelRequested = false;
    downloadCompletedCount = 0;
    downloadTotalCount = suraIds.length;
    downloadErrorMessage = null;
    notifyListeners();

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
        } catch (e) {
          if (_cancelRequested) {
            wasCancelled = true;
            break;
          }
          log('Failed to download sura $suraId: $e');
          downloadErrorMessage = e.toString();
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
