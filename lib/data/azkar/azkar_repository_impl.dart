import 'package:injectable/injectable.dart';
import 'package:islami/data/azkar/azkar_local_data_source.dart';
import 'package:islami/domain/repositories/azkar_repository.dart';
import 'package:islami/models/azkar_response.dart';

@LazySingleton(as: AzkarRepository)
class AzkarRepositoryImpl implements AzkarRepository {
  AzkarRepositoryImpl(this._dataSource);

  final AzkarLocalDataSource _dataSource;

  @override
  Future<AzkarResponse> getAzkar() {
    return _dataSource.fetchAzkar();
  }
}
