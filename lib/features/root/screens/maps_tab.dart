import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/features/root/bloc/map/map_bloc.dart';
import 'package:eyesos/features/root/bloc/map/map_state.dart';
import 'package:eyesos/features/root/widgets/accident_report/map_skeleton.dart';
import 'package:eyesos/features/root/widgets/accident_report/no_internet_fallback.dart';
import 'package:eyesos/features/root/widgets/accident_report/topbar.dart';
import 'package:eyesos/features/root/widgets/map/map_control_buttons.dart';
import 'package:eyesos/features/root/widgets/map/road_risk_bottom_sheet.dart';
import 'package:eyesos/features/root/widgets/map/road_risk_legend.dart';
import 'package:eyesos/features/root/widgets/map/user_location_marker.dart';
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

                              // ── Legend ─────────────────────────────────────────────
                              if (mapState.showLegend &&
                                  mapState.showRoadRisk &&
                                  !isLoadingRoads)
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoadRiskBottomSheet(road: road),
    );
  }
}
