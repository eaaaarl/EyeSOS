import 'package:eyesos/features/map/bloc/location_bloc.dart';
import 'package:eyesos/features/map/bloc/location_event.dart';
import 'package:eyesos/features/map/bloc/location_state.dart';
import 'package:eyesos/features/map/bloc/route_search_bloc.dart';
import 'package:eyesos/features/map/bloc/route_search_event.dart';
import 'package:eyesos/features/map/bloc/route_search_state.dart';
import 'package:eyesos/features/map/data/models/place_model.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MapSearchBar  –  static pill that opens the full search overlay on tap
// ─────────────────────────────────────────────────────────────────────────────

class MapSearchBar extends StatelessWidget {
  final LocationState locationState;
  final List<RoadRiskEntity> roadRiskSegments;

  const MapSearchBar({
    super.key,
    required this.locationState,
    this.roadRiskSegments = const [],
  });

  @override
  Widget build(BuildContext context) {
    final double topOffset = MediaQuery.of(context).padding.top + 88;

    return Positioned(
          top: topOffset,
          left: 16,
          right: 16,
          child: BlocBuilder<RouteSearchBloc, RouteSearchState>(
            builder: (context, state) {
              if (state is RouteSearchRouteLoaded) {
                return _ActiveRoutePill(route: state.route);
              }
              return _SearchPill(
                locationState: locationState,
                roadRiskSegments: roadRiskSegments,
                isLoading: state is RouteSearchRouteLoading,
                loadingLabel: state is RouteSearchRouteLoading
                    ? state.destinationName
                    : null,
              );
            },
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Default search pill
// ─────────────────────────────────────────────────────────────────────────────

class _SearchPill extends StatelessWidget {
  final LocationState locationState;
  final List<RoadRiskEntity> roadRiskSegments;
  final bool isLoading;
  final String? loadingLabel;

  const _SearchPill({
    required this.locationState,
    this.roadRiskSegments = const [],
    this.isLoading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: isLoading ? null : () => _openSearchOverlay(context),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFD32F2F),
              ),
            )
          else
            const Icon(
              Icons.search_rounded,
              color: Color(0xFFD32F2F),
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isLoading
                  ? 'Getting route to ${loadingLabel ?? '…'}'
                  : 'Search destination…',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isLoading ? Colors.grey[700] : Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          const Icon(
            Icons.mic_none_rounded,
            color: Color(0xFFD32F2F),
            size: 22,
          ),
        ],
      ),
    );
  }

  void _openSearchOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<RouteSearchBloc>(),
        child: _SearchOverlay(
          locationState: locationState,
          roadRiskSegments: roadRiskSegments,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active route pill  (shown while a route is displayed on the map)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveRoutePill extends StatelessWidget {
  final RouteEntity route;

  const _ActiveRoutePill({required this.route});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  route.destinationName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${route.distanceText}  ·  ${route.durationText}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Dismiss button
          GestureDetector(
            onTap: () =>
                context.read<RouteSearchBloc>().add(const RouteDismissed()),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card shell
// ─────────────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CardShell({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen search overlay  (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchOverlay extends StatefulWidget {
  final dynamic locationState;
  final List<RoadRiskEntity> roadRiskSegments;

  const _SearchOverlay({
    required this.locationState,
    this.roadRiskSegments = const [],
  });

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle ───────────────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Search field ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (q) => context.read<RouteSearchBloc>().add(
                            SearchQueryChanged(q),
                          ),
                          style: GoogleFonts.inter(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search destination…',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey[400],
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFFD32F2F),
                              size: 22,
                            ),
                            suffixIcon:
                                BlocBuilder<RouteSearchBloc, RouteSearchState>(
                                  builder: (context, state) {
                                    if (_controller.text.isNotEmpty) {
                                      return IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _controller.clear();
                                          context.read<RouteSearchBloc>().add(
                                            const SearchCleared(),
                                          );
                                        },
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        context.read<RouteSearchBloc>().add(
                          const SearchCleared(),
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD32F2F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              // ── Results ──────────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<RouteSearchBloc, RouteSearchState>(
                  builder: (context, state) {
                    if (state is RouteSearchSuggestionsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD32F2F),
                          strokeWidth: 2.5,
                        ),
                      );
                    }

                    if (state is RouteSearchSuggestionsError) {
                      return _ErrorMessage(message: state.message);
                    }

                    if (state is RouteSearchSuggestionsLoaded) {
                      if (state.suggestions.isEmpty) {
                        return _EmptyResult(query: state.query);
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: state.suggestions.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (context, i) => _SuggestionTile(
                          place: state.suggestions[i],
                          onTap: () =>
                              _onPlaceSelected(context, state.suggestions[i]),
                        ),
                      );
                    }

                    // Initial state – show quick tips
                    return _IdleHint(scrollController: scrollController);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onPlaceSelected(BuildContext context, PlaceModel place) async {
    final locationState = widget.locationState;
    LatLng? origin;

    if (locationState is LocationLoaded) {
      origin = LatLng(
        locationState.location.latitude,
        locationState.location.longitude,
      );
    }

    if (origin == null) {
      // If location is not available, show feedback and try to fetch it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fetching your current location...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Request a one-time location fetch
      context.read<LocationBloc>().add(
        FetchLocationRequested(forceRefresh: true),
      );

      // Wait for the next state from LocationBloc
      await for (final state in context.read<LocationBloc>().stream) {
        if (state is LocationLoaded) {
          origin = LatLng(state.location.latitude, state.location.longitude);
          break;
        } else if (state is LocationError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to get location: ${state.message}'),
              ),
            );
          }
          return;
        }
      }
    }

    if (origin == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your location is still not available. Try again.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      context.read<RouteSearchBloc>().add(
        FetchRouteRequested(
          origin: origin,
          destination: place.location,
          destinationName: place.shortName,
          roadRiskSegments: widget.roadRiskSegments,
        ),
      );

      Navigator.pop(context);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets inside the overlay
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback onTap;

  const _SuggestionTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFFD32F2F),
          size: 20,
        ),
      ),
      title: Text(
        place.shortName,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        place.displayName,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.grey,
      ),
    );
  }
}

class _IdleHint extends StatelessWidget {
  final ScrollController scrollController;
  const _IdleHint({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Row(
          children: [
            const Icon(
              Icons.tips_and_updates_outlined,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              'Type to search for a destination',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final String query;
  const _EmptyResult({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Could not reach search service',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
