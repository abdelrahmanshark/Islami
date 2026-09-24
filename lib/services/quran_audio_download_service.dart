import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:islami/data/quran_download/downloaded_audio_repository.dart';
import 'package:islami/data/quran_download/quran_media_store_data_source.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/device_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thrown when the user stops an in-progress download.
class DownloadCancelledException implements Exception {
  @override
  String toString() => 'Download cancelled';
}

/// Thrown when the remote audio file is missing or the server fails.
class AudioUnavailableException implements Exception {
  static const String userMessage = 'نتأسف هذا الملف لايمكن تحميله حاليا';

  @override
  String toString() => userMessage;
}

/// Thrown when the sura is already saved on the device.
class AlreadyDownloadedException implements Exception {
  static const String userMessage = 'هذا الملف محمّل مسبقاً';

  @override
  String toString() => userMessage;
}

/// Downloads Quran MP3s to shared MediaStore storage (not app-private).
class QuranAudioDownloadService {
  QuranAudioDownloadService({
    DownloadedAudioRepository? downloadedAudioRepository,
    QuranMediaStoreDataSource? mediaStoreDataSource,
    DeviceStorageService? deviceStorageService,
    http.Client? httpClient,
  })  : _downloadedAudioRepository =
            downloadedAudioRepository ?? DownloadedAudioRepositoryImpl(),
        _mediaStoreDataSource =
            mediaStoreDataSource ?? QuranMediaStoreDataSource(),
        _deviceStorageService =
            deviceStorageService ?? DeviceStorageService(),
        _httpClient = httpClient ?? http.Client();

  final DownloadedAudioRepository _downloadedAudioRepository;
  final QuranMediaStoreDataSource _mediaStoreDataSource;
  final DeviceStorageService _deviceStorageService;
  final http.Client _httpClient;

  /// How long to wait for the server to start responding.
  static const Duration _connectTimeout = Duration(seconds: 20);

  /// How long to wait between stream chunks before treating as stalled.
  static const Duration _streamIdleTimeout = Duration(seconds: 30);

  /// Completer used to abort the current HTTP download.
  Completer<void>? _abortTrigger;

  /// True when abort was triggered by a timeout / server failure (not the user).
  bool _abortedDueToFailure = false;

  /// Stops the current in-progress HTTP download, if any.
  void cancelActiveDownload() {
    final Completer<void>? trigger = _abortTrigger;
    if (trigger != null && !trigger.isCompleted) {
      trigger.complete();
    }
  }

  /// Aborts the active request because the server stalled or failed.
  void _abortDueToFailure() {
    _abortedDueToFailure = true;
    cancelActiveDownload();
  }

  /// Maps an abort into cancel vs unavailable, depending on who triggered it.
  Never _throwForAbort() {
    if (_abortedDueToFailure) {
      throw AudioUnavailableException();
    }
    throw DownloadCancelledException();
  }

  /// Downloads one sura for [reciter] into Music/Islami/Quran/{reciterName}.
  /// [onProgress] reports bytes received and optional total content length.
  Future<DownloadedAudio> downloadSura({
    required Reciters reciter,
    required int suraId,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final int? reciterId = reciter.id;
    final String? server = reciter.server;
    final String reciterName = reciter.name?.trim() ?? '';

    if (reciterId == null || server == null || server.isEmpty) {
      throw StateError('Reciter data is incomplete');
    }
    if (suraId < 1 || suraId > 114) {
      throw ArgumentError('suraId must be between 1 and 114');
    }

    final bool alreadyDownloaded =
        await _downloadedAudioRepository.isDownloaded(
      suraId: suraId,
      reciterId: reciterId,
      reciterName: reciterName,
    );
    if (alreadyDownloaded) {
      throw AlreadyDownloadedException();
    }

    // After reinstall, metadata may be gone while the MP3 still exists.
    final String displayName =
        _mediaStoreDataSource.buildDisplayName(suraId: suraId);
    final String relativePath =
        _mediaStoreDataSource.relativePathForReciter(reciterName);
    final Map<String, dynamic>? onDevice =
        await _mediaStoreDataSource.findExistingQuranAudio(
      displayName: displayName,
      relativePath: relativePath,
    );
    if (onDevice != null) {
      final String? localUri = onDevice['uri'] as String?;
      if (localUri != null && localUri.isNotEmpty) {
        final int fileSizeBytes = onDevice['size'] is num
            ? (onDevice['size'] as num).toInt()
            : 0;
        final int dateMs = onDevice['dateAdded'] is num
            ? (onDevice['dateAdded'] as num).toInt()
            : 0;
        final DownloadedAudio restored = DownloadedAudio(
          suraId: suraId,
          reciterId: reciterId,
          reciterName: reciterName,
          localUri: localUri,
          fileSizeBytes: fileSizeBytes,
          downloadedAt: dateMs > 0
              ? DateTime.fromMillisecondsSinceEpoch(dateMs)
              : DateTime.now(),
        );
        await _downloadedAudioRepository.saveDownload(restored);
        throw AlreadyDownloadedException();
      }
    }

    final String paddedSura = suraId.toString().padLeft(3, '0');
    final Uri remoteUri = Uri.parse('$server$paddedSura.mp3');
    final File tempFile = File(
      '${Directory.systemTemp.path}/islami_quran_${reciterId}_$paddedSura.mp3',
    );

    final Completer<void> abortTrigger = Completer<void>();
    _abortTrigger = abortTrigger;
    _abortedDueToFailure = false;

    try {
      final http.AbortableRequest request = http.AbortableRequest(
        'GET',
        remoteUri,
        abortTrigger: abortTrigger.future,
      );

      final http.StreamedResponse response;
      try {
        response = await _httpClient.send(request).timeout(
          _connectTimeout,
          onTimeout: () {
            _abortDueToFailure();
            throw TimeoutException(
              'Server did not respond in time',
              _connectTimeout,
            );
          },
        );
      } on http.RequestAbortedException {
        _throwForAbort();
      } on TimeoutException {
        throw AudioUnavailableException();
      } on SocketException {
        throw AudioUnavailableException();
      } on http.ClientException {
        throw AudioUnavailableException();
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AudioUnavailableException();
      }

      final int? contentLength = response.contentLength;
      if (contentLength != null && contentLength > 0) {
        final bool hasSpace =
            await _deviceStorageService.hasEnoughSpace(contentLength);
        if (!hasSpace) {
          throw StateError('Not enough storage space');
        }
      }

      final IOSink sink = tempFile.openWrite();
      int receivedBytes = 0;
      try {
        await response.stream
            .timeout(
              _streamIdleTimeout,
              onTimeout: (EventSink<List<int>> eventSink) {
                _abortDueToFailure();
                eventSink.addError(
                  TimeoutException(
                    'Download stalled',
                    _streamIdleTimeout,
                  ),
                );
              },
            )
            .listen((List<int> chunk) {
              sink.add(chunk);
              receivedBytes += chunk.length;
              onProgress?.call(receivedBytes, contentLength);
            })
            .asFuture<void>();
      } on http.RequestAbortedException {
        _throwForAbort();
      } on TimeoutException {
        throw AudioUnavailableException();
      } on SocketException {
        throw AudioUnavailableException();
      } on http.ClientException {
        throw AudioUnavailableException();
      } finally {
        await sink.close();
      }

      if (abortTrigger.isCompleted) {
        _throwForAbort();
      }

      final int fileSize = await tempFile.length();
      if (fileSize <= 0) {
        throw AudioUnavailableException();
      }

      final bool hasSpaceForFile =
          await _deviceStorageService.hasEnoughSpace(fileSize);
      if (!hasSpaceForFile) {
        throw StateError('Not enough storage space');
      }

      final String? localUri = await _mediaStoreDataSource.saveAudioFromPath(
        sourcePath: tempFile.path,
        displayName: displayName,
        relativePath: relativePath,
      );

      if (localUri == null || localUri.isEmpty) {
        throw StateError('Could not save audio to shared storage');
      }

      final DownloadedAudio audio = DownloadedAudio(
        suraId: suraId,
        reciterId: reciterId,
        reciterName: reciterName,
        localUri: localUri,
        fileSizeBytes: fileSize,
        downloadedAt: DateTime.now(),
      );
      await _downloadedAudioRepository.saveDownload(audio);
      return audio;
    } finally {
      if (_abortTrigger == abortTrigger) {
        _abortTrigger = null;
      }
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {
          // Temp cleanup is best-effort.
        }
      }
    }
  }

  /// Asks for storage permission only on Android 9 and older (Android 10+
  /// MediaStore writes need none). Call from UI code only: the dialog needs a
  /// visible screen and would block forever in the background.
  Future<bool> requestLegacyStoragePermissionIfNeeded() async {
    final bool needed =
        await _mediaStoreDataSource.needsLegacyStoragePermission();
    if (!needed) return true;

    final PermissionStatus status = await Permission.storage.request();
    return status.isGranted;
  }
}
