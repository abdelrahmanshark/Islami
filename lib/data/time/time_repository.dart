import 'package:islami/data/time/time_remote_data_source.dart';
import 'package:islami/domain/repositories/time_repository.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';

class TimeRepositoryImpl implements TimeRepository {
  TimeRepositoryImpl({TimeRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? TimeRemoteDataSource();

  final TimeRemoteDataSource _dataSource;

  @override
  Future<TimeResponse> getTimeResponse() {
    return _dataSource.fetchTimeResponse();
  }
}
