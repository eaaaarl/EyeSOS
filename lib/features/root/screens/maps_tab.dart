import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eyesos/features/root/bloc/location/location_bloc.dart';
import 'package:eyesos/features/root/bloc/location/location_event.dart';
import 'package:eyesos/features/root/bloc/location/location_state.dart';
import 'package:google_fonts/google_fonts.dart';

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  double _currentRadius = 60.0;
  bool _showHeatmap = true;
  bool _showLegend = true;
  String _selectedMapStyle = 'standard';

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

  // Map style options
  final Map<String, String> _mapStyles = {
    'standard': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'satellite':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  };

  @override
  Widget build(BuildContext context) {
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
              content: Text(state.message),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      builder: (context, locationState) {
        return BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
          builder: (context, connectivityState) {
            // ✅ Show fallback UI when disconnected
            if (connectivityState == ConnectivityStatus.disconnected) {
              return _buildNoInternetFallback();
            }

            // ✅ Show normal map when connected
            return Scaffold(
              body: Stack(
                children: [
                  // Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(8.6327, 126.0945),
                      initialZoom: 12.0,
                      onMapReady: () => setState(() => _isMapReady = true),
                      onPositionChanged: (camera, hasGesture) {
                        setState(() {
                          _currentRadius = 800 / camera.zoom!;
                          if (_currentRadius < 20) _currentRadius = 20;
                          if (_currentRadius > 150) _currentRadius = 150;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _mapStyles[_selectedMapStyle]!,
                        userAgentPackageName: dotenv.env['PACKAGE_NAME']!,
                      ),
                      if (_showHeatmap && _accidentData.isNotEmpty)
                        HeatMapLayer(
                          heatMapDataSource: InMemoryHeatMapDataSource(
                            data: _accidentData,
                          ),
                          heatMapOptions: HeatMapOptions(
                            radius: _currentRadius,
                            blurFactor: 10.0,
                            gradient: {
                              0.2: Colors.blue,
                              0.5: Colors.yellow,
                              0.8: Colors.red,
                            },
                          ),
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
                              child: _buildUserLocationMarker(),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Loading skeleton
                  if (!_isMapReady) _buildMapSkeleton(),

                  // UI Controls (only show when map is ready)
                  if (_isMapReady) ...[
                    _buildTopBar(),
                    _buildLegend(),
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

  // ✅ --- No Internet Fallback UI (replaces the entire map) ---
  Widget _buildNoInternetFallback() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 80,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Maps require an active internet connection to load map tiles and location data.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Trigger connectivity check
                      context.read<ConnectivityBloc>().add(CheckConnectivity());
                      // Also try to fetch location
                      context.read<LocationBloc>().add(
                        FetchLocationRequested(),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    label: Text(
                      'Retry Connection',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Help Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Check your WiFi or mobile data',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[700],
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
    ).animate().fadeIn(duration: 300.ms);
  }

  // --- Top Bar with Title and Map Style Toggle ---
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hazard Map',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Lianga, Surigao del Sur',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Map Style Toggle
                _buildMapStyleButton(),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(),
    );
  }

  // --- Map Style Toggle Button ---
  Widget _buildMapStyleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        initialValue: _selectedMapStyle,
        onSelected: (value) {
          setState(() => _selectedMapStyle = value);
        },
        icon: Icon(Icons.layers, color: Colors.red[700], size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'standard',
            child: Row(
              children: [
                Icon(
                  Icons.map,
                  size: 18,
                  color: _selectedMapStyle == 'standard'
                      ? Colors.red[700]
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Standard',
                  style: TextStyle(
                    color: _selectedMapStyle == 'standard'
                        ? Colors.red[700]
                        : Colors.black,
                    fontWeight: _selectedMapStyle == 'standard'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'satellite',
            child: Row(
              children: [
                Icon(
                  Icons.satellite_alt,
                  size: 18,
                  color: _selectedMapStyle == 'satellite'
                      ? Colors.red[700]
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Satellite',
                  style: TextStyle(
                    color: _selectedMapStyle == 'satellite'
                        ? Colors.red[700]
                        : Colors.black,
                    fontWeight: _selectedMapStyle == 'satellite'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Legend Widget ---
  Widget _buildLegend() {
    if (!_showLegend) return const SizedBox.shrink();

    return Positioned(
      top: 110,
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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Risk Level',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => setState(() => _showLegend = false),
                  child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _legendItem(Colors.red, 'High Risk', '80-100%'),
            const SizedBox(height: 6),
            _legendItem(Colors.yellow, 'Medium Risk', '50-80%'),
            const SizedBox(height: 6),
            _legendItem(Colors.blue, 'Low Risk', '20-50%'),
            const SizedBox(height: 10),
            _legendItem(Colors.blue, 'Your Location', '', icon: Icons.circle),
          ],
        ),
      ).animate().fadeIn().slideX(begin: -0.2),
    );
  }

  Widget _legendItem(
    Color color,
    String label,
    String percentage, {
    IconData? icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: icon != null ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: icon != null ? Border.all(color: color, width: 2) : null,
          ),
          child: icon != null ? Icon(icon, color: color, size: 10) : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (percentage.isNotEmpty)
              Text(
                percentage,
                style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[500]),
              ),
          ],
        ),
      ],
    );
  }

  // --- Control Buttons (Right Side) ---
  Widget _buildControlButtons(LocationState state) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle Heatmap
          _buildControlButton(
            icon: _showHeatmap ? Icons.visibility : Icons.visibility_off,
            tooltip: _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
            onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
          ),
          const SizedBox(height: 10),

          // Toggle Legend
          if (!_showLegend)
            _buildControlButton(
              icon: Icons.legend_toggle,
              tooltip: 'Show Legend',
              onPressed: () => setState(() => _showLegend = true),
            ),
          if (!_showLegend) const SizedBox(height: 10),

          // Zoom In
          _buildControlButton(
            icon: Icons.add,
            tooltip: 'Zoom In',
            onPressed: () {
              final currentCenter = _mapController.camera.center;
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(currentCenter, currentZoom + 1);
            },
          ),
          const SizedBox(height: 10),

          // Zoom Out
          _buildControlButton(
            icon: Icons.remove,
            tooltip: 'Zoom Out',
            onPressed: () {
              final currentCenter = _mapController.camera.center;
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(currentCenter, currentZoom - 1);
            },
          ),
          const SizedBox(height: 10),

          // My Location (Larger, Primary)
          _buildLocationButton(state),
        ],
      ).animate().fadeIn().slideX(begin: 0.3),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.red[700], size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton(LocationState state) {
    return Material(
      color: Colors.red[700],
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      child: InkWell(
        onTap: state is LocationLoading
            ? null
            : () => context.read<LocationBloc>().add(FetchLocationRequested()),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: state is LocationLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : const Icon(Icons.my_location, color: Colors.white, size: 26),
        ),
      ),
    ).animate().scale();
  }

  // --- User Location Marker (Simple red pin) ---
  Widget _buildUserLocationMarker() {
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

  // --- Loading Skeleton ---
  Widget _buildMapSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }
}
