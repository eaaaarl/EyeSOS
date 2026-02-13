import 'package:eyesos/features/root/repository/accident_report_repository.dart';
import 'package:eyesos/features/root/validations/description.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'accident_report_event.dart';
import 'accident_report_state.dart';

class AccidentReportBloc
    extends Bloc<AccidentReportEvent, AccidentReportState> {
  final AccidentReportRepository accidentReportRepository;

  AccidentReportBloc(this.accidentReportRepository)
    : super(const AccidentReportState()) {
    on<ImageCaptured>(_onImageCaptured);
    on<ImageRemoved>(_onImageRemoved);
    on<LocationRequested>(_onLocationRequested);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<ReportSubmitted>(_onReportSubmitted);
    on<ReportFormReset>(_onReportFormReset);
  }

  void _onImageCaptured(
    ImageCaptured event,
    Emitter<AccidentReportState> emit,
  ) {
    emit(
      state.copyWith(
        imageUrl: event.image,
        lastUpdated: DateTime.now(), // Forces a unique state
        isValid: Formz.validate([state.description]),
      ),
    );
  }

  void _onImageRemoved(ImageRemoved event, Emitter<AccidentReportState> emit) {
    emit(
      state.copyWith(
        clearImage: true,
        isValid: Formz.validate([state.description]),
      ),
    );
  }

  Future<void> _onLocationRequested(
    LocationRequested event,
    Emitter<AccidentReportState> emit,
  ) async {
    emit(state.copyWith(isLoadingLocation: true, clearLocationError: true));

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(
          state.copyWith(
            isLoadingLocation: false,
            locationError:
                'Location services are disabled. Please enable them in settings.',
          ),
        );
        return;
      }

      var status = await Permission.location.request();

      if (status.isDenied) {
        emit(
          state.copyWith(
            isLoadingLocation: false,
            locationError:
                'Location permission denied. Please grant permission.',
          ),
        );
        return;
      }

      if (status.isPermanentlyDenied) {
        emit(
          state.copyWith(
            isLoadingLocation: false,
            locationError:
                'Location permission permanently denied. Please enable in settings.',
          ),
        );
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).timeout(const Duration(seconds: 20));
      } catch (e) {
        if (e.toString().contains('timeout')) {
          emit(
            state.copyWith(
              isLoadingLocation: false,
              locationError:
                  'Unable to get your current location. Please ensure GPS is enabled and you have a clear view of the sky.',
            ),
          );
        } else {
          emit(
            state.copyWith(
              isLoadingLocation: false,
              locationError: 'Failed to get location: ${e.toString()}',
            ),
          );
        }
        return;
      }

      String address = "Fetching address...";
      emit(
        state.copyWith(
          currentPosition: position,
          currentAddress: address,
          isLoadingLocation: false,
        ),
      );
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address =
              "${place.street ?? ''}, ${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}";

          emit(state.copyWith(currentAddress: address));
        }
      } catch (e) {
        emit(
          state.copyWith(
            currentAddress:
                "Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingLocation: false,
          locationError: 'Failed to get location: ${e.toString()}',
        ),
      );
    }
  }

  void _onDescriptionChanged(
    DescriptionChanged event,
    Emitter<AccidentReportState> emit,
  ) {
    final description = Description.dirty(event.description);
    emit(
      state.copyWith(
        description: description,
        isValid: Formz.validate([description]),
      ),
    );
  }

  Future<void> _onReportSubmitted(
    ReportSubmitted event,
    Emitter<AccidentReportState> emit,
  ) async {
    // 1. Calculate validity locally
    final description = Description.dirty(state.description.value);
    final isFormValid = Formz.validate([description]);

    // 2. Emit the update
    emit(state.copyWith(description: description, isValid: isFormValid));

    // 3. CHECK THE LOCAL VARIABLE, NOT THE STATE
    if (!isFormValid) {
      return;
    }

    // 4. Now it will actually reach this part!
    emit(state.copyWith(formStatus: FormzSubmissionStatus.inProgress));

    try {
      await accidentReportRepository.submitAccidentReport(
        reportedBy: event.userId,
        latitude: state.currentPosition!.latitude,
        longitude: state.currentPosition!.longitude,
        locationAddress: state.currentAddress,
        reporterNotes: state.description.value,
        reporterName: event.reporterName,
        imageUrl: state.imageUrl,
        reporterContact: event.phoneNumber,
        accuracy: state.currentPosition!.accuracy,
      );

      emit(
        state.copyWith(
          formStatus: FormzSubmissionStatus.success,
          isSubmitSuccessfull: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          formStatus: FormzSubmissionStatus.failure,
          submitError: e.toString(),
        ),
      );
    }
  }

  void _onReportFormReset(
    ReportFormReset event,
    Emitter<AccidentReportState> emit,
  ) {
    emit(const AccidentReportState());
  }
}
