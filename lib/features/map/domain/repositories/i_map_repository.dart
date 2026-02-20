import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';

abstract class IMapRepository {
  Future<List<RoadRiskEntity>> fetchRoads();
}
