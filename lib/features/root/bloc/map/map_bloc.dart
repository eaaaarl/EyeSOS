import 'package:bloc/bloc.dart';
import 'package:eyesos/features/root/bloc/map/map_event.dart';
import 'package:eyesos/features/root/bloc/map/map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(const MapState()) {
    on<ToggleRoads>(_onToggleRoads);
    on<ToggleLegend>(_onToggleLegend);
  }

  void _onToggleRoads(ToggleRoads event, Emitter<MapState> emit) {
    emit(state.copyWith(showRoadRisk: !state.showRoadRisk));
  }

  void _onToggleLegend(ToggleLegend event, Emitter<MapState> emit) {
    emit(state.copyWith(showLegend: !state.showLegend));
  }
}
