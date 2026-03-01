import 'package:eyesos/features/home/domain/entities/accident_status_entity.dart';

class AccidentReportEntity {
  final String id;
  final DateTime createdAt;
  final String reportNumber;
  final String? severity;
  final String reporterName;
  final String? reporterNotes;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final List<String> imageUrls;
  final bool isSos;
  final AccidentStatus accidentStatus;
  final DateTime? updatedAt;

  AccidentReportEntity({
    required this.id,
    required this.createdAt,
    required this.reportNumber,
    this.severity,
    required this.reporterName,
    this.reporterNotes,
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    required this.imageUrls,
    required this.isSos,
    required this.accidentStatus,
    this.updatedAt,
  });
}
