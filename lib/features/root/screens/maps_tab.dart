import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/features/root/bloc/map/map_bloc.dart';
import 'package:eyesos/features/root/bloc/map/map_event.dart';
import 'package:eyesos/features/root/bloc/map/map_state.dart';
import 'package:eyesos/features/root/data/road_risk_mock_data.dart';
import 'package:eyesos/features/root/widgets/accident_report/control_button.dart';
import 'package:eyesos/features/root/widgets/accident_report/map_skeleton.dart';
import 'package:eyesos/features/root/widgets/accident_report/no_internet_fallback.dart';
import 'package:eyesos/features/root/widgets/accident_report/topbar.dart';
import 'package:eyesos/features/root/widgets/map/user_location_marker.dart';
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

class MapsTab extends StatelessWidget {
  const MapsTab({super.key});

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
  bool get wantKeepAlive => true;

  @override
  void dispose() {
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

                  return BlocBuilder<MapBloc, MapState>(
                    builder: (context, mapState) {
                      return Scaffold(
                        body: Stack(
                          children: [
                            // ── Map ────────────────────────────────────────────────────
                            _buildMap(locationState, roads, mapState),

                            // ── Loading skeleton ───────────────────────────────────────
                            if (!_isMapReady) const MapSkeleton(),

                            if (_isMapReady) ...[
                              // ── Top bar ────────────────────────────────────────────
                              _buildTopBar(),

                              // ── Road loading indicator ─────────────────────────────
                              if (isLoadingRoads)
                                Positioned(
                                  top: 100,
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
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              /* if (_tappedRoad != null)
                                _buildRoadPopup(_tappedRoad!), */

                              // ── Legend ─────────────────────────────────────────────
                              if (mapState.showLegend &&
                                  mapState.showRoadRisk &&
                                  !isLoadingRoads)
                                _buildLegend(),

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
          );
        },
      ),
    );
  }

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
      _showRoadBottomSheet(nearest);
    }
  }

  Widget _buildMap(
    LocationState locationState,
    List<RoadSegment> roads,
    MapState mapState,
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

  Widget _buildTopBar() {
    return TopBar(
      selectedMapStyle: _selectedMapStyle,
      onMapStyleChanged: (value) => setState(() => _selectedMapStyle = value),
    );
  }

  void _showRoadBottomSheet(RoadSegment road) {
    final color = road.riskLevel.color;
    final scoreFraction = (road.riskScore / 100).clamp(0.0, 1.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Colored header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.09)),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _riskIcon(road.riskLevel),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        road.riskLevel.label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                  const SizedBox(height: 14),

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
                  const SizedBox(height: 14),

                  // Accident count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
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

                  const SizedBox(height: 14),

                  // Time risk
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'TIME INSIGHTS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _timeChip(
                                icon: Icons.warning_amber_rounded,
                                label: 'Peak Risk',
                                value: RoadRiskMockData.getPeakTimeLabel(
                                  road.id,
                                  road.name,
                                ),
                                color: Colors.red.shade400,
                                bgColor: Colors.red.shade50,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _timeChip(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Safest Time',
                                value: RoadRiskMockData.getSafestTimeLabel(
                                  road.id,
                                  road.name,
                                ),
                                color: Colors.green.shade600,
                                bgColor: Colors.green.shade50,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Current hour indicator
                        _buildHourlyBar(road),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyBar(RoadSegment road) {
    final scores = RoadRiskMockData.getHourlyScores(road.id, road.name);
    final currentHour = DateTime.now().hour;

    // Show 6-hour window centered on current hour
    final startHour = (currentHour - 3).clamp(0, 18);
    final visibleHours = List.generate(6, (i) => startHour + i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk by hour (today)',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: visibleHours.map((hour) {
            final score = scores[hour];
            final isNow = hour == currentHour;
            final barColor = RoadRiskMockData.scoreToRisk(score).color;
            final maxHeight = 36.0;
            final barHeight = (score / 100 * maxHeight).clamp(4.0, maxHeight);

            return Column(
              children: [
                if (isNow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'now',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 14),
                const SizedBox(height: 2),
                Container(
                  width: 28,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: isNow ? barColor : barColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: isNow
                        ? Border.all(color: Colors.blue, width: 1.5)
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatHourShort(hour),
                  style: TextStyle(
                    fontSize: 9,
                    color: isNow ? Colors.blue : Colors.grey,
                    fontWeight: isNow ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatHourShort(int hour) {
    if (hour == 0) return '12a';
    if (hour == 12) return '12p';
    return hour > 12 ? '${hour - 12}p' : '${hour}a';
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
                  onTap: () => context.read<MapBloc>().add(ToggleLegend()),
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

  Widget _buildControlButtons(LocationState locationState) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, mapState) {
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
              ControlButton(
                icon: mapState.showRoadRisk
                    ? Icons.visibility
                    : Icons.visibility_off,
                tooltip: mapState.showRoadRisk
                    ? 'Hide Risk Roads'
                    : 'Show Risk Roads',
                onPressed: () => context.read<MapBloc>().add(ToggleRoads()),
                iconColor: Colors.red[700],
              ),
              const SizedBox(height: 10),
              if (!mapState.showLegend)
                ControlButton(
                  icon: Icons.legend_toggle,
                  tooltip: 'Show Legend',
                  onPressed: () => context.read<MapBloc>().add(ToggleLegend()),
                  iconColor: Colors.red[700],
                ),
              const SizedBox(height: 10),
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
      },
    );
  }
}
