import 'package:eyesos/features/map/domain/usecases/fetch_roads_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eyesos/features/map/bloc/road_risk_event.dart';
import 'package:eyesos/features/map/bloc/road_risk_state.dart';

class RoadRiskBloc extends Bloc<RoadRiskEvent, RoadRiskState> {
  final FetchRoadsUseCase _fetchRoadsUseCase;

  RoadRiskBloc({required FetchRoadsUseCase fetchRoadsUseCase})
    : _fetchRoadsUseCase = fetchRoadsUseCase,
      super(RoadRiskInitial()) {
    on<FetchRoadRiskRequested>(_onFetchRoadRiskRequested);
  }

  Future<void> _onFetchRoadRiskRequested(
    FetchRoadRiskRequested event,
    Emitter<RoadRiskState> emit,
  ) async {
    emit(RoadRiskLoading());
    try {
      final roads = await _fetchRoadsUseCase.call();
      emit(RoadRiskLoaded(roads));
    } catch (e) {
      emit(RoadRiskError(e.toString()));
    }
  }
}
