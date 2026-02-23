import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:eyesos/features/map/data/models/place_model.dart';

class RouteRemoteDatasource {
  // Nominatim: free OSM geocoding, no API key needed
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';

  // OSRM: free OSM routing, no API key needed
  static const String _osrmBase = 'https://router.project-osrm.org';

  // Required by Nominatim terms of use - identify your app
  static const Map<String, String> _headers = {
    'User-Agent': 'EyeSOS/1.0 (eyesos@app.com)',
    'Accept-Language': 'en',
  };

  /// Search for places by name - returns list of suggestions
  Future<List<PlaceModel>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_nominatimBase/search?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&addressdetails=1'
        '&countrycodes=ph', // limit to Philippines - change or remove if needed
      );

      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception('Nominatim error: ${res.statusCode}');
      }

      final results = jsonDecode(res.body) as List;
      return results
          .map((r) => PlaceModel.fromNominatim(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[RouteRemoteDatasource] searchPlaces error: $e');
      rethrow;
    }
  }

  /// Get route from origin to destination using OSRM
  /// Returns list of LatLng points representing the route path
  Future<({List<LatLng> points, double distance, double duration})> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // OSRM format: /route/v1/{profile}/{lon,lat};{lon,lat}
      final uri = Uri.parse(
        '$_osrmBase/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('OSRM error: ${res.statusCode}');
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (json['code'] != 'Ok') {
        throw Exception('OSRM: ${json['code']} - ${json['message'] ?? ''}');
      }

      final routes = json['routes'] as List;
      if (routes.isEmpty) throw Exception('No route found');

      final route = routes.first as Map<String, dynamic>;
      final distance = (route['distance'] as num).toDouble(); // meters
      final duration = (route['duration'] as num).toDouble(); // seconds

      // GeoJSON coordinates come as [lon, lat] pairs
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;

      final points = coordinates
          .map(
            (c) => LatLng(
              (c[1] as num).toDouble(), // lat
              (c[0] as num).toDouble(), // lon
            ),
          )
          .toList();

      return (points: points, distance: distance, duration: duration);
    } catch (e) {
      debugPrint('[RouteRemoteDatasource] fetchRoute error: $e');
      rethrow;
    }
  }
}
