class UserLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
  });
}
