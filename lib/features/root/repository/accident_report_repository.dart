import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AccidentReportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _getLocationQuality(double accuracy) {
    if (accuracy <= 10) return 'excellent';
    if (accuracy <= 30) return 'good';
    if (accuracy <= 100) return 'fair';
    return 'poor';
  }

  Future<void> submitAccidentReport({
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

      // 3️⃣ Optional: Add to accident_history (future)
      // await _supabase.from('accident_history').insert({
      //   'accident_id': accidentId,
      //   'action': 'CREATED',
      //   'changed_by': reportedBy,
      //   'old_data': null,
      //   'new_data': accidentResponse,
      //   'created_at': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      throw Exception('Failed to submit accident report: $e');
    }
  }
}
