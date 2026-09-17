import 'package:islami/data/radio/radio_remote_data_source.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/radio_response.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/reciters_response.dart';

abstract class RadioRepository {
  Future<List<Radios>> getRadios();

  Future<List<Reciters>> getReciters();
}

class RadioRepositoryImpl implements RadioRepository {
  RadioRepositoryImpl({RadioRemoteDataSource? dataSource})
    : _dataSource = dataSource ?? RadioRemoteDataSource();

  final RadioRemoteDataSource _dataSource;

  @override
  Future<List<Radios>> getRadios() async {
    final response = await _dataSource.fetchRadios();
    return response.radios ?? [];
  }

  @override
  Future<List<Reciters>> getReciters() async {
    final response = await _dataSource.fetchReciters();
    return response.reciters ?? [];
  }
}
