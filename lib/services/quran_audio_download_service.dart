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

  /// Completer used to abort the current HTTP download.
  Completer<void>? _abortTrigger;

  /// Stops the current in-progress HTTP download, if any.
  void cancelActiveDownload() {
    final Completer<void>? trigger = _abortTrigger;
    if (trigger != null && !trigger.isCompleted) {
      trigger.complete();
    }
  }

  /// Downloads one sura for [reciter] into Music/Islami/Quran/{reciterName}.
  Future<DownloadedAudio> downloadSura({
    required Reciters reciter,
    required int suraId,
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

    await _ensureLegacyStoragePermission();

    final bool alreadyDownloaded =
        await _downloadedAudioRepository.isDownloaded(
      suraId: suraId,
      reciterId: reciterId,
      reciterName: reciterName,
    );
    if (alreadyDownloaded) {
      final DownloadedAudio? existing =
          await _downloadedAudioRepository.getDownload(
        suraId: suraId,
        reciterId: reciterId,
        reciterName: reciterName,
      );
      if (existing != null) return existing;
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
        return restored;
      }
    }

    final String paddedSura = suraId.toString().padLeft(3, '0');
    final Uri remoteUri = Uri.parse('$server$paddedSura.mp3');
    final File tempFile = File(
      '${Directory.systemTemp.path}/islami_quran_${reciterId}_$paddedSura.mp3',
    );

    final Completer<void> abortTrigger = Completer<void>();
    _abortTrigger = abortTrigger;

    try {
      final http.AbortableRequest request = http.AbortableRequest(
        'GET',
        remoteUri,
        abortTrigger: abortTrigger.future,
      );

      final http.StreamedResponse response;
      try {
        response = await _httpClient.send(request);
      } on http.RequestAbortedException {
        throw DownloadCancelledException();
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with status ${response.statusCode}',
          uri: remoteUri,
        );
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
      try {
        await response.stream.listen(sink.add).asFuture<void>();
      } on http.RequestAbortedException {
        throw DownloadCancelledException();
      } finally {
        await sink.close();
      }

      if (abortTrigger.isCompleted) {
        throw DownloadCancelledException();
      }

      final int fileSize = await tempFile.length();
      if (fileSize <= 0) {
        throw StateError('Downloaded file is empty');
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

  /// Requests WRITE_EXTERNAL_STORAGE on older Android when still needed.
  Future<void> _ensureLegacyStoragePermission() async {
    if (!Platform.isAndroid) return;

    final PermissionStatus status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) return;

    // On Android 10+ MediaStore writes do not need this permission.
    await Permission.storage.request();
  }
}
