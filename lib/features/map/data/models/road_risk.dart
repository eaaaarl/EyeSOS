import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum RiskLevel { critical, high, moderate, minor, none }

extension RiskLevelX on RiskLevel {
  Color get color {
    switch (this) {
      case RiskLevel.critical:
        return const Color(0xFFdc2626);
      case RiskLevel.high:
        return const Color(0xFFea580c);
      case RiskLevel.moderate:
        return const Color(0xFFca8a04);
      case RiskLevel.minor:
        return const Color(0xFF16a34a);
      case RiskLevel.none:
        return const Color(0xFF3b82f6);
    }
  }

  double get strokeWidth {
    switch (this) {
      case RiskLevel.critical:
        return 7;
      case RiskLevel.high:
        return 6;
      case RiskLevel.moderate:
        return 5;
      case RiskLevel.minor:
        return 4;
      case RiskLevel.none:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.critical:
        return 'Critical';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.minor:
        return 'Minor';
      case RiskLevel.none:
        return 'None';
    }
  }
}

class RoadSegment {
  final int id;
  final String name;
  final List<LatLng> coordinates;
  final RiskLevel riskLevel;
  final int riskScore;
  final int accidentCount;

  const RoadSegment({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.riskLevel,
    required this.riskScore,
    required this.accidentCount,
  });
}
