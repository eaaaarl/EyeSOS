import 'package:eyesos/features/map/data/models/place_model.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';
import 'package:latlong2/latlong.dart';

abstract class IRouteRepository {
  /// Search places by query string (geocoding).
  Future<List<PlaceModel>> searchPlaces(String query);

  /// Fetch a routed path between [origin] and [destination]
  /// and return a [RouteEntity] ready for the UI.
  Future<RouteEntity> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    required String destinationName,
    List<RoadRiskEntity> roadRiskSegments = const [],
  });
}
