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
    // Return cached location if still fresh (unless force refresh)
    if (!event.forceRefresh &&
        _cachedLocation != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      emit(LocationLoaded(_cachedLocation!));
      return;
    }

    emit(LocationLoading());

    try {
      // Step 1: Check and request permissions using permission_handler
      final permissionStatus = await _handleLocationPermission();

      if (!permissionStatus) {
        emit(
          LocationError(
            'Location permission denied. Please enable it in app settings.',
          ),
        );
        return;
      }

      // Step 2: Check if location services are enabled
      final serviceEnabled = await _checkLocationService();

      if (!serviceEnabled) {
        emit(
          LocationError('Location services are disabled. Please enable GPS.'),
        );
        return;
      }

      // Step 3: Get current position with timeout
      final position = await _getCurrentPosition();

      // Step 4: Reverse geocoding with error handling
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
        // If geocoding fails, we still have coordinates
        address =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      // Cache the result
      _cachedLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
      _lastFetchTime = DateTime.now();

      emit(LocationLoaded(_cachedLocation!));
    } catch (e) {
      emit(LocationError(_getErrorMessage(e)));
    }
  }

  /// Handle location permissions using permission_handler
  Future<bool> _handleLocationPermission() async {
    // Check current permission status
    PermissionStatus status = await Permission.location.status;

    // If already granted, return true
    if (status.isGranted) return true;

    // If denied, request permission
    if (status.isDenied) {
      status = await Permission.location.request();
      return status.isGranted;
    }

    // If permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Check if location services are enabled
  Future<bool> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Try to open location settings
      await Geolocator.openLocationSettings();

      // Wait a bit for user to potentially enable it
      await Future.delayed(const Duration(milliseconds: 500));

      // Check again
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    return serviceEnabled;
  }

  /// Get current position with optimized settings
  Future<Position> _getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
        forceLocationManager:
            false, // Use FusedLocationProvider for faster results
        intervalDuration: const Duration(seconds: 10),
        // Enables faster location on Android
      ),
    ).timeout(
      const Duration(seconds: 15), // Add timeout to prevent hanging
      onTimeout: () {
        throw Exception('Location request timed out. Please try again.');
      },
    );
  }

  /// Format address in a readable way
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

  /// Get user-friendly error message
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

  /// Clear cached location (useful for force refresh)
  void clearCache() {
    _cachedLocation = null;
    _lastFetchTime = null;
  }
}
