import 'dart:async';
import 'dart:convert';
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
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:eyesos/features/root/bloc/location/location_bloc.dart';
import 'package:eyesos/features/root/bloc/location/location_event.dart';
import 'package:eyesos/features/root/bloc/location/location_state.dart';

// ─── Risk Level ───────────────────────────────────────────────────────────────

enum RiskLevel { critical, high, moderate, minor, none }

extension RiskLevelX on RiskLevel {
  Color get color {
    switch (this) {
      case RiskLevel.critical:
        return const Color(0xFFdc2626);
      case RiskLevel.high:
        return const Color(0xFFea580c);
      case RiskLevel.moderate:
        return const Color(0xFFca8a04);
      case RiskLevel.minor:
        return const Color(0xFF16a34a);
      case RiskLevel.none:
        return const Color(0xFF3b82f6);
    }
  }

  double get strokeWidth {
    switch (this) {
      case RiskLevel.critical:
        return 7;
      case RiskLevel.high:
        return 6;
      case RiskLevel.moderate:
        return 5;
      case RiskLevel.minor:
        return 4;
      case RiskLevel.none:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.critical:
        return 'Critical';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.minor:
        return 'Minor';
      case RiskLevel.none:
        return 'None';
    }
  }
}

// ─── Road Segment Model ───────────────────────────────────────────────────────

class RoadSegment {
  final int id;
  final String name;
  final List<LatLng> coordinates;
  final RiskLevel riskLevel;
  final int riskScore;
  final int accidentCount;

  const RoadSegment({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.riskLevel,
    required this.riskScore,
    required this.accidentCount,
  });
}

// ─── Mock Risk (replace with ML API later) ────────────────────────────────────

RiskLevel _scoreToRisk(int score) {
  if (score >= 75) return RiskLevel.critical;
  if (score >= 50) return RiskLevel.high;
  if (score >= 25) return RiskLevel.moderate;
  if (score >= 10) return RiskLevel.minor;
  return RiskLevel.none;
}

int _peakHourAdjustedScore(int base, int hour) {
  if (hour >= 6 && hour < 9) return (base * 1.3).clamp(0, 100).toInt();
  if (hour >= 17 && hour < 20) return (base * 1.2).clamp(0, 100).toInt();
  if (hour >= 21 || hour < 1) return (base * 1.15).clamp(0, 100).toInt();
  return base;
}

RoadSegment _assignMockRisk(int wayId, String name, List<LatLng> coords) {
  final n = name.toLowerCase();
  final hour = DateTime.now().hour;

  int base;
  int accidents;

  const highRisk = [
    'national highway',
    'surigao-davao coastal road',
    'bayugan',
    'canitlan',
  ];
  const modRisk = ['poblacion', 'lianga', 'st. christine', 'diatagon'];

  if (highRisk.any((k) => n.contains(k))) {
    final isCritical = wayId % 3 == 0;
    base = isCritical ? 75 + (wayId % 20) : 55 + (wayId % 20);
    accidents = isCritical ? 8 + (wayId % 7) : 4 + (wayId % 5);
  } else if (modRisk.any((k) => n.contains(k))) {
    base = 35 + (wayId % 20);
    accidents = 2 + (wayId % 4);
  } else {
    final roll = wayId % 10;
    if (roll < 1) {
      base = 80 + (wayId % 15);
      accidents = 9 + (wayId % 6);
    } else if (roll < 3) {
      base = 55 + (wayId % 20);
      accidents = 4 + (wayId % 5);
    } else if (roll < 5) {
      base = 30 + (wayId % 25);
      accidents = 2 + (wayId % 3);
    } else if (roll < 7) {
      base = 10 + (wayId % 20);
      accidents = wayId % 2;
    } else {
      base = wayId % 10;
      accidents = 0;
    }
  }

  final score = _peakHourAdjustedScore(base, hour);
  return RoadSegment(
    id: wayId,
    name: name,
    coordinates: coords,
    riskLevel: _scoreToRisk(score),
    riskScore: score,
    accidentCount: accidents,
  );
}

// ─── Overpass Fetch ───────────────────────────────────────────────────────────

const _bbox = '8.55,125.98,8.72,126.18';
const _endpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
];

Future<List<RoadSegment>> _fetchRoads() async {
  const query =
      '''
    [out:json][timeout:25];
    way["highway"~"^(primary|secondary|tertiary|residential|unclassified|trunk|road)\$"]
      ($_bbox);
    out geom;
  ''';

  for (final endpoint in _endpoints) {
    try {
      final res = await http
          .post(
            Uri.parse(endpoint),
            body: 'data=${Uri.encodeComponent(query)}',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) continue;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final ways = (json['elements'] as List?) ?? [];
      final roads = <RoadSegment>[];

      for (final way in ways) {
        final geometry = way['geometry'] as List?;
        if (geometry == null || geometry.length < 2) continue;

        final coords = geometry
            .map(
              (g) => LatLng(
                (g['lat'] as num).toDouble(),
                (g['lon'] as num).toDouble(),
              ),
            )
            .toList();

        final id = way['id'] as int;
        final tags = way['tags'] as Map<String, dynamic>? ?? {};
        final name =
            (tags['name'] ?? tags['highway'] ?? 'Unnamed Road') as String;

        roads.add(_assignMockRisk(id, name, coords));
      }
      return roads;
    } catch (e) {
      debugPrint('[MapsTab] Overpass failed ($endpoint): $e');
    }
  }
  throw Exception('All Overpass endpoints failed');
}

// ─── MapsTab ──────────────────────────────────────────────────────────────────

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  // Road risk state
  List<RoadSegment> _roads = [];
  bool _loadingRoads = true;
  String? _roadsError;
  bool _showRoads = true;
  bool _showLegend = true;

  // Tapped road popup
  RoadSegment? _tappedRoad;
  Offset? _tapPosition;

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
    _fetchRoads()
        .then((roads) {
          if (!mounted) return;
          setState(() {
            _roads = roads;
            _loadingRoads = false;
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() {
            _roadsError = e.toString();
            _loadingRoads = false;
          });
        });

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

  void _retryRoads() {
    setState(() {
      _loadingRoads = true;
      _roadsError = null;
    });
    _fetchRoads()
        .then((roads) {
          if (!mounted) return;
          setState(() {
            _roads = roads;
            _loadingRoads = false;
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() {
            _roadsError = e.toString();
            _loadingRoads = false;
          });
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
          onPressed: () => context.read<LocationBloc>().add(
            FetchLocationRequested(forceRefresh: true),
          ),
        ),
      ),
    );
  }

  // ── Peak hour label ─────────────────────────────────────────────────────────

  String get _peakHourLabel {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 9) return '🔴 Morning Rush';
    if (hour >= 17 && hour < 20) return '🔴 Evening Rush';
    if (hour >= 21 || hour < 1) return '🟠 Night — High Risk';
    return '🟢 Normal Hours';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                  // ── Map ────────────────────────────────────────────────────
                  _buildMap(locationState),

                  // ── Loading skeleton ───────────────────────────────────────
                  if (!_isMapReady) const MapSkeleton(),

                  if (_isMapReady) ...[
                    // ── Top bar ────────────────────────────────────────────
                    _buildTopBar(),

                    // ── Road loading indicator ─────────────────────────────
                    if (_loadingRoads)
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
                                color: Colors.black.withOpacity(0.1),
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
                    if (_roadsError != null)
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
                            border: Border.all(color: Colors.red.shade200),
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
                                onTap: _retryRoads,
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
                    if (_tappedRoad != null) _buildRoadPopup(_tappedRoad!),

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
  }

  // ── Map widget ──────────────────────────────────────────────────────────────

  // ── Tap detection ────────────────────────────────────────────────────────────
  // Finds the road whose polyline passes closest to the tapped LatLng.
  // Threshold: ~30 meters — close enough to feel accurate, forgiving enough to tap easily.

  static const double _tapThresholdMeters = 30.0;
  final Distance _distance = const Distance();

  void _onMapTap(TapPosition tapPos, LatLng latlng) {
    if (_roads.isEmpty) return;

    RoadSegment? nearest;
    double nearestDist = double.infinity;

    for (final road in _roads) {
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
        _tapPosition = tapPos.relative; // kept for future use
      });
    } else {
      // Tapped empty area — dismiss
      setState(() {
        _tappedRoad = null;
        _tapPosition = null;
      });
    }
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
        onTap: _onMapTap,
      ),
      children: [
        // Base tiles
        TileLayer(
          urlTemplate: _mapStyles[_selectedMapStyle]!,
          userAgentPackageName: dotenv.env['PACKAGE_NAME']!,
        ),

        // ── Risk road polylines (replaces heatmap) ──────────────────────────
        if (_showRoads && _roads.isNotEmpty)
          PolylineLayer(
            polylines: _roads
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
          shadowColor: color.withOpacity(0.2),
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
                    color: color.withOpacity(0.09),
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
                          _tapPosition = null;
                        }),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.07),
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
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
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
