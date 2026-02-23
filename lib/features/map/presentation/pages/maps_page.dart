import 'dart:ui' as ui;
import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/core/bloc/connectivity_state.dart';
import 'package:eyesos/features/map/bloc/map_bloc.dart';
import 'package:eyesos/features/map/bloc/map_state.dart';
import 'package:eyesos/features/map/data/models/road_risk_model.dart';
import 'package:eyesos/features/map/domain/entities/road_risk_entity.dart';
import 'package:eyesos/features/map/domain/entities/route_entity.dart';
import 'package:eyesos/features/map/presentation/widgets/map_skeleton.dart';
import 'package:eyesos/features/map/presentation/widgets/map_search_bar.dart';
import 'package:eyesos/features/map/presentation/widgets/topbar.dart';
import 'package:eyesos/features/map/presentation/widgets/map_control_buttons.dart';
import 'package:eyesos/features/map/presentation/widgets/road_risk_bottom_sheet.dart';
import 'package:eyesos/features/map/presentation/widgets/road_risk_legend.dart';
import 'package:eyesos/features/map/presentation/widgets/user_location_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:eyesos/features/map/bloc/location_bloc.dart';
import 'package:eyesos/features/map/bloc/location_event.dart';
import 'package:eyesos/features/map/bloc/location_state.dart';
import 'package:eyesos/features/map/bloc/road_risk_bloc.dart';
import 'package:eyesos/features/map/bloc/road_risk_event.dart';
import 'package:eyesos/features/map/bloc/road_risk_state.dart';
import 'package:eyesos/features/map/bloc/route_search_bloc.dart';
import 'package:eyesos/features/map/bloc/route_search_state.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(StartLocationTracking());
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    context.read<LocationBloc>().add(StopLocationTracking());
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
              if (_shouldCenterOnNextLocation) {
                _centerOnLocation(state);
                setState(() => _shouldCenterOnNextLocation = false);
              }
            } else if (state is LocationError) {
              _showLocationError(state.message);
              setState(() => _shouldCenterOnNextLocation = false);
            }
          },
        ),
        // ── Fly camera to the fetched route ────────────────────────────────
        BlocListener<RouteSearchBloc, RouteSearchState>(
          listener: (context, state) {
            if (state is RouteSearchRouteLoaded && _isMapReady) {
              _fitRouteBounds(state.route);
            }
          },
        ),
      ],
      child: BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
        builder: (context, connectivityState) {
          return BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locationState) {
              return BlocBuilder<RoadRiskBloc, RoadRiskState>(
                builder: (context, roadRiskState) {
                  final roads = roadRiskState is RoadRiskLoaded
                      ? roadRiskState.roads
                      : <RoadRiskModel>[];
                  final isLoadingRoads = roadRiskState is RoadRiskLoading;
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
                                // ── Map ──────────────────────────────────────────────
                                _buildMap(
                                  locationState,
                                  roads,
                                  mapState,
                                  activeRoute,
                                ),

                                // ── Loading skeleton ───────────────────────────────────────
                                if (!_isMapReady) const MapSkeleton(),

                                if (_isMapReady) ...[
                                  // ── Top bar ────────────────────────────────────────────
                                  _buildTopBar(),

                                  // ── Search bar ─────────────────────────────────────────
                                  _buildSearchBar(locationState, roads),

                                  // ── Road loading indicator ─────────────────────────────
                                  if (isLoadingRoads)
                                    Positioned(
                                      top: 180,
                                      left: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF2563eb),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Loading road risk…',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // ── Road error banner ──────────────────────────────────
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                                  fontWeight: FontWeight.w600,
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
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.red,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // ── Legend ─────────────────────────────────────────────
                                  if (mapState.showLegend && !isLoadingRoads)
                                    const RoadRiskLegend(),

                                  // ── Control buttons ────────────────────────────────────
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
      ),
    );
  }

  static const double _tapThresholdMeters = 30.0;
  final Distance _distance = const Distance();

  void _onMapTap(
    TapPosition tapPos,
    LatLng latlng,
    List<RoadRiskEntity> roads,
  ) {
    if (roads.isEmpty) return;

    RoadRiskEntity? nearest;
    double nearestDist = double.infinity;

    for (final road in roads) {
      for (final point in road.coordinates) {
        final d = _distance.as(LengthUnit.Meter, latlng, point);
        if (d < nearestDist) {
          nearestDist = d;
          nearest = road;
        }
      }
    }

    if (nearest != null && nearestDist <= _tapThresholdMeters) {
      _showRoadBottomSheet(nearest);
    }
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

  Widget _buildMap(
    LocationState locationState,
    List<RoadRiskEntity> roads,
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
        onTap: (tapPos, latlng) => _onMapTap(tapPos, latlng, roads),
      ),
      children: [
        TileLayer(
          urlTemplate: _mapStyles[_selectedMapStyle]!,
          userAgentPackageName: dotenv.env['PACKAGE_NAME']!,
        ),

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

        // ── Active route (A → B, risk-colored segments) ────────────────────
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

        MarkerLayer(
          markers: [
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
                width: 48,
                height: 56,
                alignment: Alignment.bottomCenter,
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

  void _showRoadBottomSheet(RoadRiskEntity road) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoadRiskBottomSheet(road: road),
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
          children: [
            Container(
              width: 48,
              height: 48,
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
                child: Icon(
                  Icons.location_on,
                  color: Color(0xFFD32F2F),
                  size: 28,
                ),
              ),
            ),
            // Add a small arrow/tail for the pin
            CustomPaint(
              size: const Size(12, 8),
              painter: _PinTailPainter(color: const Color(0xFFD32F2F)),
            ),
          ],
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

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Use ui.Path to avoid name collision with latlong2.Path
    final path = ui.Path()
      ..moveTo(0, 0)
      // Smooth curve towards the tip
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.4,
        size.width / 2,
        size.height,
      )
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.4, size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
