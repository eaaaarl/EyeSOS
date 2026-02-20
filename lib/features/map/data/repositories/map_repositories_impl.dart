import 'package:eyesos/features/map/data/datasources/map_remote_datasource.dart';
import 'package:eyesos/features/map/data/models/road_risk_model.dart';
import 'package:eyesos/features/map/domain/repositories/i_map_repository.dart';

class IMapRepositoryImpl implements IMapRepository {
  final MapRemoteDatasource remoteDatasource;

  IMapRepositoryImpl(this.remoteDatasource);
  @override
  Future<List<RoadRiskModel>> fetchRoads() async {
    try {
      return await remoteDatasource.fetchRoads();
    } catch (e) {
      rethrow;
    }
  }
}
