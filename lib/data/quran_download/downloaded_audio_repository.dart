import 'package:islami/data/quran_download/downloaded_audio_local_data_source.dart';
import 'package:islami/data/quran_download/quran_media_store_data_source.dart';
import 'package:islami/domain/repositories/downloaded_audio_repository.dart';
import 'package:islami/models/downloaded_audio.dart';

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

  @override
  Future<List<DownloadedAudio>> getValidDownloads() async {
    await syncDeletedFiles();
    return _localDataSource.loadAll();
  }

  @override
  Future<List<DownloadedAudio>> getValidDownloadsForReciter(
    int reciterId,
  ) async {
    final List<DownloadedAudio> all = await getValidDownloads();
    return all.where((item) => item.reciterId == reciterId).toList();
  }

  @override
  Future<DownloadedAudio?> getDownload({
    required int suraId,
    required int reciterId,
  }) async {
    final List<DownloadedAudio> items = await _localDataSource.loadAll();
    DownloadedAudio? match;
    for (final DownloadedAudio item in items) {
      if (item.suraId == suraId && item.reciterId == reciterId) {
        match = item;
        break;
      }
    }

    if (match == null) return null;

    final bool exists =
        await _mediaStoreDataSource.mediaExists(match.localUri);
    if (!exists) {
      await _localDataSource.remove(suraId: suraId, reciterId: reciterId);
      return null;
    }

    return match;
  }

  @override
  Future<bool> isDownloaded({
    required int suraId,
    required int reciterId,
  }) async {
    final DownloadedAudio? download = await getDownload(
      suraId: suraId,
      reciterId: reciterId,
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
}
