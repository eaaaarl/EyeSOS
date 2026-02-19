import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyesos/features/root/bloc/road_risk/road_risk_event.dart';
import 'package:eyesos/features/root/bloc/road_risk/road_risk_state.dart';
import 'package:eyesos/features/root/repository/road_risk_repository.dart';

class RoadRiskBloc extends Bloc<RoadRiskEvent, RoadRiskState> {
  final RoadRiskRepository _repository;

  RoadRiskBloc({required RoadRiskRepository repository})
    : _repository = repository,
      super(RoadRiskInitial()) {
    on<FetchRoadRiskRequested>(_onFetchRoadRiskRequested);
  }

  Future<void> _onFetchRoadRiskRequested(
    FetchRoadRiskRequested event,
    Emitter<RoadRiskState> emit,
  ) async {
    emit(RoadRiskLoading());
    try {
      final roads = await _repository.fetchRoads();
      emit(RoadRiskLoaded(roads));
    } catch (e) {
      emit(RoadRiskError(e.toString()));
    }
  }
}
