import 'dart:io';
import 'package:eyesos/core/domain/entities/accident_entity.dart';

abstract class IAccidentRepository {
  Future<List<AccidentEntity>> getRecentReports({
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
