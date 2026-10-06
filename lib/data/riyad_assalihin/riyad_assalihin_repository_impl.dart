import 'package:injectable/injectable.dart';
import 'package:islami/data/riyad_assalihin/riyad_assalihin_local_data_source.dart';
import 'package:islami/domain/repositories/riyad_assalihin_repository.dart';
import 'package:islami/models/riyad_assalihin.dart';

@LazySingleton(as: RiyadAssalihinRepository)
class RiyadAssalihinRepositoryImpl implements RiyadAssalihinRepository {
  RiyadAssalihinRepositoryImpl(this._dataSource);

  final RiyadAssalihinLocalDataSource _dataSource;

  /// Returns all chapters with their hadiths from the local data source.
  @override
  Future<RiyadAssalihinModel> getRiyadAssalihin() {
    return _dataSource.fetchRiyadAssalihin();
  }
}
