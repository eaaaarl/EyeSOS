import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';
import 'package:eyesos/features/map/domain/repositories/i_route_repository.dart';
import 'package:latlong2/latlong.dart';

class FetchRouteUseCase {
  final IRouteRepository _repository;

  FetchRouteUseCase(this._repository);

  Future<RouteEntity> call({
    required LatLng origin,
    required LatLng destination,
    required String destinationName,
    List<RoadRiskEntity> roadRiskSegments = const [],
  }) async {
    return _repository.fetchRoute(
      origin: origin,
      destination: destination,
      destinationName: destinationName,
      roadRiskSegments: roadRiskSegments,
    );
  }
}
