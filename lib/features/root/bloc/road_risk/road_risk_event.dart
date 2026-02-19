import 'package:equatable/equatable.dart';

abstract class RoadRiskEvent extends Equatable {
  const RoadRiskEvent();

  @override
  List<Object?> get props => [];
}

class FetchRoadRiskRequested extends RoadRiskEvent {
  final bool forceRefresh;

  const FetchRoadRiskRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}
