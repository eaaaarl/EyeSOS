import 'dart:async';
import 'package:eyesos/features/map/bloc/location_event.dart';
import 'package:eyesos/features/map/bloc/location_state.dart';
import 'package:eyesos/features/map/data/models/location_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  // Cache the last known location to avoid unnecessary API calls
  UserLocation? _cachedLocation;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  StreamSubscription<Position>? _positionSubscription;

  LocationBloc() : super(LocationInitial()) {
    on<FetchLocationRequested>(_onFetchLocationRequested);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<LocationUpdated>(_onLocationUpdated);
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    // 1. Check permissions / services
    final permissionStatus = await _handleLocationPermission();
    if (!permissionStatus) {
      emit(LocationError(message: 'Permission denied for tracking.'));
      return;
    }

    final serviceEnabled = await _checkLocationService();
    if (!serviceEnabled) {
      emit(LocationError(message: 'GPS disabled. Cannot track location.'));
      return;
    }

    // 2. Cancel existing if any
    await _positionSubscription?.cancel();

    // 3. Start stream
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // update every 5 meters
          ),
        ).listen(
          (position) => add(LocationUpdated(position)),
          onError: (e) => add(FetchLocationRequested(forceRefresh: true)),
        );
  }

  Future<void> _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) async {
    final position = event.position;

    // We update address less frequently to save resources
    String address = _cachedLocation?.address ?? 'Updating...';

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

    // Async reverse geocode to update address if it was 'Updating...' or old
    unawaited(_updateAddress(position));
  }

  Future<void> _updateAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3));

      if (placemarks.isNotEmpty && _cachedLocation != null) {
        final newAddress = _formatAddress(placemarks.first);
        if (newAddress != _cachedLocation!.address) {
          _cachedLocation = UserLocation(
            latitude: _cachedLocation!.latitude,
            longitude: _cachedLocation!.longitude,
            address: newAddress,
            accuracy: _cachedLocation!.accuracy,
          );
          // Note: Since we are outside the Emitter, we don't 'emit' here immediately
          // but the next stream update or manual fetch will catch it.
          // In a more robust implementation, we might trigger another event.
        }
      }
    } catch (_) {}
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
