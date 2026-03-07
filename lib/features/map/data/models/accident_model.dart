import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:eyesos/core/domain/entities/accident_status.dart';

class AccidentModel extends AccidentEntity {
  AccidentModel({
    required super.id,
    required super.createdAt,
    required super.reportNumber,
    super.severity,
    required super.reporterName,
    super.reporterNotes,
    required super.latitude,
    required super.longitude,
    required super.locationAddress,
    required super.imageUrls,
    required super.isSos,
    required super.accidentStatus,
    super.updatedAt,
  });

  factory AccidentModel.fromJson(Map<String, dynamic> json) {
    final imageList =
        (json['accident_images'] as List<dynamic>?)
            ?.map((e) => e['url'] as String)
            .toList() ??
        [];

    return AccidentModel(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      reportNumber: json['report_number'] ?? 'N/A',
      severity: json['severity'] ?? 'unknown',
      reporterName: json['reporter_name'] ?? 'Anonymous',
      reporterNotes: json['reporter_notes'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationAddress: json['location_address'] ?? 'Unknown Location',
      imageUrls: imageList,
      isSos: json['sos_type'] ?? false,
      accidentStatus: AccidentStatus.fromString(
        json['accident_status'] ?? 'NEW',
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'report_number': reportNumber,
      'severity': severity,
      'reporter_name': reporterName,
      'reporter_notes': reporterNotes,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'sos_type': isSos,
      'accident_status': accidentStatus.toJson(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
