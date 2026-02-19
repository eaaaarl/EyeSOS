import 'package:eyesos/features/home/domain/entities/accident_report_entity.dart';

abstract class IAccidentRepository {
  Future<List<AccidentReportEntity>> getRecentReports({
    required String userId,
    int page,
    int pageSize,
  });
}
