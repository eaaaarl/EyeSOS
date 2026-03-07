import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:eyesos/features/map/domain/repositories/i_accidents_repository.dart';

class FetchAccidentsUsecase {
  final IAccidentsRepository _accidentsRepository;

  FetchAccidentsUsecase(this._accidentsRepository);

  Future<List<AccidentEntity>> call() async {
    return await _accidentsRepository.fetchAllAccidents();
  }
}
