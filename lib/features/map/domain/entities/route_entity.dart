import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RouteSegment {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final String riskLabel; // 'low', 'medium', 'high', 'unknown'

  const RouteSegment({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.riskLabel,
  });
}

class RouteEntity {
  final List<LatLng> fullPath; // raw route points from OSRM
  final List<RouteSegment> coloredSegments; // risk-colored segments
  final double distanceMeters;
  final double durationSeconds;
  final String destinationName;

  const RouteEntity({
    required this.fullPath,
    required this.coloredSegments,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.destinationName,
  });

  String get distanceText {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.toInt()} m';
  }

  String get durationText {
    final minutes = (durationSeconds / 60).ceil();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
    return '$minutes min';
  }
}
