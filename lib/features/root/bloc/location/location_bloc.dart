import 'package:eyesos/features/root/bloc/location/location_event.dart';
import 'package:eyesos/features/root/bloc/location/location_state.dart';
import 'package:eyesos/features/root/models/location_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  // Cache the last known location to avoid unnecessary API calls
  UserLocation? _cachedLocation;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  LocationBloc() : super(LocationInitial()) {
    on<FetchLocationRequested>(_onFetchLocationRequested);
  }

  Future<void> _onFetchLocationRequested(
    FetchLocationRequested event,
    Emitter<LocationState> emit,
  ) async {
    if (!event.forceRefresh &&
        _cachedLocation != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      emit(
        LocationLoaded(location: _cachedLocation!, timestamp: _lastFetchTime!),
      );
      return;
    }

    emit(LocationLoading());

    try {
      final permissionStatus = await _handleLocationPermission();

      if (!permissionStatus) {
        emit(
          LocationError(
            message:
                'Location permission denied. Please enable it in app settings.',
          ),
        );
        return;
      }

      final serviceEnabled = await _checkLocationService();

      if (!serviceEnabled) {
        emit(
          LocationError(
            message: 'Location services are disabled. Please enable GPS.',
          ),
        );
        return;
      }

      final position = await _getCurrentPosition();

      String address = 'Unknown location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5), onTimeout: () => <Placemark>[]);

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = _formatAddress(placemark);
        }
      } catch (e) {
        address =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      _cachedLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
      );
      _lastFetchTime = DateTime.now();

      emit(
        LocationLoaded(location: _cachedLocation!, timestamp: _lastFetchTime!),
      );
    } catch (e) {
      emit(LocationError(message: _getErrorMessage(e)));
    }
  }

  Future<bool> _handleLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  Future<bool> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      await Future.delayed(const Duration(milliseconds: 500));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    return serviceEnabled;
  }

  Future<Position> _getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 10),
      ),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Location request timed out. Please try again.');
      },
    );
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.name != null && placemark.name!.isNotEmpty) {
      parts.add(placemark.name!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.subAdministrativeArea != null &&
        placemark.subAdministrativeArea!.isNotEmpty) {
      parts.add(placemark.subAdministrativeArea!);
    }

    return parts.join(', ').isEmpty ? 'Unknown location' : parts.join(', ');
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('timeout')) {
      return 'Location request timed out. Please ensure GPS is enabled and try again.';
    }
    if (error.toString().contains('permission')) {
      return 'Location permission denied. Please enable it in settings.';
    }
    if (error.toString().contains('service')) {
      return 'Location services are disabled. Please enable GPS.';
    }
    return 'Failed to get location: ${error.toString()}';
  }

  void clearCache() {
    _cachedLocation = null;
    _lastFetchTime = null;
  }
}
