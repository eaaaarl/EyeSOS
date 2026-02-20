import 'package:equatable/equatable.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';

abstract class RoadRiskState extends Equatable {
  const RoadRiskState();

  @override
  List<Object?> get props => [];
}

class RoadRiskInitial extends RoadRiskState {}

class RoadRiskLoading extends RoadRiskState {}

class RoadRiskLoaded extends RoadRiskState {
  final List<RoadRiskEntity> roads;

  const RoadRiskLoaded(this.roads);

  @override
  List<Object?> get props => [roads];
}

class RoadRiskError extends RoadRiskState {
  final String message;

  const RoadRiskError(this.message);

  @override
  List<Object?> get props => [message];
}
