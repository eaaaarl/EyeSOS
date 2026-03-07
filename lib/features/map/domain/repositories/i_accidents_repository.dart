import 'package:eyesos/core/domain/entities/accident_entity.dart';

abstract class IAccidentsRepository {
  Future<List<AccidentEntity>> fetchAllAccidents();
}
