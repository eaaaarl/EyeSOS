import 'package:eyesos/features/auth/models/user_model.dart';
import 'package:eyesos/features/auth/repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddPhoneNumberModal extends StatefulWidget {
  final String userId;
  final Function(UserModel user) onComplete;

  const AddPhoneNumberModal({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  @override
  State<AddPhoneNumberModal> createState() => _AddPhoneNumberModalState();
}

class _AddPhoneNumberModalState extends State<AddPhoneNumberModal> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhoneNumber(String phone) {
    // Philippine phone number validation (11 digits, starts with 09)
    final phoneRegex = RegExp(r'^09\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _savePhoneNumber() async {
    final phone = _phoneController.text.trim();

    // Validate
    if (phone.isEmpty) {
      setState(
        () => _errorText = 'Phone number is required for emergency contact',
      );
      return;
    }

    if (!_isValidPhoneNumber(phone)) {
      setState(() => _errorText = 'Please enter a valid 11-digit phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.updatePhoneNumber(widget.userId, phone);
      final updatedUser = await authRepo.getCurrentUser(widget.userId);
      if (mounted) {
        widget.onComplete(updatedUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Failed to save phone number. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[700]!, Colors.red[900]!],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 400.ms),

              const SizedBox(height: 20),

              // Title
              Text(
                'Add Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(),

              const SizedBox(height: 12),

              // Description
              Text(
                'Your phone number is required for emergency contact and account verification.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(),

              const SizedBox(height: 32),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  labelStyle: GoogleFonts.inter(),
                  hintText: '09171234567',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  helperText: 'Used for emergency contact',
                  helperStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: Colors.red[700],
                  ),
                  errorText: _errorText,
                  errorStyle: GoogleFonts.inter(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.red[700]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                onChanged: (value) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                onFieldSubmitted: (value) {
                  if (!_isLoading) _savePhoneNumber();
                },
              ).animate().fadeIn(delay: 300.ms).slideX(),

              const SizedBox(height: 24),

              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This number will be used to contact you during emergencies',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(),

              const SizedBox(height: 24),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.red[700]!, Colors.red[900]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
