// import 'package:flutter/foundation.dart';
import 'package:eyesos/features/map/data/datasources/route_remote_datasource.dart';
import 'package:eyesos/features/map/data/models/place_model.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';
import 'package:eyesos/features/map/domain/repositories/i_route_repository.dart';
import 'package:latlong2/latlong.dart';

class RouteRepositoryImpl implements IRouteRepository {
  final RouteRemoteDatasource _datasource;

  RouteRepositoryImpl(this._datasource);

  @override
  Future<List<PlaceModel>> searchPlaces(String query) async {
    try {
      return await _datasource.searchPlaces(query);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<RouteEntity> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    required String destinationName,
    List<RoadRiskEntity> roadRiskSegments = const [],
  }) async {
    try {
      final result = await _datasource.fetchRoute(
        origin: origin,
        destination: destination,
      );

      final fullPath = result.points;
      if (fullPath.isEmpty) {
        return RouteEntity(
          fullPath: [],
          coloredSegments: [],
          distanceMeters: result.distance,
          durationSeconds: result.duration,
          destinationName: destinationName,
        );
      }

      // NOTE: Multi-colored route segmentation is currently disabled for compatibility.
      // To re-enable, uncomment the code below and update the return statement.
      /*
      final coloredSegments = await compute(_segmentRouteByRisk, (
        fullPath: fullPath,
        roadRiskSegments: roadRiskSegments,
      ));
      */

      return RouteEntity(
        fullPath: fullPath,
        coloredSegments: const [], // Return empty to use simple blue line in UI
        distanceMeters: result.distance,
        durationSeconds: result.duration,
        destinationName: destinationName,
      );
    } catch (_) {
      rethrow;
    }
  }
}
