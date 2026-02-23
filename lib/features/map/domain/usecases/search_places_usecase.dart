import 'package:eyesos/features/map/data/models/place_model.dart';
import 'package:eyesos/features/map/domain/repositories/i_route_repository.dart';

class SearchPlacesUseCase {
  final IRouteRepository _repository;

  SearchPlacesUseCase(this._repository);

  Future<List<PlaceModel>> call(String query) async {
    return _repository.searchPlaces(query);
  }
}
