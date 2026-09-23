import 'package:islami/data/radio/mshary_local_data_source.dart';
import 'package:islami/data/radio/radio_remote_data_source.dart';
import 'package:islami/domain/repositories/radio_repository.dart';
import 'package:islami/models/radio_response.dart';
import 'package:islami/models/reciters_response.dart';

class RadioRepositoryImpl implements RadioRepository {
  RadioRepositoryImpl({
    RadioRemoteDataSource? dataSource,
    MsharyLocalDataSource? msharyLocalDataSource,
  })  : _dataSource = dataSource ?? RadioRemoteDataSource(),
        _msharyLocalDataSource =
            msharyLocalDataSource ?? MsharyLocalDataSource();

  final RadioRemoteDataSource _dataSource;
  final MsharyLocalDataSource _msharyLocalDataSource;

  @override
  Future<List<Radios>> getRadios() async {
    final response = await _dataSource.fetchRadios();
    return response.radios ?? [];
  }

  @override
  Future<List<Reciters>> getReciters() async {
    final response = await _dataSource.fetchReciters();
    final List<Reciters> fromApi = response.reciters ?? [];
    final Reciters mashary = await _msharyLocalDataSource.loadReciter();

    // Drop the old API مشاري العفاسي (and any API duplicate of the new name).
    final List<Reciters> filtered = fromApi.where((reciter) {
      final String name = reciter.name?.trim() ?? '';
      return name != MsharyLocalDataSource.oldApiReciterName &&
          name != mashary.name;
    }).toList();

    // Local mashary replaces the removed API entry at the top of the list.
    return <Reciters>[mashary, ...filtered];
  }
}
