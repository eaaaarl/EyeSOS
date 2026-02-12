import 'package:eyesos/features/root/repository/accident_report_repository.dart';
import 'package:eyesos/features/root/validations/description.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
      // 1. Check permissions (standard Geolocator stuff)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 2. Get FRESH position specifically for this report
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter:
              100, // Optional: minimum distance (in meters) before update
        ),
      );

      // 3. Get FRESH address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "Address not found";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}";
      }

      // 4. Update the state with the NEW data
      emit(
        state.copyWith(
          currentPosition: position,
          currentAddress: address,
          isLoadingLocation: false,
        ),
      );
    } catch (e) {
      // Use copyWith to update the error message in the state
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
