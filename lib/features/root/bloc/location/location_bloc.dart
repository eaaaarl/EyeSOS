import 'package:eyesos/features/root/bloc/location/location_event.dart';
import 'package:eyesos/features/root/bloc/location/location_state.dart';
import 'package:eyesos/features/root/models/location_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<FetchLocationRequested>((event, emit) async {
      emit(LocationLoading());
      try {
        Position position = await _determinePosition();

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        String address =
            "${placemarks.first.name}, ${placemarks.first.locality}";

        emit(
          LocationLoaded(
            UserLocation(
              latitude: position.latitude,
              longitude: position.longitude,
              address: address,
            ),
          ),
        );
      } catch (e) {
        emit(LocationError(e.toString()));
      }
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if GPS is actually turned on
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Instead of just returning an error, we ask the user to open settings
      bool opened = await Geolocator.openLocationSettings();
      if (!opened) {
        return Future.error('Location services are disabled.');
      }
      // Note: After they come back from settings, we check again
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are still disabled.');
      }
    }

    // 2. Check/Request Permissions (Standard Logic)
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    // Handle permanent denial (User clicked "Never ask again")
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return Future.error(
        'Permissions are permanently denied. Please enable them in settings.',
      );
    }

    // 3. Get the actual coordinates
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter:
            100, // Optional: minimum distance (in meters) before update
      ),
    );
  }
}
