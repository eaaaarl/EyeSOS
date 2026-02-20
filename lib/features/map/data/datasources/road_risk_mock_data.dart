import 'package:eyesos/features/map/data/models/road_risk.dart';
import 'package:latlong2/latlong.dart';

class RoadRiskMockData {
  static const highRiskKeywords = [
    'national highway',
    'surigao-davao coastal road',
    'bayugan',
    'canitlan',
  ];

  static const moderateRiskKeywords = [
    'poblacion',
    'lianga',
    'st. christine',
    'diatagon',
  ];

  static RiskLevel scoreToRisk(int score) {
    if (score >= 75) return RiskLevel.critical;
    if (score >= 50) return RiskLevel.high;
    if (score >= 25) return RiskLevel.moderate;
    if (score >= 10) return RiskLevel.minor;
    return RiskLevel.none;
  }

  static int getPeakHourAdjustedScore(int base, int hour) {
    if (hour >= 6 && hour < 9) return (base * 1.3).clamp(0, 100).toInt();
    if (hour >= 17 && hour < 20) return (base * 1.2).clamp(0, 100).toInt();
    if (hour >= 21 || hour < 1) return (base * 1.15).clamp(0, 100).toInt();
    return base;
  }

  static List<int> getHourlyScores(int wayId, String name) {
    final n = name.toLowerCase();
    List<int> hourlyScores = [];

    for (int hour = 0; hour < 24; hour++) {
      int base;
      if (highRiskKeywords.any((k) => n.contains(k))) {
        final isCritical = wayId % 3 == 0;
        base = isCritical ? 75 + (wayId % 20) : 55 + (wayId % 20);
      } else if (moderateRiskKeywords.any((k) => n.contains(k))) {
        base = 35 + (wayId % 20);
      } else {
        final roll = wayId % 10;
        if (roll < 1) {
          base = 80 + (wayId % 15);
        } else if (roll < 3) {
          base = 55 + (wayId % 20);
        } else if (roll < 5) {
          base = 30 + (wayId % 25);
        } else if (roll < 7) {
          base = 10 + (wayId % 20);
        } else {
          base = wayId % 10;
        }
      }
      hourlyScores.add(getPeakHourAdjustedScore(base, hour));
    }
    return hourlyScores;
  }

  // Returns the safest hour range label
  static String getSafestTimeLabel(int wayId, String name) {
    final scores = getHourlyScores(wayId, name);
    int minScore = 999;
    int safestHour = 0;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] < minScore) {
        minScore = scores[i];
        safestHour = i;
      }
    }
    return _formatHour(safestHour);
  }

  // Returns the peak (most dangerous) hour label
  static String getPeakTimeLabel(int wayId, String name) {
    final scores = getHourlyScores(wayId, name);
    int maxScore = 0;
    int peakHour = 0;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        peakHour = i;
      }
    }
    return _formatHour(peakHour);
  }

  static String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:00 $period';
  }

  static RoadSegment assignMockRisk(
    int wayId,
    String name,
    List<LatLng> coords,
  ) {
    final n = name.toLowerCase();
    final hour = DateTime.now().hour;

    int base;
    int accidents;

    if (highRiskKeywords.any((k) => n.contains(k))) {
      final isCritical = wayId % 3 == 0;
      base = isCritical ? 75 + (wayId % 20) : 55 + (wayId % 20);
      accidents = isCritical ? 8 + (wayId % 7) : 4 + (wayId % 5);
    } else if (moderateRiskKeywords.any((k) => n.contains(k))) {
      base = 35 + (wayId % 20);
      accidents = 2 + (wayId % 4);
    } else {
      final roll = wayId % 10;
      if (roll < 1) {
        base = 80 + (wayId % 15);
        accidents = 9 + (wayId % 6);
      } else if (roll < 3) {
        base = 55 + (wayId % 20);
        accidents = 4 + (wayId % 5);
      } else if (roll < 5) {
        base = 30 + (wayId % 25);
        accidents = 2 + (wayId % 3);
      } else if (roll < 7) {
        base = 10 + (wayId % 20);
        accidents = wayId % 2;
      } else {
        base = wayId % 10;
        accidents = 0;
      }
    }

    final score = getPeakHourAdjustedScore(base, hour);
    return RoadSegment(
      id: wayId,
      name: name,
      coordinates: coords,
      riskLevel: scoreToRisk(score),
      riskScore: score,
      accidentCount: accidents,
    );
  }
}
