import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/download_foreground_task.dart';
import 'package:islami/services/download_notification_service.dart';
import 'package:islami/services/quran_audio_download_service.dart';
import 'package:islami/utils/app_messenger.dart';
import 'package:islami/utils/network_utils.dart';
import 'package:islami/utils/shared_preferences.dart';

/// App-wide Quran download state that survives leaving the reciter screen.
///
/// The downloads themselves run in [DownloadForegroundTaskHandler] (a foreground
/// service), so the queue keeps going after the app is left or swiped away.
class QuranDownloadManager extends ChangeNotifier {
  QuranDownloadManager._({QuranAudioDownloadService? downloadService})
      : _downloadService = downloadService ?? QuranAudioDownloadService() {
    _registerCancelPort();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  static final QuranDownloadManager instance = QuranDownloadManager._();

  static const String storagePermissionMessage =
      'يجب السماح بصلاحية التخزين لتحميل السور';
  static const String serviceStartFailedMessage =
      'تعذر بدء التحميل، حاول مرة أخرى';

  final QuranAudioDownloadService _downloadService;

  ReceivePort? _cancelReceivePort;

  /// Completes with the success count when the running batch finishes.
  Completer<int>? _jobCompleter;

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

  /// Starts sequential downloads for [suraIds] of [reciter] in the foreground
  /// service. Completes with the success count when the batch ends.
  Future<int> downloadSuras({
    required Reciters reciter,
    required List<int> suraIds,
    bool downloadAll = false,
    int alreadySkippedCount = 0,
  }) async {
    if (isDownloading || suraIds.isEmpty) return 0;

    final int? reciterId = reciter.id;
    if (reciterId == null) return 0;

    // Asked here (user tap) because the background task cannot show dialogs.
    final bool hasStorageAccess =
        await _downloadService.requestLegacyStoragePermissionIfNeeded();
    if (!hasStorageAccess) {
      unavailableCount = suraIds.length;
      downloadErrorMessage = storagePermissionMessage;
      AppMessenger.showSnackBar(storagePermissionMessage);
      notifyListeners();
      return 0;
    }

    // Re-register in case a hot restart dropped the isolate port.
    _registerCancelPort();

    isDownloading = true;
    isDownloadAll = downloadAll;
    wasCancelled = false;
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

    if (!await NetworkUtils.hasInternetConnection()) {
      isDownloading = false;
      unavailableCount = suraIds.length;
      downloadErrorMessage = NetworkUtils.noInternetMessage;
      currentSuraId = null;
      currentFileProgressPercent = null;
      notifyListeners();
      return 0;
    }

    // Set before starting so an instant "finished" message is not missed.
    final Completer<int> completer = Completer<int>();
    _jobCompleter = completer;

    final bool started = await _startDownloadService(
      reciter: reciter,
      suraIds: suraIds,
      downloadAll: downloadAll,
      alreadySkippedCount: alreadySkippedCount,
    );
    if (!started) {
      downloadErrorMessage = serviceStartFailedMessage;
      unavailableCount = suraIds.length;
      AppMessenger.showSnackBar(serviceStartFailedMessage);
      _finishJob(0, showSnackBar: false);
    }

    return completer.future;
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
    wasCancelled = true;
    FlutterForegroundTask.sendDataToTask(DownloadTaskButtons.cancelAll);
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
    FlutterForegroundTask.sendDataToTask(DownloadTaskButtons.cancelCurrent);
  }

  /// Saves the job for the task isolate and starts the foreground service.
  Future<bool> _startDownloadService({
    required Reciters reciter,
    required List<int> suraIds,
    required bool downloadAll,
    required int alreadySkippedCount,
  }) async {
    // Android 13+ hides the progress notification without this permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    await FlutterForegroundTask.saveData(
      key: DownloadTaskKeys.reciterId,
      value: reciter.id!,
    );
    await FlutterForegroundTask.saveData(
      key: DownloadTaskKeys.reciterName,
      value: activeReciterName ?? 'قارئ',
    );
    await FlutterForegroundTask.saveData(
      key: DownloadTaskKeys.reciterServer,
      value: reciter.server ?? '',
    );
    await FlutterForegroundTask.saveData(
      key: DownloadTaskKeys.suraIds,
      value: jsonEncode(suraIds),
    );
    await FlutterForegroundTask.saveData(
      key: DownloadTaskKeys.downloadAll,
      value: downloadAll,
    );
    await FlutterForegroundTask.saveData(
      key: DownloadTaskKeys.alreadySkipped,
      value: alreadySkippedCount,
    );

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'quran_download_service',
        channelName: 'تحميل القرآن',
        channelDescription: 'حالة وتقدم تحميل سور القرآن مع إمكانية الإيقاف',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    final ServiceRequestResult result = await FlutterForegroundTask.startService(
      notificationTitle: 'تحميل: ${activeReciterName ?? 'قارئ'}',
      notificationText: 'جاري التحضير...',
      callback: downloadForegroundStartCallback,
    );

    if (result is ServiceRequestFailure) {
      log('Could not start download service: ${result.error}');
      return false;
    }
    return true;
  }

  /// Receives progress / finished messages from the download task isolate.
  void _onTaskData(Object data) {
    if (data is! Map) return;

    final Object? type = data['type'];
    if (type == DownloadTaskMessages.progress) {
      _applyProgress(data);
    } else if (type == DownloadTaskMessages.finished) {
      _applyFinished(data);
    }
  }

  /// Mirrors live task progress (also restores state after the app reopens).
  void _applyProgress(Map data) {
    isDownloading = true;
    isDownloadAll = data['downloadAll'] as bool? ?? isDownloadAll;
    activeReciterId = data['reciterId'] as int? ?? activeReciterId;
    activeReciterName = data['reciterName'] as String? ?? activeReciterName;
    downloadCompletedCount = data['completed'] as int? ?? downloadCompletedCount;
    downloadTotalCount = data['total'] as int? ?? downloadTotalCount;
    skippedAlreadyDownloadedCount =
        data['skipped'] as int? ?? skippedAlreadyDownloadedCount;
    unavailableCount = data['unavailable'] as int? ?? unavailableCount;
    currentSuraId = data['currentSuraId'] as int?;
    currentFileProgressPercent = data['filePercent'] as int?;

    final int? completedSuraId = data['lastCompletedSuraId'] as int?;
    if (completedSuraId != null) {
      lastCompletedSuraId = completedSuraId;
    }
    notifyListeners();
  }

  /// Applies the batch result sent when the task finishes.
  Future<void> _applyFinished(Map data) async {
    wasCancelled = data['wasCancelled'] as bool? ?? false;
    skippedAlreadyDownloadedCount =
        data['skipped'] as int? ?? skippedAlreadyDownloadedCount;
    unavailableCount = data['unavailable'] as int? ?? unavailableCount;
    downloadErrorMessage = data['errorMessage'] as String?;

    // The task isolate saved the new downloads; refresh this isolate's cache.
    await reloadPreferences();

    _finishJob(data['successCount'] as int? ?? 0);
  }

  /// Resets running state, shows the result, and completes the waiting call.
  void _finishJob(int successCount, {bool showSnackBar = true}) {
    isDownloading = false;
    currentSuraId = null;
    currentFileProgressPercent = null;
    notifyListeners();

    if (showSnackBar) {
      _showFinishedSnackBar(successCount, cancelled: wasCancelled);
    }

    final Completer<int>? completer = _jobCompleter;
    _jobCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(successCount);
    }
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
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _cancelReceivePort?.close();
    IsolateNameServer.removePortNameMapping(downloadCancelPortName);
    super.dispose();
  }
}
