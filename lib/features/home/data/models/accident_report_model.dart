import 'package:eyesos/features/home/domain/entities/accident_report_entity.dart';

class AccidentReportModel extends AccidentReportEntity {
  AccidentReportModel({
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
  });

  factory AccidentReportModel.fromJson(Map<String, dynamic> json) {
    final imageList =
        (json['accident_images'] as List<dynamic>?)
            ?.map((e) => e['url'] as String)
            .toList() ??
        [];

    return AccidentReportModel(
      id: json['id'],
      // Parse the ISO8601 string from Supabase
      createdAt: DateTime.parse(json['created_at']),
      reportNumber: json['report_number'] ?? 'N/A',
      severity: json['severity'] ?? 'unknown',
      reporterName: json['reporter_name'] ?? 'Anonymous',
      reporterNotes: json['reporter_notes'],
      // Supabase numbers can come back as int or double, .toDouble() is safer
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationAddress: json['location_address'] ?? 'Unknown Location',
      // Convert the dynamic list to a List<String>
      imageUrls: imageList,
      isSos: json['sos_type'] ?? false,
    );
  }
}
