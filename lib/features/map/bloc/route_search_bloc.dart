import 'dart:async';

import 'package:eyesos/features/map/bloc/route_search_event.dart';
import 'package:eyesos/features/map/bloc/route_search_state.dart';
import 'package:eyesos/features/map/domain/usecases/fetch_route_usecase.dart';
import 'package:eyesos/features/map/domain/usecases/search_places_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RouteSearchBloc extends Bloc<RouteSearchEvent, RouteSearchState> {
  final SearchPlacesUseCase _searchPlacesUseCase;
  final FetchRouteUseCase _fetchRouteUseCase;

  // Debounce timer to avoid hammering Nominatim on every keystroke
  Timer? _debounce;

  RouteSearchBloc({
    required SearchPlacesUseCase searchPlacesUseCase,
    required FetchRouteUseCase fetchRouteUseCase,
  }) : _searchPlacesUseCase = searchPlacesUseCase,
       _fetchRouteUseCase = fetchRouteUseCase,
       super(const RouteSearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SearchCleared>(_onSearchCleared);
    on<FetchRouteRequested>(_onFetchRouteRequested);
    on<RouteDismissed>(_onRouteDismissed);
  }

  // ── Handlers ────────────────────────────────────────────────────────────

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<RouteSearchState> emit,
  ) async {
    _debounce?.cancel();

    if (event.query.trim().isEmpty) {
      emit(const RouteSearchInitial());
      return;
    }

    // Show loading immediately so the UI shows a spinner
    emit(const RouteSearchSuggestionsLoading());

    // Debounce: wait 400 ms before actually calling the API
    final completer = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      completer.complete();
    });
    await completer.future;

    // Guard: state may have changed while waiting
    if (isClosed) return;

    try {
      final suggestions = await _searchPlacesUseCase.call(event.query);
      emit(
        RouteSearchSuggestionsLoaded(
          query: event.query,
          suggestions: suggestions,
        ),
      );
    } catch (e) {
      emit(RouteSearchSuggestionsError(e.toString()));
    }
  }

  void _onSearchCleared(SearchCleared event, Emitter<RouteSearchState> emit) {
    _debounce?.cancel();
    emit(const RouteSearchInitial());
  }

  Future<void> _onFetchRouteRequested(
    FetchRouteRequested event,
    Emitter<RouteSearchState> emit,
  ) async {
    emit(RouteSearchRouteLoading(destinationName: event.destinationName));
    try {
      final route = await _fetchRouteUseCase.call(
        origin: event.origin,
        destination: event.destination,
        destinationName: event.destinationName,
        roadRiskSegments: event.roadRiskSegments,
      );
      emit(RouteSearchRouteLoaded(route));
    } catch (e) {
      emit(RouteSearchRouteError(e.toString()));
    }
  }

  void _onRouteDismissed(RouteDismissed event, Emitter<RouteSearchState> emit) {
    emit(const RouteSearchInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
