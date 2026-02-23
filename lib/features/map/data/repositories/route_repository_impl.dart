import 'package:eyesos/features/map/data/datasources/route_remote_datasource.dart';
import 'package:eyesos/features/map/data/models/place_model.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';
import 'package:eyesos/features/map/domain/repositories/i_route_repository.dart';
import 'package:flutter/material.dart';
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

      final List<RouteSegment> coloredSegments = [];
      if (roadRiskSegments.isEmpty) {
        coloredSegments.add(
          RouteSegment(
            points: fullPath,
            color: const Color(0xFF1565C0),
            strokeWidth: 5.0,
            riskLabel: 'unknown',
          ),
        );
      } else {
        // Simple segmentation: for each consecutive pair of points,
        // find the highest risk among all intersecting/nearby roads.
        const double threshold = 50.0; // meters
        const distance = Distance();

        var currentPoints = <LatLng>[fullPath.first];
        RiskLevel? currentRisk;

        for (int i = 0; i < fullPath.length - 1; i++) {
          final p1 = fullPath[i];
          final p2 = fullPath[i + 1];

          // Find if this segment (p1->p2) matches any risk road.
          // For simplicity, we check the midpoint or just the first point.
          final midPoint = LatLng(
            (p1.latitude + p2.latitude) / 2,
            (p1.longitude + p2.longitude) / 2,
          );

          RiskLevel? highestRisk;
          for (final road in roadRiskSegments) {
            bool matches = false;
            for (final roadPoint in road.coordinates) {
              if (distance.as(LengthUnit.Meter, midPoint, roadPoint) <=
                  threshold) {
                matches = true;
                break;
              }
            }
            if (matches) {
              if (highestRisk == null ||
                  road.riskLevel.index > highestRisk.index) {
                highestRisk = road.riskLevel;
              }
            }
          }

          // If risk level changed, start a new segment
          if (highestRisk != currentRisk && i > 0) {
            coloredSegments.add(
              RouteSegment(
                points: List.from(currentPoints),
                color: currentRisk?.color ?? const Color(0xFF1565C0),
                strokeWidth: currentRisk?.strokeWidth ?? 5.0,
                riskLabel: currentRisk?.label ?? 'low',
              ),
            );
            currentPoints = [p1];
          }

          currentPoints.add(p2);
          currentRisk = highestRisk;
        }

        // Add the last segment
        if (currentPoints.isNotEmpty) {
          coloredSegments.add(
            RouteSegment(
              points: currentPoints,
              color: currentRisk?.color ?? const Color(0xFF1565C0),
              strokeWidth: currentRisk?.strokeWidth ?? 5.0,
              riskLabel: currentRisk?.label ?? 'low',
            ),
          );
        }
      }

      return RouteEntity(
        fullPath: fullPath,
        coloredSegments: coloredSegments,
        distanceMeters: result.distance,
        durationSeconds: result.duration,
        destinationName: destinationName,
      );
    } catch (_) {
      rethrow;
    }
  }
}
