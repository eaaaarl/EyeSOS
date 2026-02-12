import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/features/root/widgets/accident_report/control_button.dart';
import 'package:eyesos/features/root/widgets/accident_report/map_skeleton.dart';
import 'package:eyesos/features/root/widgets/accident_report/no_internet_fallback.dart';
import 'package:eyesos/features/root/widgets/accident_report/topbar.dart';
import 'package:eyesos/features/root/widgets/map/legend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import 'package:eyesos/features/root/bloc/location/location_bloc.dart';
import 'package:eyesos/features/root/bloc/location/location_event.dart';
import 'package:eyesos/features/root/bloc/location/location_state.dart';

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  final ValueNotifier<double> _radiusNotifier = ValueNotifier(60.0);
  bool _showHeatmap = true;
  bool _showLegend = true;
  String _selectedMapStyle = 'standard';
  bool _hasRequestedLocationOnce = false;

  final List<WeightedLatLng> _accidentData = [
    // --- LIANGA POBLACION (Red Hot Center) ---
    WeightedLatLng(const LatLng(8.6324, 126.0945), 1.0), // Town Center
    WeightedLatLng(const LatLng(8.6335, 126.0950), 0.9), // Near Coastline
    WeightedLatLng(const LatLng(8.6310, 126.0930), 0.8), // Market Area
    WeightedLatLng(const LatLng(8.6300, 126.0910), 0.9), // Junction to Highway
    // --- DIATAGON AREA (Secondary Hotspot) ---
    WeightedLatLng(const LatLng(8.6770, 126.1376), 1.0), // Diatagon Proper
    WeightedLatLng(const LatLng(8.6780, 126.1390), 0.7),
    WeightedLatLng(const LatLng(8.6755, 126.1360), 0.8),
    // --- GANAYON & ST. CHRISTINE (The "Orange" Bridge) ---
    WeightedLatLng(const LatLng(8.6545, 126.1009), 0.8), // Ganayon
    WeightedLatLng(const LatLng(8.6450, 126.0980), 0.6), // Connecting Road
    WeightedLatLng(const LatLng(8.6180, 126.0750), 0.7), // St. Christine
    // --- HIGHWAY BENDS (Scattered Orange/Yellow) ---
    WeightedLatLng(const LatLng(8.6600, 126.1100), 0.5),
    WeightedLatLng(const LatLng(8.6200, 126.0800), 0.4),
    WeightedLatLng(const LatLng(8.6380, 126.0970), 0.6),
  ];

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
    _radiusNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocConsumer<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationLoaded && _isMapReady) {
          _mapController.move(
            LatLng(state.location.latitude, state.location.longitude),
            15.0,
          );
        } else if (state is LocationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  context.read<LocationBloc>().add(
                    FetchLocationRequested(forceRefresh: true),
                  );
                },
              ),
            ),
          );
        }
      },

      builder: (context, locationState) {
        return BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
          builder: (context, connectivityState) {
            if (connectivityState == ConnectivityStatus.disconnected) {
              return const NoInternetFallback();
            }
            return Scaffold(
              body: Stack(
                children: [
                  // Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(8.6327, 126.0945),
                      initialZoom: 12.0,
                      onMapReady: () {
                        if (!mounted) return;
                        setState(() => _isMapReady = true);
                      },
                      onPositionChanged: (camera, hasGesture) {
                        double newRadius = 800 / camera.zoom!;
                        if (newRadius < 20) newRadius = 20;
                        if (newRadius > 150) newRadius = 150;

                        _radiusNotifier.value = newRadius;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _mapStyles[_selectedMapStyle]!,
                        userAgentPackageName: dotenv.env['PACKAGE_NAME']!,
                      ),
                      if (_showHeatmap && _accidentData.isNotEmpty)
                        ValueListenableBuilder<double>(
                          valueListenable: _radiusNotifier,
                          builder: (context, radius, _) {
                            return HeatMapLayer(
                              heatMapDataSource: InMemoryHeatMapDataSource(
                                data: _accidentData,
                              ),
                              heatMapOptions: HeatMapOptions(
                                radius: radius,
                                blurFactor: 10.0,
                                gradient: {
                                  0.2: Colors.blue,
                                  0.5: Colors.yellow,
                                  0.8: Colors.red,
                                },
                              ),
                            );
                          },
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
                              child: _BuildUserLocationMarker(),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Loading skeleton
                  if (!_isMapReady) const MapSkeleton(),

                  // UI Controls (only show when map is ready)
                  if (_isMapReady) ...[
                    TopBar(
                      selectedMapStyle: _selectedMapStyle,
                      onMapStyleChanged: (value) =>
                          setState(() => _selectedMapStyle = value),
                    ),
                    if (_showLegend)
                      LegendCard(
                        onClose: () => setState(() => _showLegend = false),
                      ),
                    _BuildControlButtons(
                      mapController: _mapController,
                      state: locationState,
                      showLegend: _showLegend,
                      showHeatmap: _showHeatmap,
                      onLegendClosed: () => setState(() => _showLegend = true),
                      onToggleHeatmap: () =>
                          setState(() => _showHeatmap = !_showHeatmap),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BuildUserLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_pin_circle,
      color: Colors.red[700],
      size: 40,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

class _BuildControlButtons extends StatelessWidget {
  final MapController mapController;
  final LocationState state;
  final bool showLegend;
  final bool showHeatmap;
  final VoidCallback onLegendClosed;
  final VoidCallback onToggleHeatmap;

  const _BuildControlButtons({
    required this.mapController,
    required this.state,
    required this.showLegend,
    required this.showHeatmap,
    required this.onLegendClosed,
    required this.onToggleHeatmap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ControlButton(
            icon: showHeatmap ? Icons.visibility : Icons.visibility_off,
            tooltip: showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
            onPressed: onToggleHeatmap,
            iconColor: Colors.red[700],
          ),
          if (!showLegend)
            ControlButton(
              icon: Icons.legend_toggle,
              tooltip: 'Show Legend',
              onPressed: onLegendClosed,
              iconColor: Colors.red[700],
            ),
          const SizedBox(height: 10),
          ControlButton(
            icon: Icons.add,
            tooltip: 'Zoom In',
            iconColor: Colors.red[700],
            onPressed: () {
              final currentCenter = mapController.camera.center;
              final currentZoom = mapController.camera.zoom;
              mapController.move(currentCenter, currentZoom + 1);
            },
          ),
          const SizedBox(height: 10),
          ControlButton(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            iconColor: Colors.red[700],
            onPressed: () {
              final currentCenter = mapController.camera.center;
              final currentZoom = mapController.camera.zoom;
              mapController.move(currentCenter, currentZoom - 1);
            },
          ),
          const SizedBox(height: 10),
          ControlButton(
            icon: Icons.my_location,
            tooltip: 'Center on Current Location',
            iconColor: Colors.white,
            color: Colors.red[700],
            onPressed: () {
              if (state is LocationLoaded) {
                final location = (state as LocationLoaded).location;
                mapController.move(
                  LatLng(location.latitude, location.longitude),
                  15.0,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
