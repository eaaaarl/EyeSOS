import 'dart:convert';
import 'package:eyesos/features/map/data/models/road_risk.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:eyesos/features/map/data/datasources/road_risk_mock_data.dart';

class MapRemoteDatasource {
  static const String _bbox = '8.55,125.98,8.72,126.18';
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  Future<List<RoadSegment>> fetchRoads() async {
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

          roads.add(RoadRiskMockData.assignMockRisk(id, name, coords));
        }
        return roads;
      } catch (e) {
        debugPrint('[RoadRiskRepository] Overpass failed ($endpoint): $e');
      }
    }
    throw Exception('All Overpass endpoints failed');
  }
}
