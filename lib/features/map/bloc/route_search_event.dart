import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';

abstract class RouteSearchEvent extends Equatable {
  const RouteSearchEvent();

  @override
  List<Object?> get props => [];
}

// ── Search / suggestions ────────────────────────────────────────────────────

/// Fired when the user types in the search field.
class SearchQueryChanged extends RouteSearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Fired to clear suggestions and reset the search field.
class SearchCleared extends RouteSearchEvent {
  const SearchCleared();
}

// ── Route ───────────────────────────────────────────────────────────────────

/// Fired when the user selects a suggestion and wants directions.
class FetchRouteRequested extends RouteSearchEvent {
  final LatLng origin;
  final LatLng destination;
  final String destinationName;
  final List<RoadRiskEntity> roadRiskSegments;

  const FetchRouteRequested({
    required this.origin,
    required this.destination,
    required this.destinationName,
    this.roadRiskSegments = const [],
  });

  @override
  List<Object?> get props => [
    origin,
    destination,
    destinationName,
    roadRiskSegments,
  ];
}

/// Fired when the user dismisses the active route.
class RouteDismissed extends RouteSearchEvent {
  const RouteDismissed();
}
