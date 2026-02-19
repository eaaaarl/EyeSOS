import 'dart:io';

import 'package:eyesos/features/home/data/datasources/accident_remote_datasource.dart';
import 'package:eyesos/features/home/domain/entities/accident_report_entity.dart';
import 'package:eyesos/features/home/domain/repositories/i_accident_repository.dart';

class AccidentRepositoryImpl implements IAccidentRepository {
  final AccidentRemoteDatasource remoteDatasource;

  AccidentRepositoryImpl(this.remoteDatasource);

  @override
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
  }) async {
    try {
      return await remoteDatasource.reportAccident(
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

  @override
  Future<List<AccidentReportEntity>> getRecentReports({
    required String userId,
    int page = 1,
    int pageSize = 5,
  }) async {
    try {
      return await remoteDatasource.getRecentReports(
        userId: userId,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      rethrow;
    }
  }
}
