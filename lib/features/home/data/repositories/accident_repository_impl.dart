import 'package:eyesos/features/home/data/datasources/accident_remote_datasource.dart';
import 'package:eyesos/features/home/domain/entities/accident_report_entity.dart';
import 'package:eyesos/features/home/domain/repositories/i_accident_repository.dart';

class AccidentRepositoryImpl implements IAccidentRepository {
  final AccidentRemoteDatasource remoteDatasource;

  AccidentRepositoryImpl(this.remoteDatasource);

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
