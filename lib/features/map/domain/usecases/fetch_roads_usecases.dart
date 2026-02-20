import 'package:eyesos/features/map/data/models/road_risk.dart';
import 'package:eyesos/features/map/domain/repositories/i_map_repository.dart';

class FetchRoadsUseCase {
  final IMapRepository mapRepositories;

  FetchRoadsUseCase(this.mapRepositories);

  Future<List<RoadSegment>> call() async {
    return await mapRepositories.fetchRoads();
  }
}
