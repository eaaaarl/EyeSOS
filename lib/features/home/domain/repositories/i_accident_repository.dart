import 'dart:io';

import 'package:eyesos/features/home/domain/entities/accident_report_entity.dart';

abstract class IAccidentRepository {
  Future<List<AccidentReportEntity>> getRecentReports({
    required String userId,
    int page,
    int pageSize,
  });

  Future<void> sendReportAccident({
    required String reportedBy,
    required String reporterName,
    String? reporterNotes, // descriptions
    String? reporterContact,
    required double latitude,
    required double longitude,
    String? locationAddress,
    String? barangay,
    String? municipality,
    String? province,
    String? landmark,
    File? imageFile,
    String? severity,
    required double accuracy,
  });
}
