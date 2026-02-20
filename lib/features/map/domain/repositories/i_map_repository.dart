import 'package:eyesos/features/map/data/models/road_risk.dart';

abstract class IMapRepository {
  Future<List<RoadSegment>> fetchRoads();
}
