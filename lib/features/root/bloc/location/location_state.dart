import 'package:equatable/equatable.dart';
import 'package:eyesos/features/root/models/location_model.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final UserLocation location;
  final DateTime timestamp;

  const LocationLoaded({required this.location, required this.timestamp});

  @override
  List<Object?> get props => [location, timestamp];

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class LocationError extends LocationState {
  final String message;
  const LocationError({required this.message});
  @override
  List<Object?> get props => [message];
}
