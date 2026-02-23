import 'package:geolocator/geolocator.dart';

abstract class LocationEvent {}

class FetchLocationRequested extends LocationEvent {
  final bool forceRefresh;

  FetchLocationRequested({this.forceRefresh = false});
}

class StartLocationTracking extends LocationEvent {}

class StopLocationTracking extends LocationEvent {}

class LocationUpdated extends LocationEvent {
  final Position position;
  LocationUpdated(this.position);
}
