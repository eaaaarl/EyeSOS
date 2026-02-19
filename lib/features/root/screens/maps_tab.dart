import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/features/root/widgets/accident_report/control_button.dart';
import 'package:eyesos/features/root/widgets/accident_report/map_skeleton.dart';
import 'package:eyesos/features/root/widgets/accident_report/no_internet_fallback.dart';
import 'package:eyesos/features/root/widgets/accident_report/topbar.dart';
import 'package:eyesos/features/root/widgets/accident_report/user_location_marker.dart';
import 'package:eyesos/features/root/widgets/map/location_time_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:eyesos/features/root/bloc/location/location_bloc.dart';
import 'package:eyesos/features/root/bloc/location/location_event.dart';
import 'package:eyesos/features/root/bloc/location/location_state.dart';
import 'package:eyesos/features/root/models/road_risk.dart';
import 'package:eyesos/features/root/bloc/road_risk/road_risk_bloc.dart';
import 'package:eyesos/features/root/bloc/road_risk/road_risk_event.dart';
import 'package:eyesos/features/root/bloc/road_risk/road_risk_state.dart';
import 'package:eyesos/features/root/repository/road_risk_repository.dart';

class MapsTab extends StatelessWidget {
  const MapsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RoadRiskBloc(repository: RoadRiskRepository())
            ..add(const FetchRoadRiskRequested()),
      child: const MapsTableView(),
    );
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

  // UI status state
  bool _showRoads = true;
  bool _showLegend = true;

  // Tapped road popup
  RoadSegment? _tappedRoad;

  String _selectedMapStyle = 'standard';
  bool _hasRequestedLocationOnce = false;

  final Map<String, String> _mapStyles = {
    'standard': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'satellite':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_hasRequestedLocationOnce) {
        context.read<LocationBloc>().add(FetchLocationRequested());
        _hasRequestedLocationOnce = true;
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnLocation(LocationState state) {
    if (state is LocationLoaded && _isMapReady) {
      _mapController.move(
        LatLng(state.location.latitude, state.location.longitude),
        15.0,
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
              _centerOnLocation(state);
            } else if (state is LocationError) {
              _showLocationError(state.message);
            }
          },
        ),
      ],
      child: BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
        builder: (context, connectivityState) {
          if (connectivityState == ConnectivityStatus.disconnected) {
            return const NoInternetFallback();
          }

          return BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locationState) {
              return BlocBuilder<RoadRiskBloc, RoadRiskState>(
                builder: (context, roadRiskState) {
                  final roads = roadRiskState is RoadRiskLoaded
                      ? roadRiskState.roads
                      : <RoadSegment>[];
                  final isLoadingRoads = roadRiskState is RoadRiskLoading;
                  final roadsError = roadRiskState is RoadRiskError
                      ? roadRiskState.message
                      : null;

                  return Scaffold(
                    body: Stack(
                      children: [
                        // ── Map ────────────────────────────────────────────────────
                        _buildMap(locationState, roads),

                        // ── Loading skeleton ───────────────────────────────────────
                        if (!_isMapReady) const MapSkeleton(),

                        if (_isMapReady) ...[
                          // ── Top bar ────────────────────────────────────────────
                          _buildTopBar(),

                          // ── Road loading indicator ─────────────────────────────
                          if (isLoadingRoads)
                            Positioned(
                              top: 80,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
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
                              top: 80,
                              left: 16,
                              right: 80,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
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
                                      onTap: () =>
                                          context.read<RoadRiskBloc>().add(
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
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Road tap popup card (bottom anchored) ─────────────
                          if (_tappedRoad != null)
                            _buildRoadPopup(_tappedRoad!),

                          // ── Legend ─────────────────────────────────────────────
                          if (_showLegend && _showRoads) _buildLegend(),

                          // ── Control buttons ────────────────────────────────────
                          _buildControlButtons(locationState),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── Map widget ──────────────────────────────────────────────────────────────

  // ── Tap detection ────────────────────────────────────────────────────────────
  // Finds the road whose polyline passes closest to the tapped LatLng.
  // Threshold: ~30 meters — close enough to feel accurate, forgiving enough to tap easily.

  static const double _tapThresholdMeters = 30.0;
  final Distance _distance = const Distance();

  void _onMapTap(TapPosition tapPos, LatLng latlng, List<RoadSegment> roads) {
    if (roads.isEmpty) return;

    RoadSegment? nearest;
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
      setState(() {
        _tappedRoad = nearest;
      });
    } else {
      // Tapped empty area — dismiss
      setState(() {
        _tappedRoad = null;
      });
    }
  }

  Widget _buildMap(LocationState locationState, List<RoadSegment> roads) {
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
        // Base tiles
        TileLayer(
          urlTemplate: _mapStyles[_selectedMapStyle]!,
          userAgentPackageName: dotenv.env['PACKAGE_NAME']!,
        ),

        // ── Risk road polylines (replaces heatmap) ──────────────────────────
        if (_showRoads && roads.isNotEmpty)
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

        // User location marker (unchanged from your original)
        MarkerLayer(
          markers: [
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
          ],
        ),
      ],
    );
  }

  // ── Top bar (unchanged) ─────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return TopBar(
      selectedMapStyle: _selectedMapStyle,
      onMapStyleChanged: (value) => setState(() => _selectedMapStyle = value),
    );
  }

  // ── Road tap popup card ──────────────────────────────────────────────────────

  Widget _buildRoadPopup(RoadSegment road) {
    final color = road.riskLevel.color;
    final scoreFraction = (road.riskScore / 100).clamp(0.0, 1.0);

    return Positioned(
      left: 16,
      right: 16,
      top: 100,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -16 * (1 - value)),
            child: child,
          ),
        ),
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          shadowColor: color.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Colored top strip ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _riskIcon(road.riskLevel),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              road.riskLevel.label.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Text(
                              'RISK LEVEL',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dismiss button
                      GestureDetector(
                        onTap: () => setState(() {
                          _tappedRoad = null;
                        }),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Road name
                      Row(
                        children: [
                          const Icon(Icons.route, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              road.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Score bar
                      Row(
                        children: [
                          const Text(
                            'Risk Score',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${road.riskScore}/100',
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: scoreFraction,
                          minHeight: 7,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Accident count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: road.accidentCount > 0
                              ? Colors.orange.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 15,
                              color: road.accidentCount > 0
                                  ? Colors.orange.shade600
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              road.accidentCount > 0
                                  ? '${road.accidentCount} accident${road.accidentCount > 1 ? "s" : ""} recorded'
                                  : 'No accidents recorded',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: road.accidentCount > 0
                                    ? Colors.orange.shade700
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _riskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return Icons.dangerous_rounded;
      case RiskLevel.high:
        return Icons.warning_rounded;
      case RiskLevel.moderate:
        return Icons.info_rounded;
      case RiskLevel.minor:
        return Icons.check_circle_rounded;
      case RiskLevel.none:
        return Icons.shield_rounded;
    }
  }

  // ── Legend ──────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Positioned(
      bottom: 120,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Road Risk Level',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Based on current time',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => setState(() => _showLegend = false),
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...RiskLevel.values.map(
              (level) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: level.strokeWidth,
                      decoration: BoxDecoration(
                        color: level.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(level.label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Based on MDRRMC data',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Control buttons (same structure as your original) ───────────────────────

  Widget _buildControlButtons(LocationState locationState) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (locationState is LocationLoaded) ...[
            LocationTimeBadge(locationState: locationState),
            const SizedBox(height: 10),
          ],

          // Toggle risk roads (was: toggle heatmap)
          ControlButton(
            icon: _showRoads ? Icons.visibility : Icons.visibility_off,
            tooltip: _showRoads ? 'Hide Risk Roads' : 'Show Risk Roads',
            onPressed: () => setState(() => _showRoads = !_showRoads),
            iconColor: Colors.red[700],
          ),
          const SizedBox(height: 10),

          // Show legend
          if (!_showLegend)
            ControlButton(
              icon: Icons.legend_toggle,
              tooltip: 'Show Legend',
              onPressed: () => setState(() => _showLegend = true),
              iconColor: Colors.red[700],
            ),
          const SizedBox(height: 10),

          // Zoom in
          ControlButton(
            icon: Icons.add,
            tooltip: 'Zoom In',
            iconColor: Colors.red[700],
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
          ),
          const SizedBox(height: 10),

          // Zoom out
          ControlButton(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            iconColor: Colors.red[700],
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
          ),
          const SizedBox(height: 10),

          // Center on location
          ControlButton(
            icon: Icons.my_location,
            tooltip: 'Center on Current Location',
            iconColor: Colors.white,
            color: Colors.red[700],
            onPressed: () => _centerOnLocation(locationState),
            isLoading: locationState is LocationLoading && _isMapReady,
          ),
        ],
      ),
    );
  }
}
