import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:eyesos/features/home/domain/repositories/i_accident_repository.dart';

class LoadRecentReportsUsecase {
  final IAccidentRepository repository;

  LoadRecentReportsUsecase({required this.repository});

  Future<List<AccidentEntity>> call({
    required String userId,
    int page = 1,
    int pageSize = 5,
  }) async {
    try {
      return await repository.getRecentReports(
        userId: userId,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      rethrow;
    }
  }
}
