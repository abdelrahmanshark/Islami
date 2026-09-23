import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/download_notification_service.dart';
import 'package:islami/services/quran_audio_download_service.dart';
import 'package:islami/utils/app_messenger.dart';
import 'package:islami/utils/network_utils.dart';

/// App-wide Quran download state that survives leaving the reciter screen.
class QuranDownloadManager extends ChangeNotifier {
  QuranDownloadManager._({
    DownloadedAudioRepository? downloadedAudioRepository,
    QuranAudioDownloadService? downloadService,
  }) : _downloadedAudioRepository =
            downloadedAudioRepository ?? DownloadedAudioRepositoryImpl() {
    _downloadService = downloadService ??
        QuranAudioDownloadService(
          downloadedAudioRepository: _downloadedAudioRepository,
        );
    _registerCancelPort();
  }

  static final QuranDownloadManager instance = QuranDownloadManager._();

  final DownloadedAudioRepository _downloadedAudioRepository;
  late final QuranAudioDownloadService _downloadService;

  ReceivePort? _cancelReceivePort;

  bool isDownloading = false;
  bool isDownloadAll = false;
  bool wasCancelled = false;
  int downloadCompletedCount = 0;
  int downloadTotalCount = 0;
  int skippedAlreadyDownloadedCount = 0;
  int unavailableCount = 0;
  int? activeReciterId;
  String? activeReciterName;
  int? currentSuraId;
  int? lastCompletedSuraId;
  int? currentFileProgressPercent;
  String? downloadErrorMessage;

  bool _cancelAllRequested = false;
  bool _skipCurrentRequested = false;
  DateTime? _lastNotificationUpdate;

  /// Handles notification action taps on the main isolate.
  static void onNotificationResponse(NotificationResponse response) {
    instance.applyNotificationAction(response.actionId);
  }

  /// Applies a notification action id (also used by the isolate port).
  void applyNotificationAction(String? actionId) {
    if (actionId == null || actionId.isEmpty) return;
    log('Download notification action: $actionId');

    if (actionId == DownloadNotificationActions.cancelAll) {
      cancelAllDownloads();
      return;
    }
    if (actionId == DownloadNotificationActions.cancelCurrent) {
      cancelCurrentSuraDownload();
    }
  }

  /// True when a batch is running for [reciterId].
  bool isDownloadingReciter(int? reciterId) {
    if (!isDownloading || reciterId == null) return false;
    return activeReciterId == reciterId;
  }

  /// Human-readable progress for the active batch.
  String? get progressLabel {
    if (!isDownloading) return null;
    final String base =
        'جاري التحميل $downloadCompletedCount/$downloadTotalCount';
    if (currentSuraId == null) return base;
    return '$base • سورة ${_suraName(currentSuraId!)}';
  }

  /// Starts sequential downloads for [suraIds] of [reciter].
  Future<int> downloadSuras({
    required Reciters reciter,
    required List<int> suraIds,
    bool downloadAll = false,
    int alreadySkippedCount = 0,
  }) async {
    if (isDownloading || suraIds.isEmpty) return 0;

    final int? reciterId = reciter.id;
    if (reciterId == null) return 0;

    // Re-register in case a hot restart dropped the isolate port.
    _registerCancelPort();

    isDownloading = true;
    isDownloadAll = downloadAll;
    wasCancelled = false;
    _cancelAllRequested = false;
    _skipCurrentRequested = false;
    downloadCompletedCount = 0;
    downloadTotalCount = suraIds.length;
    skippedAlreadyDownloadedCount = alreadySkippedCount;
    unavailableCount = 0;
    downloadErrorMessage = null;
    activeReciterId = reciterId;
    activeReciterName = reciter.name?.trim().isNotEmpty == true
        ? reciter.name!.trim()
        : 'قارئ';
    currentSuraId = suraIds.first;
    lastCompletedSuraId = null;
    currentFileProgressPercent = null;
    notifyListeners();
    await _updateNotification(force: true);

    if (!await NetworkUtils.hasInternetConnection()) {
      isDownloading = false;
      unavailableCount = suraIds.length;
      downloadErrorMessage = NetworkUtils.noInternetMessage;
      currentSuraId = null;
      currentFileProgressPercent = null;
      notifyListeners();
      await DownloadNotificationService.dismiss();
      return 0;
    }

    int successCount = 0;

    try {
      for (final int suraId in suraIds) {
        if (_cancelAllRequested) {
          wasCancelled = true;
          break;
        }

        currentSuraId = suraId;
        currentFileProgressPercent = 0;
        _skipCurrentRequested = false;
        notifyListeners();
        await _updateNotification(force: true);

        try {
          await _downloadService.downloadSura(
            reciter: reciter,
            suraId: suraId,
            onProgress: (int received, int? total) {
              // Keep aborting if the user already requested stop from notification.
              if (_cancelAllRequested || _skipCurrentRequested) {
                _downloadService.cancelActiveDownload();
              }
              if (total != null && total > 0) {
                currentFileProgressPercent =
                    ((received / total) * 100).clamp(0, 100).round();
              } else {
                currentFileProgressPercent = null;
              }
              notifyListeners();
              _updateNotification();
            },
          );
          successCount++;
          lastCompletedSuraId = suraId;
          notifyListeners();
        } on DownloadCancelledException {
          if (_cancelAllRequested) {
            wasCancelled = true;
            break;
          }
          // Skip only the current sura, then continue the batch.
          if (_skipCurrentRequested) {
            log('Skipped current sura download: $suraId');
          }
        } on AlreadyDownloadedException {
          skippedAlreadyDownloadedCount++;
          lastCompletedSuraId = suraId;
          notifyListeners();
        } on AudioUnavailableException catch (e) {
          log('Audio unavailable for sura $suraId: $e');
          unavailableCount++;
          downloadErrorMessage = AudioUnavailableException.userMessage;
        } catch (e) {
          if (_cancelAllRequested) {
            wasCancelled = true;
            break;
          }
          log('Failed to download sura $suraId: $e');
          unavailableCount++;
          downloadErrorMessage = NetworkUtils.isNetworkError(e)
              ? NetworkUtils.noInternetMessage
              : AudioUnavailableException.userMessage;
        }

        downloadCompletedCount++;
        currentFileProgressPercent = null;
        notifyListeners();
        await _updateNotification(force: true);
      }
    } finally {
      final bool cancelled = wasCancelled;
      final int finishedCount = successCount;
      isDownloading = false;
      _cancelAllRequested = false;
      _skipCurrentRequested = false;
      currentSuraId = null;
      currentFileProgressPercent = null;
      notifyListeners();
      await DownloadNotificationService.dismiss();
      _showFinishedSnackBar(finishedCount, cancelled: cancelled);
    }

    return successCount;
  }

  /// Stops the whole remaining batch (used by in-app stop and "إيقاف الكل").
  void cancelDownload() {
    cancelAllDownloads();
  }

  /// Aborts the active file and stops every remaining sura.
  void cancelAllDownloads() {
    if (!isDownloading) {
      log('cancelAllDownloads ignored: not downloading');
      return;
    }
    log('Cancelling all downloads');
    _cancelAllRequested = true;
    _skipCurrentRequested = false;
    wasCancelled = true;
    _downloadService.cancelActiveDownload();
    notifyListeners();
  }

  /// Aborts only the current sura and continues with the next ones.
  void cancelCurrentSuraDownload() {
    if (!isDownloading) {
      log('cancelCurrentSuraDownload ignored: not downloading');
      return;
    }
    // For small selected batches, "stop" means stop everything.
    if (!isDownloadAll) {
      cancelAllDownloads();
      return;
    }
    log('Skipping current sura download');
    _skipCurrentRequested = true;
    _downloadService.cancelActiveDownload();
    notifyListeners();
  }

  /// Registers a receive port so notification actions can cancel downloads.
  void _registerCancelPort() {
    _cancelReceivePort?.close();
    IsolateNameServer.removePortNameMapping(downloadCancelPortName);

    final ReceivePort port = ReceivePort();
    final bool registered = IsolateNameServer.registerPortWithName(
      port.sendPort,
      downloadCancelPortName,
    );
    if (!registered) {
      log('Could not register download cancel port');
      port.close();
      return;
    }

    _cancelReceivePort = port;
    port.listen((dynamic message) {
      if (message is String) {
        applyNotificationAction(message);
      }
    });
  }

  /// Updates the system notification (throttled unless [force] is true).
  Future<void> _updateNotification({bool force = false}) async {
    if (!isDownloading) return;

    final DateTime now = DateTime.now();
    if (!force &&
        _lastNotificationUpdate != null &&
        now.difference(_lastNotificationUpdate!) <
            const Duration(milliseconds: 400)) {
      return;
    }
    _lastNotificationUpdate = now;

    final int? suraId = currentSuraId;
    await DownloadNotificationService.showProgress(
      reciterName: activeReciterName ?? 'قارئ',
      suraLabel: suraId == null ? '...' : _suraName(suraId),
      completed: downloadCompletedCount,
      total: downloadTotalCount,
      isDownloadAll: isDownloadAll,
      fileProgressPercent: currentFileProgressPercent,
    );
  }

  /// Shows a global snackbar when a batch ends (works after navigation).
  void _showFinishedSnackBar(int count, {required bool cancelled}) {
    if (cancelled) {
      AppMessenger.showSnackBar(
        count > 0 ? 'تم إيقاف التحميل بعد $count سورة' : 'تم إيقاف التحميل',
      );
      return;
    }

    final List<String> parts = <String>[];
    if (count > 0) {
      parts.add('تم تحميل $count سورة بنجاح');
    }
    if (skippedAlreadyDownloadedCount > 0) {
      parts.add(
        skippedAlreadyDownloadedCount == 1
            ? 'تم تخطي سورة محمّلة مسبقاً'
            : 'تم تخطي $skippedAlreadyDownloadedCount سور محمّلة مسبقاً',
      );
    }
    if (unavailableCount > 0) {
      parts.add(
        downloadErrorMessage ?? AudioUnavailableException.userMessage,
      );
    }

    if (parts.isNotEmpty) {
      AppMessenger.showSnackBar(parts.join('\n'));
    }
  }

  /// Arabic sura name for display (1-based id).
  String _suraName(int suraId) {
    final int index = suraId - 1;
    if (index < 0 || index >= QuranResources.arabicQuranSuras.length) {
      return '$suraId';
    }
    return QuranResources.arabicQuranSuras[index];
  }

  @override
  void dispose() {
    _cancelReceivePort?.close();
    IsolateNameServer.removePortNameMapping(downloadCancelPortName);
    super.dispose();
  }
}
