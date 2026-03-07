import 'package:flutter/material.dart';

enum AccidentStatus {
  newStatus,
  verified,
  deleted,
  resolved,
  inProgress,
  closed,
  pending,
  idle;

  String get label {
    switch (this) {
      case AccidentStatus.newStatus:
        return 'New';
      case AccidentStatus.verified:
        return 'Verified';
      case AccidentStatus.deleted:
        return 'Deleted';
      case AccidentStatus.resolved:
        return 'Resolved';
      case AccidentStatus.inProgress:
        return 'In Progress';
      case AccidentStatus.closed:
        return 'Closed';
      case AccidentStatus.pending:
        return 'Pending';
      case AccidentStatus.idle:
        return 'Idle';
    }
  }

  String get displayName => label;

  Color get color {
    switch (this) {
      case AccidentStatus.newStatus:
        return Colors.blue[600]!;
      case AccidentStatus.verified:
        return Colors.cyan[600]!;
      case AccidentStatus.deleted:
        return Colors.grey[600]!;
      case AccidentStatus.resolved:
        return Colors.green[600]!;
      case AccidentStatus.inProgress:
        return Colors.orange[600]!;
      case AccidentStatus.closed:
        return Colors.brown[600]!;
      case AccidentStatus.pending:
        return Colors.purple[600]!;
      case AccidentStatus.idle:
        return Colors.blueGrey[600]!;
    }
  }

  IconData get icon {
    switch (this) {
      case AccidentStatus.newStatus:
        return Icons.fiber_new_outlined;
      case AccidentStatus.verified:
        return Icons.verified_user_outlined;
      case AccidentStatus.deleted:
        return Icons.delete_outline;
      case AccidentStatus.resolved:
        return Icons.check_circle_outline;
      case AccidentStatus.inProgress:
        return Icons.pending_actions;
      case AccidentStatus.closed:
        return Icons.lock_outline;
      case AccidentStatus.pending:
        return Icons.schedule;
      case AccidentStatus.idle:
        return Icons.not_interested;
    }
  }

  static AccidentStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return AccidentStatus.newStatus;
      case 'VERIFIED':
        return AccidentStatus.verified;
      case 'DELETED':
        return AccidentStatus.deleted;
      case 'RESOLVED':
        return AccidentStatus.resolved;
      case 'IN_PROGRESS':
        return AccidentStatus.inProgress;
      case 'CLOSED':
        return AccidentStatus.closed;
      case 'PENDING':
        return AccidentStatus.pending;
      case 'IDLE':
        return AccidentStatus.idle;
      default:
        return AccidentStatus.newStatus;
    }
  }

  String toJson() {
    switch (this) {
      case AccidentStatus.newStatus:
        return 'NEW';
      case AccidentStatus.verified:
        return 'VERIFIED';
      case AccidentStatus.deleted:
        return 'DELETED';
      case AccidentStatus.resolved:
        return 'RESOLVED';
      case AccidentStatus.inProgress:
        return 'IN_PROGRESS';
      case AccidentStatus.closed:
        return 'CLOSED';
      case AccidentStatus.pending:
        return 'PENDING';
      case AccidentStatus.idle:
        return 'IDLE';
    }
  }
}
