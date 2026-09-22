import 'dart:io';

import 'package:islami/data/quran_download/downloaded_audio_local_data_source.dart';
import 'package:islami/data/quran_download/quran_media_store_data_source.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:permission_handler/permission_handler.dart';

/// Keeps download metadata in sync with MediaStore file presence.
class DownloadedAudioRepositoryImpl implements DownloadedAudioRepository {
  DownloadedAudioRepositoryImpl({
    DownloadedAudioLocalDataSource? localDataSource,
    QuranMediaStoreDataSource? mediaStoreDataSource,
  })  : _localDataSource =
            localDataSource ?? DownloadedAudioLocalDataSource(),
        _mediaStoreDataSource =
            mediaStoreDataSource ?? QuranMediaStoreDataSource();

  final DownloadedAudioLocalDataSource _localDataSource;
  final QuranMediaStoreDataSource _mediaStoreDataSource;

  static final RegExp _suraFileRegex = RegExp(
    r'^sura_(\d{3})\.mp3$',
    caseSensitive: false,
  );

  @override
  Future<List<DownloadedAudio>> getValidDownloads() async {
    // Check device storage first — metadata is wiped on reinstall.
    await restoreExistingDownloads();
    await syncDeletedFiles();
    return _localDataSource.loadAll();
  }

  @override
  Future<List<DownloadedAudio>> getValidDownloadsForReciter(
    int reciterId, {
    String? reciterName,
  }) async {
    final List<DownloadedAudio> all = await getValidDownloads();
    final String? folder = reciterName == null
        ? null
        : _mediaStoreDataSource.sanitizeReciterFolderName(reciterName);

    return all.where((item) {
      if (item.reciterId == reciterId) return true;
      if (folder == null) return false;
      return _mediaStoreDataSource.sanitizeReciterFolderName(item.reciterName) ==
          folder;
    }).toList();
  }

  @override
  Future<DownloadedAudio?> getDownload({
    required int suraId,
    required int reciterId,
    String? reciterName,
  }) async {
    final List<DownloadedAudio> items = await getValidDownloads();
    DownloadedAudio? match;
    final String? folder = reciterName == null
        ? null
        : _mediaStoreDataSource.sanitizeReciterFolderName(reciterName);

    for (final DownloadedAudio item in items) {
      if (item.suraId != suraId) continue;
      if (item.reciterId == reciterId) {
        match = item;
        break;
      }
      if (folder != null &&
          _mediaStoreDataSource.sanitizeReciterFolderName(item.reciterName) ==
              folder) {
        match = item;
        break;
      }
    }

    if (match == null) return null;

    final bool exists =
        await _mediaStoreDataSource.mediaExists(match.localUri);
    if (!exists) {
      await _localDataSource.remove(
        suraId: match.suraId,
        reciterId: match.reciterId,
      );
      return null;
    }

    return match;
  }

  @override
  Future<bool> isDownloaded({
    required int suraId,
    required int reciterId,
    String? reciterName,
  }) async {
    final DownloadedAudio? download = await getDownload(
      suraId: suraId,
      reciterId: reciterId,
      reciterName: reciterName,
    );
    return download != null;
  }

  @override
  Future<void> saveDownload(DownloadedAudio audio) {
    return _localDataSource.upsert(audio);
  }

  @override
  Future<void> removeDownload({
    required int suraId,
    required int reciterId,
    bool deleteFile = false,
  }) async {
    if (deleteFile) {
      final List<DownloadedAudio> items = await _localDataSource.loadAll();
      for (final DownloadedAudio item in items) {
        if (item.suraId == suraId && item.reciterId == reciterId) {
          await _mediaStoreDataSource.deleteMedia(item.localUri);
          break;
        }
      }
    }

    await _localDataSource.remove(suraId: suraId, reciterId: reciterId);
  }

  @override
  Future<void> syncDeletedFiles() async {
    final List<DownloadedAudio> items = await _localDataSource.loadAll();
    if (items.isEmpty) return;

    final List<DownloadedAudio> stillPresent = <DownloadedAudio>[];

    for (final DownloadedAudio item in items) {
      final bool exists =
          await _mediaStoreDataSource.mediaExists(item.localUri);
      if (exists) {
        stillPresent.add(item);
      }
    }

    if (stillPresent.length != items.length) {
      await _localDataSource.saveAll(stillPresent);
    }
  }

  @override
  Future<void> restoreExistingDownloads({
    List<Reciters> knownReciters = const <Reciters>[],
  }) async {
    await _ensureReadAudioPermission();

    final List<Map<String, dynamic>> scanned =
        await _mediaStoreDataSource.listExistingQuranAudio();
    if (scanned.isEmpty) return;

    final Map<String, int> reciterIdByFolder = <String, int>{};
    for (final Reciters reciter in knownReciters) {
      final int? id = reciter.id;
      final String? name = reciter.name;
      if (id == null || name == null || name.trim().isEmpty) continue;
      final String folder =
          _mediaStoreDataSource.sanitizeReciterFolderName(name);
      reciterIdByFolder[folder] = id;
    }

    final List<DownloadedAudio> existing = await _localDataSource.loadAll();
    final Map<String, DownloadedAudio> byKey = <String, DownloadedAudio>{
      for (final DownloadedAudio item in existing)
        _downloadKey(item.reciterId, item.suraId): item,
    };

    // Also index by folder+sura so restored hash IDs can rematch API IDs.
    final Map<String, DownloadedAudio> byFolderSura =
        <String, DownloadedAudio>{};
    for (final DownloadedAudio item in existing) {
      final String folder =
          _mediaStoreDataSource.sanitizeReciterFolderName(item.reciterName);
      byFolderSura['$folder|${item.suraId}'] = item;
    }

    bool changed = false;

    for (final Map<String, dynamic> file in scanned) {
      final DownloadedAudio? parsed = _parseScannedFile(
        file,
        reciterIdByFolder: reciterIdByFolder,
      );
      if (parsed == null) continue;

      final String folder =
          _mediaStoreDataSource.sanitizeReciterFolderName(parsed.reciterName);
      final String folderKey = '$folder|${parsed.suraId}';
      final DownloadedAudio? existingByFolder = byFolderSura[folderKey];

      if (existingByFolder != null) {
        // Keep known API id when possible; refresh URI if path changed.
        final int resolvedId =
            reciterIdByFolder[folder] ?? existingByFolder.reciterId;
        final DownloadedAudio updated = existingByFolder.copyWith(
          reciterId: resolvedId,
          reciterName: parsed.reciterName,
          localUri: parsed.localUri,
          fileSizeBytes: parsed.fileSizeBytes,
        );
        if (updated.reciterId != existingByFolder.reciterId ||
            updated.localUri != existingByFolder.localUri ||
            updated.reciterName != existingByFolder.reciterName) {
          byKey.remove(
            _downloadKey(existingByFolder.reciterId, existingByFolder.suraId),
          );
          byKey[_downloadKey(updated.reciterId, updated.suraId)] = updated;
          byFolderSura[folderKey] = updated;
          changed = true;
        }
        continue;
      }

      final String key = _downloadKey(parsed.reciterId, parsed.suraId);
      if (!byKey.containsKey(key)) {
        byKey[key] = parsed;
        byFolderSura[folderKey] = parsed;
        changed = true;
      }
    }

    if (changed) {
      await _localDataSource.saveAll(byKey.values.toList());
    }
  }

  /// Builds metadata from one scanned Music/Islami/Quran file.
  DownloadedAudio? _parseScannedFile(
    Map<String, dynamic> file, {
    required Map<String, int> reciterIdByFolder,
  }) {
    final String? displayName = file['displayName'] as String?;
    final String? relativePath = file['relativePath'] as String?;
    final String? localUri = file['uri'] as String?;
    if (displayName == null || relativePath == null || localUri == null) {
      return null;
    }

    final Match? match = _suraFileRegex.firstMatch(displayName);
    if (match == null) return null;

    final int? suraId = int.tryParse(match.group(1)!);
    if (suraId == null || suraId < 1 || suraId > 114) return null;

    final String folder = _folderNameFromRelativePath(relativePath);
    if (folder.isEmpty) return null;

    final int reciterId =
        reciterIdByFolder[folder] ?? _stableIdFromFolderName(folder);

    final int fileSizeBytes = _asInt(file['size']) ?? 0;
    final int dateMs = _asInt(file['dateAdded']) ?? 0;
    final DateTime downloadedAt = dateMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(dateMs)
        : DateTime.now();

    return DownloadedAudio(
      suraId: suraId,
      reciterId: reciterId,
      reciterName: folder,
      localUri: localUri,
      fileSizeBytes: fileSizeBytes,
      downloadedAt: downloadedAt,
    );
  }

  /// Last folder segment from Music/Islami/Quran/{reciter}.
  String _folderNameFromRelativePath(String relativePath) {
    final String trimmed = relativePath.trim().replaceAll('\\', '/');
    final List<String> parts =
        trimmed.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.last;
  }

  /// Stable positive id when the API reciter list is not available yet.
  int _stableIdFromFolderName(String folderName) {
    return folderName.hashCode & 0x7fffffff;
  }

  String _downloadKey(int reciterId, int suraId) => '$reciterId|$suraId';

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  /// Requests read access so we can see MP3s left after uninstall.
  Future<void> _ensureReadAudioPermission() async {
    if (!Platform.isAndroid) return;

    // Android 13+: READ_MEDIA_AUDIO. Older: READ_EXTERNAL_STORAGE.
    final PermissionStatus audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted || audioStatus.isLimited) return;

    final PermissionStatus storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted || storageStatus.isLimited) return;

    final PermissionStatus audioResult = await Permission.audio.request();
    if (audioResult.isGranted || audioResult.isLimited) return;

    await Permission.storage.request();
  }
}
