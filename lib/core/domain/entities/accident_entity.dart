import 'package:eyesos/core/domain/entities/accident_status.dart';
import 'package:flutter/material.dart';

class AccidentEntity {
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

  AccidentEntity({
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

  Color get severityColor {
    final sev = severity?.toLowerCase().trim();
    switch (sev) {
      case 'emergency':
        return Colors.red[900]!;
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'moderate':
      case 'medium':
        return Colors.yellow[700]!;
      case 'minor':
      case 'low':
        return Colors.green;
      default:
        return Colors.grey[600]!;
    }
  }
}
