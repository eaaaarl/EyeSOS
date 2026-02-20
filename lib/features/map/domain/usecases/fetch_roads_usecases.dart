import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/repositories/i_map_repository.dart';

class FetchRoadsUseCase {
  final IMapRepository mapRepositories;

  FetchRoadsUseCase(this.mapRepositories);

  Future<List<RoadRiskEntity>> call() async {
    return await mapRepositories.fetchRoads();
  }
}
