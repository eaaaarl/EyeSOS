abstract class LocationEvent {}

class FetchLocationRequested extends LocationEvent {
  final bool forceRefresh;

  FetchLocationRequested({this.forceRefresh = false});
}
