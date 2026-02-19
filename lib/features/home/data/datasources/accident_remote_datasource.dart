import 'package:eyesos/features/home/data/models/accident_report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccidentRemoteDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

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
