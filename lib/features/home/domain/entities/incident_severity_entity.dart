import 'package:flutter/material.dart';

enum IncidentSeverityEntity {
  minor,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case IncidentSeverityEntity.minor:
        return 'Minor';
      case IncidentSeverityEntity.moderate:
        return 'Moderate';
      case IncidentSeverityEntity.high:
        return 'High';
      case IncidentSeverityEntity.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case IncidentSeverityEntity.minor:
        return 'Scratches, small dents, or cosmetic damage. No injuries reported.';
      case IncidentSeverityEntity.moderate:
        return 'Significant damage (e.g., broken lights, body dents). Minor injuries needing basic first aid.';
      case IncidentSeverityEntity.high:
        return 'Severe vehicle damage (e.g., airbags deployed). Major injuries requiring medical attention.';
      case IncidentSeverityEntity.critical:
        return 'Life-threatening situation. Multiple vehicles, fire, or unconscious persons. Call MDRRMC/Emergency immediately.';
    }
  }

  Color get color {
    switch (this) {
      case IncidentSeverityEntity.minor:
        return Colors.green;
      case IncidentSeverityEntity.moderate:
        return Colors.yellow[700]!;
      case IncidentSeverityEntity.high:
        return Colors.orange[700]!;
      case IncidentSeverityEntity.critical:
        return Colors.red[700]!;
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentSeverityEntity.minor:
        return Icons.info_outline;
      case IncidentSeverityEntity.moderate:
        return Icons.warning_amber_rounded;
      case IncidentSeverityEntity.high:
        return Icons.warning_rounded;
      case IncidentSeverityEntity.critical:
        return Icons.error_outline_rounded;
    }
  }
}
