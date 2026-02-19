class AccidentReportEntity {
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

  AccidentReportEntity({
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
}
