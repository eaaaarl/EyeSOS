import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/core/bloc/connectivity_state.dart';
import 'package:eyesos/features/map/bloc/accidents_bloc.dart';
import 'package:eyesos/features/map/bloc/location_bloc.dart';
import 'package:eyesos/features/map/bloc/location_event.dart';
import 'package:eyesos/features/map/bloc/location_state.dart';
import 'package:eyesos/features/map/bloc/map_bloc.dart';
import 'package:eyesos/features/map/bloc/map_state.dart';
import 'package:eyesos/features/map/bloc/road_risk_bloc.dart';
import 'package:eyesos/features/map/bloc/road_risk_event.dart';
import 'package:eyesos/features/map/bloc/road_risk_state.dart';
import 'package:eyesos/features/map/bloc/route_search_bloc.dart';
import 'package:eyesos/features/map/bloc/route_search_state.dart';
import 'package:eyesos/features/map/data/models/road_risk_model.dart';
import 'package:eyesos/core/domain/entities/accident_entity.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';
import 'package:eyesos/features/map/presentation/widgets/accident_marker.dart';
import 'package:eyesos/features/map/presentation/widgets/map_accident_bottom_sheet.dart';
import 'package:eyesos/features/map/presentation/widgets/map_skeleton.dart';
import 'package:eyesos/features/map/presentation/widgets/map_search_bar.dart';
import 'package:eyesos/features/map/presentation/widgets/topbar.dart';
import 'package:eyesos/features/map/presentation/widgets/map_control_buttons.dart';
import 'package:eyesos/features/map/presentation/widgets/user_location_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapsTableView();
  }
}

class MapsTableView extends StatefulWidget {
  const MapsTableView({super.key});

  @override
  State<MapsTableView> createState() => _MapsTableViewState();
}

class _MapsTableViewState extends State<MapsTableView>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  bool _shouldCenterOnNextLocation = false;

  String _selectedMapStyle = 'standard';

  final Map<String, String> _mapStyles = {
    'standard': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'satellite':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  late final LocationBloc _locationBloc;

  @override
  void initState() {
    super.initState();
    _locationBloc = context.read<LocationBloc>();
    context.read<AccidentsBloc>().add(const FetchAccidentsRequested());
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _locationBloc.add(StopLocationTracking());
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnLocation(LocationState state) {
    if (!_isMapReady) return;

    if (state is LocationLoaded) {
      _mapController.move(
        LatLng(state.location.latitude, state.location.longitude),
        15.0,
      );
    } else {
      setState(() => _shouldCenterOnNextLocation = true);
      context.read<LocationBloc>().add(
        FetchLocationRequested(forceRefresh: true),
      );
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => context.read<LocationBloc>().add(
            FetchLocationRequested(forceRefresh: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            if (state is LocationLoaded && _isMapReady) {
              ScaffoldMessenger.of(context).clearSnackBars();
              if (_shouldCenterOnNextLocation) {
                _centerOnLocation(state);
                setState(() => _shouldCenterOnNextLocation = false);
              }
            } else if (state is LocationError) {
              final errorMessage = state.message;
              final locationBloc = context.read<LocationBloc>();
              Future.delayed(const Duration(milliseconds: 800), () {
                if (!mounted) return;
                final currentState = locationBloc.state;
                if (currentState is LocationError) {
                  _showLocationError(errorMessage);
                }
              });
              setState(() => _shouldCenterOnNextLocation = false);
            }
          },
        ),
        BlocListener<RouteSearchBloc, RouteSearchState>(
          listener: (context, state) {
            if (state is RouteSearchRouteLoaded && _isMapReady) {
              _fitRouteBounds(state.route);
              context.read<LocationBloc>().add(StartLocationTracking());
            } else if (state is RouteSearchInitial) {
              context.read<LocationBloc>().add(StopLocationTracking());
            }
          },
        ),
        BlocListener<AccidentsBloc, AccidentsState>(
          listener: (context, state) {
            if (state is AccidentsLoaded && _isMapReady) {
              _fitAccidentBounds(state.accidents);
            }
          },
        ),
      ],
      child: BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
        builder: (context, connectivityState) {
          return BlocBuilder<AccidentsBloc, AccidentsState>(
            builder: (context, accidentsState) {
              final accidents = accidentsState is AccidentsLoaded
                  ? accidentsState.accidents
                  : <AccidentEntity>[];

              return BlocBuilder<LocationBloc, LocationState>(
                builder: (context, locationState) {
                  return BlocBuilder<RoadRiskBloc, RoadRiskState>(
                    builder: (context, roadRiskState) {
                      final roads = roadRiskState is RoadRiskLoaded
                          ? roadRiskState.roads
                          : <RoadRiskModel>[];
                      final roadsError = roadRiskState is RoadRiskError
                          ? roadRiskState.message
                          : null;

                      return BlocBuilder<MapBloc, MapState>(
                        builder: (context, mapState) {
                          return BlocBuilder<RouteSearchBloc, RouteSearchState>(
                            builder: (context, routeState) {
                              final activeRoute =
                                  routeState is RouteSearchRouteLoaded
                                  ? routeState.route
                                  : null;

                              return Scaffold(
                                body: Stack(
                                  children: [
                                    _buildMap(
                                      locationState,
                                      roads,
                                      accidents,
                                      mapState,
                                      activeRoute,
                                    ),
                                    if (!_isMapReady) const MapSkeleton(),
                                    if (_isMapReady) ...[
                                      _buildTopBar(),
                                      _buildSearchBar(locationState, roads),
                                      if (roadsError != null)
                                        Positioned(
                                          top: 100,
                                          left: 16,
                                          right: 80,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              border: Border.all(
                                                color: Colors.red.shade200,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                const Expanded(
                                                  child: Text(
                                                    'Road data unavailable',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => context
                                                      .read<RoadRiskBloc>()
                                                      .add(
                                                        const FetchRoadRiskRequested(
                                                          forceRefresh: true,
                                                        ),
                                                      ),
                                                  child: const Text(
                                                    'Retry',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.red,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      MapControlButtons(
                                        mapController: _mapController,
                                        locationState: locationState,
                                        isMapReady: _isMapReady,
                                        onCenterOnLocation: () =>
                                            _centerOnLocation(locationState),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Fly the camera to show the full A→B route.
  void _fitRouteBounds(RouteEntity route) {
    if (route.fullPath.isEmpty) return;
    double minLat = route.fullPath.first.latitude;
    double maxLat = minLat;
    double minLon = route.fullPath.first.longitude;
    double maxLon = minLon;
    for (final p in route.fullPath) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  /// Fit the map camera to show all accident markers and the user's location.
  void _fitAccidentBounds(List<AccidentEntity> accidents) {
    if (accidents.isEmpty && _locationBloc.state is! LocationLoaded) return;

    final List<LatLng> points = [];

    // Add all accident coordinates
    for (final acc in accidents) {
      points.add(LatLng(acc.latitude, acc.longitude));
    }

    // Add user's location if available
    final locationState = _locationBloc.state;
    if (locationState is LocationLoaded) {
      points.add(
        LatLng(
          locationState.location.latitude,
          locationState.location.longitude,
        ),
      );
    }

    if (points.isEmpty) return;

    // Calculate bounds manually since LatLngBounds.fromPoints might be missing in some versions
    double minLat = points.first.latitude;
    double maxLat = minLat;
    double minLon = points.first.longitude;
    double maxLon = minLon;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(70), // Slightly more padding for markers
      ),
    );
  }

  Widget _buildMap(
    LocationState locationState,
    List<RoadRiskEntity> roads,
    List<AccidentEntity> accidents,
    MapState mapState,
    RouteEntity? activeRoute,
  ) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(8.6327, 126.0945),
        initialZoom: 12.0,
        onMapReady: () {
          if (!mounted) return;
          setState(() => _isMapReady = true);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _mapStyles[_selectedMapStyle]!,
          userAgentPackageName: dotenv.env['PACKAGE_NAME']!,
        ),

        /*
        // ── Road-risk overlay (off by default, togglable) ─────────────────
        if (mapState.showRoadRisk && roads.isNotEmpty)
          PolylineLayer(
            polylines: roads
                .map(
                  (road) => Polyline(
                    points: road.coordinates,
                    color: road.riskLevel.color,
                    strokeWidth: road.riskLevel.strokeWidth,
                  ),
                )
                .toList(),
          ),
        */

        // ── Active route (Standard Blue Line) ────────────────────────────────
        if (activeRoute != null && activeRoute.fullPath.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: activeRoute.fullPath,
                color: const Color(0xFF2563eb),
                strokeWidth: 6.0,
                borderColor: Colors.white.withValues(alpha: 0.5),
                borderStrokeWidth: 2,
              ),
            ],
          ),

        // ── Active route (A → B, risk-colored segments) [DISABLED] ──────────
        /*
        if (activeRoute != null && activeRoute.coloredSegments.isNotEmpty)
          PolylineLayer(
            polylines: activeRoute.coloredSegments
                .where((s) => s.points.isNotEmpty)
                .map(
                  (s) => Polyline(
                    points: s.points,
                    color: s.color,
                    strokeWidth: s.strokeWidth,
                    borderColor: Colors.white.withValues(alpha: 0.5),
                    borderStrokeWidth: 2,
                  ),
                )
                .toList(),
          ),
        */
        MarkerLayer(
          markers: [
            // ── Accident markers ───────────────────────────────────────────
            ...accidents.map(
              (acc) => Marker(
                point: LatLng(acc.latitude, acc.longitude),
                width: 32,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => _showAccidentBottomSheet(acc),
                  child: AccidentMarker(accident: acc),
                ),
              ),
            ),

            // ── User location marker (A) ──────────────────────────────────
            if (locationState is LocationLoaded)
              Marker(
                point: LatLng(
                  locationState.location.latitude,
                  locationState.location.longitude,
                ),
                width: 60,
                height: 60,
                child: const UserLocationMarker(),
              ),

            // ── Destination marker (B) ────────────────────────────────────
            if (activeRoute != null && activeRoute.fullPath.isNotEmpty)
              Marker(
                point: activeRoute.fullPath.last,
                width: 28,
                height: 28,
                alignment: Alignment.topCenter,
                child: const _DestinationPin(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return TopBar(
      selectedMapStyle: _selectedMapStyle,
      onMapStyleChanged: (value) => setState(() => _selectedMapStyle = value),
    );
  }

  Widget _buildSearchBar(
    LocationState locationState,
    List<RoadRiskEntity> roads,
  ) {
    return MapSearchBar(locationState: locationState, roadRiskSegments: roads);
  }

  void _showAccidentBottomSheet(AccidentEntity accident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: MapAccidentBottomSheet(accident: accident),
      ),
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFD32F2F), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 18),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
