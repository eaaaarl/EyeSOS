import 'package:latlong2/latlong.dart';

class PlaceModel {
  final String displayName;
  final String shortName;
  final LatLng location;

  const PlaceModel({
    required this.displayName,
    required this.shortName,
    required this.location,
  });

  factory PlaceModel.fromNominatim(Map<String, dynamic> json) {
    final lat = double.parse(json['lat'] as String);
    final lon = double.parse(json['lon'] as String);

    // Build a short readable name from address components
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final shortName =
        address['road'] ??
        address['hamlet'] ??
        address['village'] ??
        address['town'] ??
        address['city'] ??
        (json['display_name'] as String).split(',').first;

    return PlaceModel(
      displayName: json['display_name'] as String,
      shortName: shortName as String,
      location: LatLng(lat, lon),
    );
  }
}
