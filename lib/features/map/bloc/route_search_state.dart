import 'package:equatable/equatable.dart';
import 'package:eyesos/features/map/data/models/place_model.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';

abstract class RouteSearchState extends Equatable {
  const RouteSearchState();

  @override
  List<Object?> get props => [];
}

// ── Idle ────────────────────────────────────────────────────────────────────

/// Default: nothing is happening.
class RouteSearchInitial extends RouteSearchState {
  const RouteSearchInitial();
}

// ── Suggestions ─────────────────────────────────────────────────────────────

/// User is typing — currently fetching suggestions.
class RouteSearchSuggestionsLoading extends RouteSearchState {
  const RouteSearchSuggestionsLoading();
}

/// Suggestions have arrived.
class RouteSearchSuggestionsLoaded extends RouteSearchState {
  final String query;
  final List<PlaceModel> suggestions;

  const RouteSearchSuggestionsLoaded({
    required this.query,
    required this.suggestions,
  });

  @override
  List<Object?> get props => [query, suggestions];
}

/// Suggestion search failed.
class RouteSearchSuggestionsError extends RouteSearchState {
  final String message;

  const RouteSearchSuggestionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Route ───────────────────────────────────────────────────────────────────

/// Route OSRM call in progress.
class RouteSearchRouteLoading extends RouteSearchState {
  final String destinationName;

  const RouteSearchRouteLoading({required this.destinationName});

  @override
  List<Object?> get props => [destinationName];
}

/// Route successfully fetched and ready to display on the map.
class RouteSearchRouteLoaded extends RouteSearchState {
  final RouteEntity route;

  const RouteSearchRouteLoaded(this.route);

  @override
  List<Object?> get props => [route];
}

/// Route fetch failed.
class RouteSearchRouteError extends RouteSearchState {
  final String message;

  const RouteSearchRouteError(this.message);

  @override
  List<Object?> get props => [message];
}
