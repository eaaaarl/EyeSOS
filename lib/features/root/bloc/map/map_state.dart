import 'package:equatable/equatable.dart';

class MapState extends Equatable {
  final bool showLegend;
  final bool showRoadRisk;

  const MapState({this.showLegend = true, this.showRoadRisk = true});

  MapState copyWith({bool? showLegend, bool? showRoadRisk}) {
    return MapState(
      showLegend: showLegend ?? this.showLegend,
      showRoadRisk: showRoadRisk ?? this.showRoadRisk,
    );
  }

  @override
  List<Object?> get props => [showLegend, showRoadRisk];
}
