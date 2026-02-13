import 'dart:io';
import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/root/bloc/accidents/accident_report_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accident_report_event.dart';
import 'package:eyesos/features/root/bloc/accidents/accident_report_state.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_report_load_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/widgets/accident_report/section_header.dart';
import 'package:flutter/material.dart';
import 'package:formz/formz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class AccidentReportScreen extends StatefulWidget {
  const AccidentReportScreen({super.key});

  @override
  State<AccidentReportScreen> createState() => _AccidentReportScreenState();
}

class _AccidentReportScreenState extends State<AccidentReportScreen> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AccidentReportBloc>().add(LocationRequested());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Open in-app camera
  Future<void> _openCamera(BuildContext context) async {
    if (!mounted) return;

    try {
      var status = await Permission.camera.request();

      if (!context.mounted) return;

      if (status.isGranted) {
        // Get available cameras
        final cameras = await availableCameras();

        if (cameras.isEmpty) {
          if (context.mounted) {
            _showErrorSnackbar(context, 'No camera found on this device');
          }
          return;
        }

        // Navigate to camera screen
        if (context.mounted) {
          final File? capturedImage = await Navigator.push<File>(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(camera: cameras.first),
            ),
          );

          if (capturedImage != null && context.mounted) {
            context.read<AccidentReportBloc>().add(
              ImageCaptured(capturedImage),
            );
          }
        }
      } else if (status.isDenied) {
        _showPermissionDialog(context, 'Camera');
      } else if (status.isPermanentlyDenied) {
        _showPermissionSettingsDialog(context, 'Camera');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to open camera: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Report Submitted!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your accident report has been sent to MDRRMC. Help is on the way.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.inter())),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$permissionType Permission Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please grant $permissionType permission to continue.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openCamera(context);
            },
            child: Text('Retry', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsDialog(
    BuildContext context,
    String permissionType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$permissionType Permission Denied',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Please enable $permissionType permission in app settings.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccidentReportBloc, AccidentReportState>(
      listener: (context, state) {
        final sessionState = context.read<SessionBloc>().state;
        String userId = '';

        if (sessionState is AuthAuthenticated) {
          userId = sessionState.userId;
        }

        if (state.isSubmitSuccessfull) {
          _showSuccessDialog();

          context.read<AccidentsReportLoadBloc>().add(
            LoadRecentsReports(userId: userId),
          );

          context.read<AccidentReportBloc>().add(ReportFormReset());
        }

        if (state.submitError != null) {
          _showErrorSnackbar(context, state.submitError!);
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Accident Report',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Form(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[700],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.car_crash,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report an Accident',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Help is on the way',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(),

                    const SizedBox(height: 20),

                    // Form Content
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step 1: Photo
                          SectionHeader(
                            number: '1',
                            title: 'Take Photo',
                            subtitle: 'Capture the accident scene',
                          ),
                          const SizedBox(height: 12),
                          _buildPhotoSection(),

                          const SizedBox(height: 24),

                          // Step 2: Location
                          SectionHeader(
                            number: '2',
                            title: 'Location',
                            subtitle: 'Your current position',
                          ),
                          const SizedBox(height: 12),
                          _buildLocationSection(),

                          const SizedBox(height: 24),

                          // Step 3: Description
                          SectionHeader(
                            number: '3',
                            title: 'Description',
                            subtitle: 'What happened?',
                          ),
                          const SizedBox(height: 12),
                          _buildDescriptionSection(context, state),

                          const SizedBox(height: 32),

                          // Submit Button
                          _buildSubmitButton(),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoSection() {
    return BlocBuilder<AccidentReportBloc, AccidentReportState>(
      buildWhen: (previous, current) => previous.imageUrl != current.imageUrl,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: state.imageUrl == null
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openCamera(context),
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to open camera',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Take a photo of the accident',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        state.imageUrl!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        children: [
                          // Retake button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              onPressed: () => _openCamera(context),
                              tooltip: 'Retake Photo',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Remove button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                context.read<AccidentReportBloc>().add(
                                  const ImageRemoved(),
                                );
                              },
                              tooltip: 'Remove Photo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Photo Added',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLocationSection() {
    return BlocBuilder<AccidentReportBloc, AccidentReportState>(
      buildWhen: (previous, current) =>
          previous.isLoadingLocation != current.isLoadingLocation ||
          previous.currentPosition != current.currentPosition ||
          previous.locationError != current.locationError,
      builder: (context, state) {
        final state = context.watch<AccidentReportBloc>().state;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (state.isLoadingLocation)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.red[700]),
                      const SizedBox(height: 12),
                      Text(
                        'Getting your location...',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.locationError != null)
                Column(
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(
                      state.locationError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AccidentReportBloc>().add(
                          const LocationRequested(),
                        );
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Retry', style: GoogleFonts.inter()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                )
              else if (state.currentPosition != null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Location captured successfully',
                              style: GoogleFonts.poppins(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationInfoRow(
                      icon: Icons.location_city,
                      label: 'Address',
                      value: state.currentAddress!,
                    ),
                    const SizedBox(height: 12),
                    _buildLocationInfoRow(
                      icon: Icons.my_location,
                      label: 'Latitude',
                      value: state.currentPosition!.latitude.toStringAsFixed(6),
                    ),
                    const SizedBox(height: 12),
                    _buildLocationInfoRow(
                      icon: Icons.location_on,
                      label: 'Longitude',
                      value: state.currentPosition!.longitude.toStringAsFixed(
                        6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLocationInfoRow(
                      icon: Icons.speed,
                      label: 'Accuracy',
                      value:
                          '${state.currentPosition!.accuracy.toStringAsFixed(1)}m',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AccidentReportBloc>().add(
                          LocationRequested(),
                        );
                      },
                      icon: Icon(Icons.refresh),
                      label: Text(
                        'Update Location',
                        style: GoogleFonts.inter(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 6,
        maxLength: 500,
        textInputAction: TextInputAction.done,
        onChanged: (value) {
          context.read<AccidentReportBloc>().add(DescriptionChanged(value));
        },
        onEditingComplete: () {
          FocusScope.of(context).unfocus();
        },
        decoration: InputDecoration(
          hintText:
              'Describe what happened...\n\nExample: Two-car collision at the intersection. No injuries reported.',
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          errorText: state.description.displayError != null
              ? 'Min 10 characters required'
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          counterStyle: GoogleFonts.inter(fontSize: 12),
        ),
        style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please describe what happened';
          }
          if (value.trim().length < 10) {
            return 'Description must be at least 10 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AccidentReportBloc, AccidentReportState>(
      builder: (context, state) {
        final isDisabled =
            state.isLoadingLocation || state.formStatus.isInProgress;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: isDisabled
                ? null
                : () {
                    final sessionState = context.read<SessionBloc>().state;
                    if (sessionState is! AuthAuthenticated) {
                      _showErrorSnackbar(
                        context,
                        'You must be logged in to report.',
                      );
                      return;
                    }

                    // Show validation errors
                    if (state.imageUrl == null) {
                      _showErrorSnackbar(
                        context,
                        'Please capture or select an image',
                      );
                      return;
                    }
                    if (state.currentPosition == null) {
                      _showErrorSnackbar(
                        context,
                        'Location is required. Please enable location services.',
                      );
                      return;
                    }
                    final currentUser = context.read<SessionBloc>().state;

                    if (currentUser is AuthAuthenticated) {
                      context.read<AccidentReportBloc>().add(
                        ReportSubmitted(
                          userId: currentUser.user.id,
                          reporterName: currentUser.user.fullName!,
                          email: currentUser.user.email,
                          phoneNumber: currentUser.user.phoneNumber,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: state.formStatus.isInProgress
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        state.isLoadingLocation
                            ? 'Getting Location...'
                            : 'Submit Report',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
