import 'dart:convert';
import 'dart:developer';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/download_notification_service.dart';
import 'package:islami/services/quran_audio_download_service.dart';
import 'package:islami/utils/network_utils.dart';

/// Keys used to pass the download job into the foreground isolate.
class DownloadTaskKeys {
  static const String reciterId = 'reciterId';
  static const String reciterName = 'reciterName';
  static const String reciterServer = 'reciterServer';
  static const String suraIds = 'suraIds';
  static const String downloadAll = 'downloadAll';
  static const String alreadySkipped = 'alreadySkipped';
}

/// Message types sent from the task isolate to the UI isolate.
class DownloadTaskMessages {
  static const String progress = 'progress';
  static const String finished = 'finished';
}

/// Notification button ids handled inside the foreground task.
class DownloadTaskButtons {
  static const String cancelCurrent = 'btn_cancel_current';
  static const String cancelAll = 'btn_cancel_all';
}

/// Top-level callback required by flutter_foreground_task.
@pragma('vm:entry-point')
void downloadForegroundStartCallback() {
  FlutterForegroundTask.setTaskHandler(DownloadForegroundTaskHandler());
}

/// Runs Quran downloads in a foreground-service isolate so they survive app quit.
class DownloadForegroundTaskHandler extends TaskHandler {
  final QuranAudioDownloadService _downloadService =
      QuranAudioDownloadService();

  bool _cancelAllRequested = false;
  bool _skipCurrentRequested = false;
  bool _isRunning = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      await _runDownloadJob();
    } catch (e, st) {
      log('DownloadForegroundTaskHandler error: $e\n$st');
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': DownloadTaskMessages.finished,
        'successCount': 0,
        'wasCancelled': false,
        'skipped': 0,
        'unavailable': 0,
        'errorMessage': e.toString(),
      });
    } finally {
      _isRunning = false;
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Downloads are driven from onStart; no periodic work needed.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _cancelAllRequested = true;
    _downloadService.cancelActiveDownload();
  }

  @override
  void onReceiveData(Object data) {
    if (data is String) {
      _handleCancelCommand(data);
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    _handleCancelCommand(id);
  }

  /// Applies cancel-current or cancel-all from UI / notification buttons.
  void _handleCancelCommand(String id) {
    if (id == DownloadNotificationActions.cancelAll ||
        id == DownloadTaskButtons.cancelAll) {
      _cancelAllRequested = true;
      _skipCurrentRequested = false;
      _downloadService.cancelActiveDownload();
      return;
    }

    if (id == DownloadNotificationActions.cancelCurrent ||
        id == DownloadTaskButtons.cancelCurrent) {
      // Selected-batch "stop" ends everything; download-all skips one sura.
      _skipCurrentRequested = true;
      _downloadService.cancelActiveDownload();
    }
  }

  /// Loads job data and downloads each sura sequentially.
  Future<void> _runDownloadJob() async {
    final int? reciterId =
        await FlutterForegroundTask.getData(key: DownloadTaskKeys.reciterId)
            as int?;
    final String? reciterName =
        await FlutterForegroundTask.getData(key: DownloadTaskKeys.reciterName)
            as String?;
    final String? reciterServer =
        await FlutterForegroundTask.getData(key: DownloadTaskKeys.reciterServer)
            as String?;
    final dynamic rawSuraIds =
        await FlutterForegroundTask.getData(key: DownloadTaskKeys.suraIds);
    final bool downloadAll =
        await FlutterForegroundTask.getData(key: DownloadTaskKeys.downloadAll)
            as bool? ??
            false;
    final int alreadySkipped =
        await FlutterForegroundTask.getData(key: DownloadTaskKeys.alreadySkipped)
            as int? ??
            0;

    if (reciterId == null ||
        reciterServer == null ||
        reciterServer.isEmpty ||
        rawSuraIds == null) {
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': DownloadTaskMessages.finished,
        'successCount': 0,
        'wasCancelled': false,
        'skipped': alreadySkipped,
        'unavailable': 0,
        'errorMessage': 'بيانات التحميل غير مكتملة',
      });
      return;
    }

    final List<int> suraIds = _parseSuraIds(rawSuraIds);
    if (suraIds.isEmpty) {
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': DownloadTaskMessages.finished,
        'successCount': 0,
        'wasCancelled': false,
        'skipped': alreadySkipped,
        'unavailable': 0,
        'errorMessage': 'لا توجد سور للتحميل',
      });
      return;
    }

    final Reciters reciter = Reciters(
      id: reciterId,
      name: reciterName,
      server: reciterServer,
    );

    final String displayName =
        (reciterName != null && reciterName.trim().isNotEmpty)
            ? reciterName.trim()
            : 'قارئ';

    int successCount = 0;
    int skipped = alreadySkipped;
    int unavailable = 0;
    bool wasCancelled = false;
    String? errorMessage;

    if (!await NetworkUtils.hasInternetConnection()) {
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': DownloadTaskMessages.finished,
        'successCount': 0,
        'wasCancelled': false,
        'skipped': skipped,
        'unavailable': suraIds.length,
        'errorMessage': NetworkUtils.noInternetMessage,
      });
      return;
    }

    for (int index = 0; index < suraIds.length; index++) {
      if (_cancelAllRequested) {
        wasCancelled = true;
        break;
      }

      // For selected batches, "skip current" means stop the whole batch.
      if (_skipCurrentRequested && !downloadAll) {
        _cancelAllRequested = true;
        wasCancelled = true;
        break;
      }

      final int suraId = suraIds[index];
      _skipCurrentRequested = false;

      await _updateProgressNotification(
        reciterName: displayName,
        suraId: suraId,
        completed: index,
        total: suraIds.length,
        downloadAll: downloadAll,
      );

      _sendProgress(
        completed: index,
        total: suraIds.length,
        currentSuraId: suraId,
        filePercent: 0,
        downloadAll: downloadAll,
        reciterId: reciterId,
        reciterName: displayName,
        skipped: skipped,
        unavailable: unavailable,
      );

      try {
        await _downloadService.downloadSura(
          reciter: reciter,
          suraId: suraId,
          onProgress: (int received, int? total) {
            if (_cancelAllRequested || _skipCurrentRequested) {
              _downloadService.cancelActiveDownload();
            }
            final int? percent = (total != null && total > 0)
                ? ((received / total) * 100).clamp(0, 100).round()
                : null;
            _sendProgress(
              completed: index,
              total: suraIds.length,
              currentSuraId: suraId,
              filePercent: percent,
              downloadAll: downloadAll,
              reciterId: reciterId,
              reciterName: displayName,
              skipped: skipped,
              unavailable: unavailable,
            );
            if (percent != null && percent % 10 == 0) {
              _updateProgressNotification(
                reciterName: displayName,
                suraId: suraId,
                completed: index,
                total: suraIds.length,
                downloadAll: downloadAll,
                filePercent: percent,
              );
            }
          },
        );
        successCount++;
        _sendProgress(
          completed: index + 1,
          total: suraIds.length,
          currentSuraId: suraId,
          filePercent: null,
          downloadAll: downloadAll,
          reciterId: reciterId,
          reciterName: displayName,
          skipped: skipped,
          unavailable: unavailable,
          lastCompletedSuraId: suraId,
        );
      } on DownloadCancelledException {
        if (_cancelAllRequested || (!downloadAll && _skipCurrentRequested)) {
          wasCancelled = true;
          break;
        }
        log('Skipped current sura download: $suraId');
      } on AlreadyDownloadedException {
        skipped++;
        _sendProgress(
          completed: index + 1,
          total: suraIds.length,
          currentSuraId: suraId,
          filePercent: null,
          downloadAll: downloadAll,
          reciterId: reciterId,
          reciterName: displayName,
          skipped: skipped,
          unavailable: unavailable,
          lastCompletedSuraId: suraId,
        );
      } on AudioUnavailableException catch (e) {
        log('Audio unavailable for sura $suraId: $e');
        unavailable++;
        errorMessage = AudioUnavailableException.userMessage;
      } catch (e) {
        if (_cancelAllRequested) {
          wasCancelled = true;
          break;
        }
        log('Failed to download sura $suraId: $e');
        unavailable++;
        errorMessage = NetworkUtils.isNetworkError(e)
            ? NetworkUtils.noInternetMessage
            : AudioUnavailableException.userMessage;
      }
    }

    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'type': DownloadTaskMessages.finished,
      'successCount': successCount,
      'wasCancelled': wasCancelled,
      'skipped': skipped,
      'unavailable': unavailable,
      'errorMessage': errorMessage,
      'reciterId': reciterId,
      'reciterName': displayName,
      'downloadAll': downloadAll,
      'total': suraIds.length,
    });
  }

  /// Sends live progress to the UI isolate.
  void _sendProgress({
    required int completed,
    required int total,
    required int currentSuraId,
    required int? filePercent,
    required bool downloadAll,
    required int reciterId,
    required String reciterName,
    required int skipped,
    required int unavailable,
    int? lastCompletedSuraId,
  }) {
    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'type': DownloadTaskMessages.progress,
      'completed': completed,
      'total': total,
      'currentSuraId': currentSuraId,
      'filePercent': filePercent,
      'downloadAll': downloadAll,
      'reciterId': reciterId,
      'reciterName': reciterName,
      'skipped': skipped,
      'unavailable': unavailable,
      'lastCompletedSuraId': lastCompletedSuraId,
      'isDownloading': true,
    });
  }

  /// Updates the ongoing foreground-service notification text/buttons.
  Future<void> _updateProgressNotification({
    required String reciterName,
    required int suraId,
    required int completed,
    required int total,
    required bool downloadAll,
    int? filePercent,
  }) async {
    final String suraName = _suraName(suraId);
    final String progressText = '$completed/$total';
    final String body = filePercent == null
        ? 'سورة $suraName • $progressText'
        : 'سورة $suraName • $progressText • $filePercent%';

    final List<NotificationButton> buttons = <NotificationButton>[
      NotificationButton(
        id: DownloadTaskButtons.cancelCurrent,
        text: downloadAll ? 'إيقاف السورة' : 'إيقاف التحميل',
      ),
    ];
    if (downloadAll) {
      buttons.add(
        const NotificationButton(
          id: DownloadTaskButtons.cancelAll,
          text: 'إيقاف الكل',
        ),
      );
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: 'تحميل: $reciterName',
      notificationText: body,
      notificationButtons: buttons,
    );
  }

  /// Arabic sura name for display (1-based id).
  String _suraName(int suraId) {
    final int index = suraId - 1;
    if (index < 0 || index >= QuranResources.arabicQuranSuras.length) {
      return '$suraId';
    }
    return QuranResources.arabicQuranSuras[index];
  }

  /// Parses sura ids stored as a JSON string (or already a list).
  List<int> _parseSuraIds(dynamic raw) {
    if (raw is List) {
      return raw
          .map((dynamic id) => id is int ? id : int.tryParse('$id'))
          .whereType<int>()
          .toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        return _parseSuraIds(decoded);
      } catch (_) {
        return <int>[];
      }
    }
    return <int>[];
  }
}
