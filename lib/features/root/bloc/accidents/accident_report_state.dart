import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:eyesos/features/root/validations/description.dart';
import 'package:formz/formz.dart';
import 'package:geolocator/geolocator.dart';

class AccidentReportState extends Equatable {
  final File? imageUrl;
  final Position? currentPosition;
  final String? currentAddress;
  final Description description;
  final FormzSubmissionStatus formStatus;
  final bool isValid; // This captures the Formz.validate result
  final bool isLoadingLocation;
  final String? locationError;
  final String? submitError;
  final bool isSubmitSuccessfull;
  final DateTime? lastUpdated; // Add this field

  const AccidentReportState({
    this.lastUpdated,
    this.isValid = false,
    this.imageUrl,
    this.currentAddress,
    this.currentPosition,
    this.description = const Description.pure(),
    this.formStatus = FormzSubmissionStatus.initial,
    this.isLoadingLocation = false,
    this.isSubmitSuccessfull = false,
    this.locationError,
    this.submitError,
  });

  AccidentReportState copyWith({
    File? imageUrl,
    Position? currentPosition,
    String? currentAddress,
    Description? description,
    FormzSubmissionStatus? formStatus,
    bool? isLoadingLocation,
    String? locationError,
    String? submitError,
    bool? isSubmitSuccessfull,
    bool? isValid, // Changed to nullable bool
    bool clearImage = false,
    bool clearLocation = false,
    bool clearLocationError = false,
    bool clearSubmitError = false,
    DateTime? lastUpdated,
  }) {
    return AccidentReportState(
      // Use the new value, or the old value, unless clearing
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      currentPosition: clearLocation
          ? null
          : (currentPosition ?? this.currentPosition),
      currentAddress: clearLocation
          ? null
          : (currentAddress ?? this.currentAddress),
      description: description ?? this.description,
      formStatus: formStatus ?? this.formStatus,
      isValid: isValid ?? this.isValid, // Correctly pass validation status
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationError: clearLocationError
          ? null
          : (locationError ?? this.locationError),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      isSubmitSuccessfull: isSubmitSuccessfull ?? this.isSubmitSuccessfull,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Validation helpers
  bool get isImageValid => imageUrl != null;
  bool get isLocationValid => currentPosition != null;

  // Logic helper for the UI button
  bool get canSubmit => isImageValid && isLocationValid && isValid;

  @override
  List<Object?> get props => [
    imageUrl,
    currentPosition,
    currentAddress,
    description,
    formStatus,
    isValid, // Add this to props so Bloc knows when it changes!
    isLoadingLocation,
    locationError,
    submitError,
    isSubmitSuccessfull,
    lastUpdated,
  ];
}
