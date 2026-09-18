import 'package:islami/data/azkar/azkar_local_data_source.dart';
import 'package:islami/domain/repositories/azkar_repository.dart';
import 'package:islami/models/azkar_response.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  AzkarRepositoryImpl({AzkarLocalDataSource? dataSource})
      : _dataSource = dataSource ?? AzkarLocalDataSource();

  final AzkarLocalDataSource _dataSource;

  @override
  Future<AzkarResponse> getAzkar() {
    return _dataSource.fetchAzkar();
  }
}
