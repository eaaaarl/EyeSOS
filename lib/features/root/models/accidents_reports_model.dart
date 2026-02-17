class AccidentReport {
  final String id;
  final DateTime createdAt;
  final String reportNumber;
  final String? severity;
  final String reporterName;
  final String? reporterNotes;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final List<String> imageUrls;
  final bool isSos;

  AccidentReport({
    required this.id,
    required this.createdAt,
    required this.reportNumber,
    this.severity,
    required this.reporterName,
    this.reporterNotes,
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    required this.imageUrls,
    required this.isSos,
  });

  factory AccidentReport.fromJson(Map<String, dynamic> json) {
    final imageList =
        (json['accident_images'] as List<dynamic>?)
            ?.map((e) => e['url'] as String)
            .toList() ??
        [];

    return AccidentReport(
      id: json['id'],
      // Parse the ISO8601 string from Supabase
      createdAt: DateTime.parse(json['created_at']),
      reportNumber: json['report_number'] ?? 'N/A',
      severity: json['severity'] ?? 'unknown',
      reporterName: json['reporter_name'] ?? 'Anonymous',
      reporterNotes: json['reporter_notes'],
      // Supabase numbers can come back as int or double, .toDouble() is safer
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationAddress: json['location_address'] ?? 'Unknown Location',
      // Convert the dynamic list to a List<String>
      imageUrls: imageList,
      isSos: json['sos_type'] ?? false,
    );
  }
}
