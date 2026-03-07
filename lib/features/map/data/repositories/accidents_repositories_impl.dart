import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:eyesos/features/map/data/datasources/accidents_remote_datasource.dart';
import 'package:eyesos/features/map/data/models/accident_model.dart';
import 'package:eyesos/features/map/domain/repositories/i_accidents_repository.dart';

class AccidentsRepositoriesImpl implements IAccidentsRepository {
  final AccidentsRemoteDataSource _remoteDataSource;

  AccidentsRepositoriesImpl(this._remoteDataSource);

  @override
  Future<List<AccidentEntity>> fetchAllAccidents() async {
    final response = await _remoteDataSource.fetchAllAccidents();
    return response.map((json) => AccidentModel.fromJson(json)).toList();
  }
}
