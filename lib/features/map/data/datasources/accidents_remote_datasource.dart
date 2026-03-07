import 'package:supabase_flutter/supabase_flutter.dart';

class AccidentsRemoteDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAllAccidents() async {
    final response = await _supabase
        .from('accidents')
        .select('*, accident_images(*)');

    return response;
  }
}
