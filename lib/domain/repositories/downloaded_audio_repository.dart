import 'package:islami/models/downloaded_audio.dart';

/// Contract for local Quran MP3 download metadata and file presence.
abstract class DownloadedAudioRepository {
  /// All downloads whose MediaStore files still exist.
  Future<List<DownloadedAudio>> getValidDownloads();

  /// Valid downloads for a single reciter.
  Future<List<DownloadedAudio>> getValidDownloadsForReciter(int reciterId);

  /// Returns metadata when the file still exists; otherwise null.
  Future<DownloadedAudio?> getDownload({
    required int suraId,
    required int reciterId,
  });

  /// True when metadata exists and the MediaStore file is still present.
  Future<bool> isDownloaded({
    required int suraId,
    required int reciterId,
  });

  /// Saves or updates local download metadata (call after a future download).
  Future<void> saveDownload(DownloadedAudio audio);

  /// Removes metadata and optionally the MediaStore file.
  Future<void> removeDownload({
    required int suraId,
    required int reciterId,
    bool deleteFile = false,
  });

  /// Drops metadata for files the user deleted outside the app.
  Future<void> syncDeletedFiles();
}
