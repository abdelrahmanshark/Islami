import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Accesses Quran MP3 files in Android shared storage via MediaStore.
///
/// Files live under Music/Islami/Quran/{reciterName}. Does not download audio
/// itself — only checks, deletes, and inserts MediaStore entries.
class QuranMediaStoreDataSource {
  QuranMediaStoreDataSource({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.example.islami/quran_storage');

  final MethodChannel _channel;

  /// Relative Music path used when inserting MediaStore audio rows.
  static const String quranAudioRelativePath = 'Music/Islami/Quran';

  /// True when [contentUri] still points to a readable MediaStore file.
  Future<bool> mediaExists(String contentUri) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (contentUri.isEmpty) return false;

    try {
      final result = await _channel.invokeMethod<dynamic>(
        'mediaExists',
        <String, dynamic>{'uri': contentUri},
      );
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  /// Deletes the MediaStore row for [contentUri]. Returns true when removed.
  Future<bool> deleteMedia(String contentUri) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (contentUri.isEmpty) return false;

    try {
      final result = await _channel.invokeMethod<dynamic>(
        'deleteMedia',
        <String, dynamic>{'uri': contentUri},
      );
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  /// Copies a local temp file into shared Music storage. Returns content URI.
  Future<String?> saveAudioFromPath({
    required String sourcePath,
    required String displayName,
    required String relativePath,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<dynamic>(
        'saveAudioFromPath',
        <String, dynamic>{
          'sourcePath': sourcePath,
          'displayName': displayName,
          'relativePath': relativePath,
        },
      );
      if (result is String && result.isNotEmpty) {
        return result;
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Builds a display name for a sura MP3 (e.g. sura_001.mp3).
  String buildDisplayName({required int suraId}) {
    final String suraPart = suraId.toString().padLeft(3, '0');
    return 'sura_$suraPart.mp3';
  }

  /// Sanitizes a reciter name for use as a folder name.
  String sanitizeReciterFolderName(String reciterName) {
    final String trimmed = reciterName.trim();
    if (trimmed.isEmpty) return 'unknown_reciter';

    final String cleaned = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'unknown_reciter' : cleaned;
  }

  /// Relative MediaStore path for a reciter's Quran folder.
  String relativePathForReciter(String reciterName) {
    final String folder = sanitizeReciterFolderName(reciterName);
    return '$quranAudioRelativePath/$folder';
  }

  /// Lists Quran MP3s already on the device under Music/Islami/Quran.
  Future<List<Map<String, dynamic>>> listExistingQuranAudio() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return <Map<String, dynamic>>[];
    }

    try {
      final result = await _channel.invokeMethod<dynamic>('listQuranAudio');
      if (result is! List) return <Map<String, dynamic>>[];

      return result
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on PlatformException {
      return <Map<String, dynamic>>[];
    }
  }

  /// Finds one existing Quran MP3 by display name and relative folder.
  Future<Map<String, dynamic>?> findExistingQuranAudio({
    required String displayName,
    required String relativePath,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<dynamic>(
        'findQuranAudio',
        <String, dynamic>{
          'displayName': displayName,
          'relativePath': relativePath,
        },
      );
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException {
      return null;
    }
  }
}
