import 'dart:async';
import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/features/root/widgets/accident_report/control_button.dart';
import 'package:eyesos/features/root/widgets/accident_report/map_skeleton.dart';
import 'package:eyesos/features/root/widgets/accident_report/no_internet_fallback.dart';
import 'package:eyesos/features/root/widgets/accident_report/topbar.dart';
import 'package:eyesos/features/root/widgets/accident_report/user_location_marker.dart';
import 'package:eyesos/features/root/widgets/map/legend_card.dart';
import 'package:eyesos/features/root/widgets/map/location_time_badge.dart';
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

  // Timer for debouncing radius updates
  Timer? _radiusUpdateTimer;

  // Mock accident data - can be easily replaced later
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

      // Request location data
      if (!_hasRequestedLocationOnce) {
        context.read<LocationBloc>().add(FetchLocationRequested());
        _hasRequestedLocationOnce = true;
      }
    });
  }

  @override
  void dispose() {
    _radiusUpdateTimer?.cancel();
    _radiusNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handlePositionChanged(MapPosition position, bool hasGesture) {
    // Debounce radius updates to avoid excessive rebuilds
    _radiusUpdateTimer?.cancel();
    _radiusUpdateTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      double newRadius = 800 / position.zoom!;
      if (newRadius < 20) newRadius = 20;
      if (newRadius > 150) newRadius = 150;

      // Round to reduce unnecessary updates
      final roundedRadius = newRadius.roundToDouble();

      // Only update if the change is significant (> 1.0)
      if ((roundedRadius - _radiusNotifier.value).abs() > 1.0) {
        _radiusNotifier.value = roundedRadius;
      }
    });
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
          onPressed: () {
            context.read<LocationBloc>().add(
              FetchLocationRequested(forceRefresh: true),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocConsumer<LocationBloc, LocationState>(
      listener: (context, state) {
        if (state is LocationLoaded && _isMapReady) {
          _centerOnLocation(state);
        } else if (state is LocationError) {
          _showLocationError(state.message);
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
                  _buildMap(locationState),

                  // Loading skeleton
                  if (!_isMapReady) const MapSkeleton(),

                  // UI Controls (only show when map is ready)
                  if (_isMapReady) ...[
                    _buildTopBar(),
                    if (_showLegend) _buildLegend(),
                    _buildControlButtons(locationState),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMap(LocationState locationState) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(8.6327, 126.0945),
        initialZoom: 12.0,
        onMapReady: () {
          if (!mounted) return;
          setState(() => _isMapReady = true);
        },
        onPositionChanged: _handlePositionChanged,
      ),
      children: [
        // Tile Layer
        TileLayer(
          urlTemplate: _mapStyles[_selectedMapStyle]!,
          userAgentPackageName: dotenv.env['PACKAGE_NAME']!,
        ),

        // Heatmap Layer
        if (_showHeatmap && _accidentData.isNotEmpty && _isMapReady)
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

        // User Location Marker
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

  Widget _buildLegend() {
    return LegendCard(onClose: () => setState(() => _showLegend = false));
  }

  Widget _buildControlButtons(LocationState locationState) {
    return _ControlButtons(
      mapController: _mapController,
      state: locationState,
      showLegend: _showLegend,
      showHeatmap: _showHeatmap,
      onOpenLegend: () => setState(() => _showLegend = true),
      onToggleHeatmap: () => setState(() => _showHeatmap = !_showHeatmap),
      isLoading: () {
        if (locationState is LocationLoading && _isMapReady) {
          return true;
        }
        return false;
      }(),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final MapController mapController;
  final LocationState state;
  final bool showLegend;
  final bool showHeatmap;
  final VoidCallback onOpenLegend;
  final VoidCallback onToggleHeatmap;
  final bool? isLoading;

  const _ControlButtons({
    required this.mapController,
    required this.state,
    required this.showLegend,
    required this.showHeatmap,
    required this.onOpenLegend,
    required this.onToggleHeatmap,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (state is LocationLoaded) ...[
            LocationTimeBadge(locationState: state),
            const SizedBox(height: 10),
          ],
          ControlButton(
            icon: showHeatmap ? Icons.visibility : Icons.visibility_off,
            tooltip: showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
            onPressed: onToggleHeatmap,
            iconColor: Colors.red[700],
          ),
          const SizedBox(height: 10),
          if (!showLegend)
            ControlButton(
              icon: Icons.legend_toggle,
              tooltip: 'Show Legend',
              onPressed: onOpenLegend,
              iconColor: Colors.red[700],
            ),
          const SizedBox(height: 10),
          ControlButton(
            icon: Icons.add,
            tooltip: 'Zoom In',
            iconColor: Colors.red[700],
            onPressed: () => _handleZoomIn(mapController),
          ),
          const SizedBox(height: 10),
          ControlButton(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            iconColor: Colors.red[700],
            onPressed: () => _handleZoomOut(mapController),
          ),
          const SizedBox(height: 10),
          ControlButton(
            icon: Icons.my_location,
            tooltip: 'Center on Current Location',
            iconColor: Colors.white,
            color: Colors.red[700],
            onPressed: () => _handleCenterLocation(mapController, state),
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  void _handleZoomIn(MapController controller) {
    final currentCenter = controller.camera.center;
    final currentZoom = controller.camera.zoom;
    controller.move(currentCenter, currentZoom + 1);
  }

  void _handleZoomOut(MapController controller) {
    final currentCenter = controller.camera.center;
    final currentZoom = controller.camera.zoom;
    controller.move(currentCenter, currentZoom - 1);
  }

  void _handleCenterLocation(MapController controller, LocationState state) {
    if (state is LocationLoaded) {
      final location = state.location;
      controller.move(LatLng(location.latitude, location.longitude), 15.0);
    }
  }
}
