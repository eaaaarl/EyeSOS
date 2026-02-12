import 'package:eyesos/features/root/models/location_model.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final UserLocation location;
  LocationLoaded(this.location);
}

class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}
