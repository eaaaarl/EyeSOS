import 'dart:io';

import 'package:eyesos/features/root/models/accidents_reports_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccidentReportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitAccidentReport({
    required String reportedBy,
    required String reporterName,
    String? reporterNotes, // descriptions,
    String? reporterContact,
    required double latitude,
    required double longitude,
    String? locationAddress,
    String? barangay,
    String? municipality,
    String? province,
    String? landmark,
    File? imageUrl,
    String? severity,
    required double accuracy,
  }) async {
    try {
      final String fileName =
          '$reporterName-${DateTime.now().microsecondsSinceEpoch}.jpg';
      final String filePath = 'incidents/$fileName';

      await _supabase.storage
          .from('accidents_images')
          .upload(
            filePath,
            imageUrl!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String supabaseImageUrl = _supabase.storage
          .from('accidents_images')
          .getPublicUrl(filePath);

      String locationQuality;
      if (accuracy <= 10) {
        locationQuality = 'excellent';
      } else if (accuracy <= 30) {
        locationQuality = 'good';
      } else if (accuracy <= 100) {
        locationQuality = 'fair';
      } else {
        locationQuality = 'poor';
      }

      await _supabase.from('accidents').insert({
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
        'imageUrl': [supabaseImageUrl],
        'location_accuracy': accuracy,
        'location_quality': locationQuality,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AccidentReport>> getRecentsReports({
    required String userId,
    int page = 1,
    int pageSize = 5,
  }) async {
    try {
      final offset = (page - 1) * pageSize;

      final response = await _supabase
          .from('accidents')
          .select()
          .eq('reported_by', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      return (response as List)
          .map((json) => AccidentReport.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
