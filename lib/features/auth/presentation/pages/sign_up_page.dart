import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_report_load_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/screens/root_screen.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/signup_bloc.dart';
import '../bloc/signup_event.dart';
import '../bloc/signup_state.dart';
import '../validation/confirm_password.dart';
import '../validation/email.dart';
import '../validation/name.dart';
import '../validation/password.dart';
import '../validation/phone_number.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  String? _getNameErrorText(NameValidationError? error) {
    switch (error) {
      case NameValidationError.empty:
        return 'Name is required for emergency identification';
      case NameValidationError.tooShort:
        return 'Please enter your full name';
      case null:
        return null;
    }
  }

  String? _getEmailErrorText(EmailValidationError? error) {
    switch (error) {
      case EmailValidationError.empty:
        return 'Email is required for account verification';
      case EmailValidationError.invalid:
        return 'Please enter a valid email address';
      case null:
        return null;
    }
  }

  String? _getPasswordErrorText(PasswordValidationError? error) {
    switch (error) {
      case PasswordValidationError.empty:
        return 'Password is required';
      case PasswordValidationError.tooShort:
        return 'Password must be at least 6 characters';
      case null:
        return null;
    }
  }

  String? _getConfirmedPasswordErrorText(
    ConfirmedPasswordValidationError? error,
  ) {
    switch (error) {
      case ConfirmedPasswordValidationError.empty:
        return 'Please confirm your password';
      case ConfirmedPasswordValidationError.mismatch:
        return 'Passwords do not match';
      case null:
        return null;
    }
  }

  String? _getPhoneNumberErrorText(PhoneNumberValidationError? error) {
    switch (error) {
      case PhoneNumberValidationError.empty:
        return 'Phone number is required for emergency contact';
      case PhoneNumberValidationError.invalid:
        return 'Please enter a valid 11-digit phone number';
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocListener<SignupBloc, SignupState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == SignupStatus.success) {
              _nameController.clear();
              _emailController.clear();
              _passwordController.clear();
              _confirmPasswordController.clear();
              _phoneNumberController.clear();

              context.read<AccidentsReportLoadBloc>().add(
                RefreshReports(userId: state.user!.id),
              );

              context.read<SessionBloc>().add(AuthLoggedIn(state.user!));

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RootScreen()),
                (route) => false,
              );
            } else if (state.status == SignupStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage ?? 'Registration failed',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.red[700]!, Colors.red[900]!],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.remove_red_eye,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOut)
                          .shimmer(delay: 600.ms, duration: 1000.ms),
                      const SizedBox(height: 32),
                      Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(),
                      const SizedBox(height: 8),
                      Text(
                        'Join EyeSOS to report emergencies and help your community stay safe',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(),
                      const SizedBox(height: 32),
                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (previous, current) =>
                            previous.name != current.name,
                        builder: (context, state) {
                          return _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Juan Dela Cruz',
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            errorText: state.name.displayError != null
                                ? _getNameErrorText(state.name.error)
                                : null,
                            onChanged: (value) {
                              context.read<SignupBloc>().add(
                                SignupNameChanged(value),
                              );
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 400.ms).slideX(),
                      const SizedBox(height: 16),
                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (previous, current) =>
                            previous.email != current.email,
                        builder: (context, state) {
                          return _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'juan@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            errorText: state.email.displayError != null
                                ? _getEmailErrorText(state.email.error)
                                : null,
                            onChanged: (value) {
                              context.read<SignupBloc>().add(
                                SignupEmailChanged(value),
                              );
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 450.ms).slideX(),
                      const SizedBox(height: 16),
                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (previous, current) =>
                            previous.phoneNumber != current.phoneNumber,
                        builder: (context, state) {
                          return _buildTextField(
                            controller: _phoneNumberController,
                            label: 'Mobile Number',
                            hint: '09171234567',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            helperText: 'Used for emergency contact',
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            errorText: state.phoneNumber.displayError != null
                                ? _getPhoneNumberErrorText(
                                    state.phoneNumber.error,
                                  )
                                : null,
                            onChanged: (value) {
                              context.read<SignupBloc>().add(
                                SignupPhoneNumberChanged(value),
                              );
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 500.ms).slideX(),
                      const SizedBox(height: 16),
                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (previous, current) =>
                            previous.password != current.password,
                        builder: (context, state) {
                          return _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'At least 6 characters',
                            icon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.next,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            errorText: state.password.displayError != null
                                ? _getPasswordErrorText(state.password.error)
                                : null,
                            onChanged: (value) {
                              context.read<SignupBloc>().add(
                                SignupPasswordChanged(value),
                              );
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 550.ms).slideX(),
                      const SizedBox(height: 16),
                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (previous, current) =>
                            previous.confirmedPassword !=
                            current.confirmedPassword,
                        builder: (context, state) {
                          return _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            icon: Icons.lock_outline,
                            obscureText: !_isConfirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            errorText:
                                state.confirmedPassword.displayError != null
                                ? _getConfirmedPasswordErrorText(
                                    state.confirmedPassword.error,
                                  )
                                : null,
                            onChanged: (value) {
                              context.read<SignupBloc>().add(
                                SignupConfirmPasswordChanged(value),
                              );
                            },
                            onFieldSubmitted: (value) {
                              if (context.read<SignupBloc>().state.isValid) {
                                context.read<SignupBloc>().add(
                                  SignupSubmitted(),
                                );
                              }
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 600.ms).slideX(),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[50]!,
                              Colors.blue[100]!.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your information will be used to verify your identity during emergency reports',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 650.ms).slideY(),
                      const SizedBox(height: 32),
                      BlocBuilder<SignupBloc, SignupState>(
                        buildWhen: (previous, current) =>
                            previous.status != current.status ||
                            previous.isValid != current.isValid,
                        builder: (context, state) {
                          return Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: state.isValid
                                  ? LinearGradient(
                                      colors: [
                                        Colors.red[700]!,
                                        Colors.red[900]!,
                                      ],
                                    )
                                  : null,
                              boxShadow: state.isValid
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton(
                              onPressed: state.status == SignupStatus.loading
                                  ? null
                                  : state.isValid
                                  ? () {
                                      FocusScope.of(context).unfocus();
                                      context.read<SignupBloc>().add(
                                        SignupSubmitted(),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.isValid
                                    ? Colors.transparent
                                    : Colors.grey[300],
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: state.status == SignupStatus.loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 700.ms).slideY(),
                      const SizedBox(height: 24),
                      Text(
                        'By creating an account, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 750.ms),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    String? helperText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    required Function(String) onChanged,
    Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
        helperText: helperText,
        helperStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.red[700]),
        suffixIcon: suffixIcon,
        errorText: errorText,
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
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
