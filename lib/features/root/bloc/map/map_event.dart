import 'package:equatable/equatable.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class ToggleRoads extends MapEvent {
  @override
  List<Object?> get props => [];
}

class ToggleLegend extends MapEvent {
  @override
  List<Object?> get props => [];
}
