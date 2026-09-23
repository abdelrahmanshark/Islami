import 'dart:developer';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Action IDs used by the Quran download progress notification.
class DownloadNotificationActions {
  static const String cancelCurrent = 'download_cancel_current';
  static const String cancelAll = 'download_cancel_all';
}

/// Isolate port name so background notification taps can cancel downloads.
const String downloadCancelPortName = 'islami_download_cancel_port';

/// Top-level entry point for background notification actions.
/// Must stay top-level so the plugin can invoke it from a background isolate.
@pragma('vm:entry-point')
void downloadNotificationBackground(NotificationResponse response) {
  final String? actionId = response.actionId;
  if (actionId == null || actionId.isEmpty) return;

  final sendPort =
      IsolateNameServer.lookupPortByName(downloadCancelPortName);
  if (sendPort == null) {
    log('Download cancel port missing in background isolate');
    return;
  }
  sendPort.send(actionId);
}

/// Shows an ongoing notification with download progress and stop actions.
class DownloadNotificationService {
  DownloadNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int notificationId = 420;
  // v3: silent channel (no sound/vibration) while keeping stop actions.
  static const String _channelId = 'quran_download_progress_v3';
  static const String _channelName = 'تحميل القرآن';
  static const String _channelDescription =
      'حالة وتقدم تحميل سور القرآن مع إمكانية الإيقاف';

  static bool _channelReady = false;

  /// Ensures the Android notification channel exists.
  static Future<void> init() async {
    if (_channelReady) return;

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );
    _channelReady = true;
  }

  /// Shows or updates the ongoing download progress notification.
  static Future<void> showProgress({
    required String reciterName,
    required String suraLabel,
    required int completed,
    required int total,
    required bool isDownloadAll,
    int? fileProgressPercent,
  }) async {
    try {
      await init();

      final int safeTotal = total <= 0 ? 1 : total;
      final int safeCompleted = completed.clamp(0, safeTotal);
      final String progressText = '$safeCompleted/$safeTotal';
      final String body = fileProgressPercent == null
          ? 'سورة $suraLabel • $progressText'
          : 'سورة $suraLabel • $progressText • $fileProgressPercent%';

      // showsUserInterface: true → action runs on the main isolate via
      // onDidReceiveNotificationResponse (reliable while the app is alive).
      final List<AndroidNotificationAction> actions =
          <AndroidNotificationAction>[
        AndroidNotificationAction(
          DownloadNotificationActions.cancelCurrent,
          isDownloadAll ? 'إيقاف السورة' : 'إيقاف التحميل',
          showsUserInterface: true,
          cancelNotification: !isDownloadAll,
        ),
      ];
      if (isDownloadAll) {
        actions.add(
          const AndroidNotificationAction(
            DownloadNotificationActions.cancelAll,
            'إيقاف الكل',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        );
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: safeTotal,
        progress: safeCompleted,
        playSound: false,
        enableVibration: false,
        silent: true,
        category: AndroidNotificationCategory.progress,
        actions: actions,
      );

      await _plugin.show(
        id: notificationId,
        title: 'تحميل: $reciterName',
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      log('DownloadNotificationService.showProgress error: $e');
    }
  }

  /// Removes the download progress notification.
  static Future<void> dismiss() async {
    try {
      await _plugin.cancel(id: notificationId);
    } catch (e) {
      log('DownloadNotificationService.dismiss error: $e');
    }
  }
}
