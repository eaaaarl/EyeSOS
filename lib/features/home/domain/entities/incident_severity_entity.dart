import 'package:flutter/material.dart';

enum IncidentSeverityEntity {
  minor,
  moderate,
  high,
  critical,
  emergency;

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
      case IncidentSeverityEntity.emergency:
        return 'Emergency';
    }
  }

  String get description {
    switch (this) {
      case IncidentSeverityEntity.minor:
        return 'Scratches, small dents, no injuries';
      case IncidentSeverityEntity.moderate:
        return 'Significant damage, minor injuries';
      case IncidentSeverityEntity.high:
        return 'Severe damage, major injuries';
      case IncidentSeverityEntity.critical:
        return 'Life-threatening situation';
      case IncidentSeverityEntity.emergency:
        return 'Immediate assistance required, fire or fatal';
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
      case IncidentSeverityEntity.emergency:
        return Colors.red[900]!;
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
      case IncidentSeverityEntity.emergency:
        return Icons.local_fire_department_rounded;
    }
  }
}
