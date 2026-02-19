import 'dart:io';

import 'package:eyesos/features/home/data/models/accident_report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccidentRemoteDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _getLocationQuality(double accuracy) {
    if (accuracy <= 10) return 'excellent';
    if (accuracy <= 30) return 'good';
    if (accuracy <= 100) return 'fair';
    return 'poor';
  }

  Future<void> reportAccident({
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
      final locationQuality = _getLocationQuality(accuracy);

      final accidentResponse = await _supabase
          .from('accidents')
          .insert({
            'severity': severity ?? 'minor',
            'reported_by': reportedBy,
            'reporter_name': reporterName,
            'reporter_notes': reporterNotes,
            'reporter_contact': reporterContact,
            'latitude': latitude,
            'longitude': longitude,
            'location_address': locationAddress,
            'barangay': barangay,
            'municipality': municipality,
            'province': province,
            'landmark': landmark,
            'location_accuracy': accuracy,
            'location_quality': locationQuality,
            'sos_type': false,
            'accident_status': 'NEW',
          })
          .select()
          .single();

      final accidentId = accidentResponse['id'] as String;

      if (imageFile != null) {
        final fileName =
            '$reporterName-${DateTime.now().microsecondsSinceEpoch}.jpg';
        final filePath = 'incidents/$fileName';

        await _supabase.storage
            .from('accidents_images')
            .upload(
              filePath,
              imageFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );

        final publicImageUrl = _supabase.storage
            .from('accidents_images')
            .getPublicUrl(filePath);

        await _supabase.from('accident_images').insert({
          'accident_id': accidentId,
          'url': publicImageUrl,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AccidentReportModel>> getRecentReports({
    required String userId,
    int page = 1,
    int pageSize = 5,
  }) async {
    try {
      final offset = (page - 1) * pageSize;
      final response = await _supabase
          .from('accidents')
          .select('*, accident_images(*)')
          .eq('reported_by', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return (response as List)
          .map((json) => AccidentReportModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
