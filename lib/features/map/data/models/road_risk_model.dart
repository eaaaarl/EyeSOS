import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:latlong2/latlong.dart';

class RoadRiskModel extends RoadRiskEntity {
  RoadRiskModel({
    required super.id,
    required super.name,
    required super.coordinates,
    required super.riskLevel,
    required super.riskScore,
    required super.accidentCount,
  });

  factory RoadRiskModel.fromJson(Map<String, dynamic> json) {
    return RoadRiskModel(
      id: json['id'] as int,
      name: json['name'] as String,
      coordinates: (json['coordinates'] as List)
          .map(
            (e) => LatLng(
              (e['lat'] as num).toDouble(),
              (e['lon'] as num).toDouble(),
            ),
          )
          .toList(),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => RiskLevel.none,
      ),
      riskScore: (json['riskScore'] as num).toInt(),
      accidentCount: (json['accidentCount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coordinates': coordinates
          .map((e) => {'lat': e.latitude, 'lon': e.longitude})
          .toList(),
      'riskLevel': riskLevel.name,
      'riskScore': riskScore,
      'accidentCount': accidentCount,
    };
  }

  RoadRiskModel copyWith({
    int? id,
    String? name,
    List<LatLng>? coordinates,
    RiskLevel? riskLevel,
    int? riskScore,
    int? accidentCount,
  }) {
    return RoadRiskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      riskLevel: riskLevel ?? this.riskLevel,
      riskScore: riskScore ?? this.riskScore,
      accidentCount: accidentCount ?? this.accidentCount,
    );
  }
}
