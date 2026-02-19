import 'dart:io';

import 'package:eyesos/features/home/domain/repositories/i_accident_repository.dart';

class SendReportAccidentUsecase {
  final IAccidentRepository repository;

  SendReportAccidentUsecase(this.repository);

  Future<void> call({
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
  }) async {
    try {
      return await repository.sendReportAccident(
        reportedBy: reportedBy,
        reporterName: reporterName,
        reporterNotes: reporterNotes,
        reporterContact: reporterContact,
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
        barangay: barangay,
        municipality: municipality,
        province: province,
        landmark: landmark,
        imageFile: imageFile,
        severity: severity,
        accuracy: accuracy,
      );
    } catch (e) {
      rethrow;
    }
  }
}
