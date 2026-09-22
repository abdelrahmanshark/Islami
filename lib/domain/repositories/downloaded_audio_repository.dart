import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/models/reciters_response.dart';

/// Contract for local Quran MP3 download metadata and file presence.
abstract class DownloadedAudioRepository {
  /// All downloads whose MediaStore files still exist.
  ///
  /// Scans device storage first so files survive app reinstall.
  Future<List<DownloadedAudio>> getValidDownloads();

  /// Valid downloads for a single reciter.
  ///
  /// [reciterName] is used to match restored files after reinstall when
  /// SharedPreferences IDs were lost.
  Future<List<DownloadedAudio>> getValidDownloadsForReciter(
    int reciterId, {
    String? reciterName,
  });

  /// Returns metadata when the file still exists; otherwise null.
  Future<DownloadedAudio?> getDownload({
    required int suraId,
    required int reciterId,
    String? reciterName,
  });

  /// True when metadata exists and the MediaStore file is still present.
  Future<bool> isDownloaded({
    required int suraId,
    required int reciterId,
    String? reciterName,
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

  /// Scans Music/Islami/Quran and rebuilds metadata for existing MP3s.
  Future<void> restoreExistingDownloads({
    List<Reciters> knownReciters = const <Reciters>[],
  });
}
