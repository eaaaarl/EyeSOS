import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AccidentReportEvent extends Equatable {
  const AccidentReportEvent();

  @override
  List<Object?> get props => [];
}

// Event to capture image from camera
class ImageCaptured extends AccidentReportEvent {
  final File image;

  const ImageCaptured(this.image);

  @override
  List<Object?> get props => [image];
}

// Event to remove the selected image
class ImageRemoved extends AccidentReportEvent {
  const ImageRemoved();
}

// Event to fetch current location
class LocationRequested extends AccidentReportEvent {
  const LocationRequested();
}

// Event when description text changes
class DescriptionChanged extends AccidentReportEvent {
  final String description;

  const DescriptionChanged(this.description);

  @override
  List<Object?> get props => [description];
}

// Event to submit the accident report
class ReportSubmitted extends AccidentReportEvent {
  final String userId;
  final String reporterName;
  final String? email;
  final String? phoneNumber;

  const ReportSubmitted({
    required this.userId,
    required this.reporterName,
    this.email,
    this.phoneNumber,
  });
  @override
  List<Object> get props => [userId, reporterName];
}

// Event to reset the form
class ReportFormReset extends AccidentReportEvent {
  const ReportFormReset();
}
