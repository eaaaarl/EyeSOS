import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_event.dart';
import 'package:eyesos/features/auth/bloc/signin_bloc.dart';
import 'package:eyesos/features/auth/bloc/signin_event.dart';
import 'package:eyesos/features/auth/bloc/signin_state.dart';
import 'package:eyesos/features/auth/models/user_model.dart';
import 'package:eyesos/features/auth/screens/sign_up_screen.dart';
import 'package:eyesos/features/auth/validation/email.dart';
import 'package:eyesos/features/auth/validation/password.dart';
import 'package:eyesos/features/auth/widgets/oauth_widget.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_report_load_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/screens/root_screen.dart';
import 'package:eyesos/core/widgets/add_phone_number_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _getEmailErrorText(EmailValidationError? error) {
    switch (error) {
      case EmailValidationError.empty:
        return 'Email is required';
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

  // Google Sign In Handler
  Future<void> _handleGoogleSignIn() async {
    context.read<SigninBloc>().add(const GoogleSigninRequested());
  }

  void _navigateToHome(BuildContext context, UserModel user) {
    context.read<AccidentsReportLoadBloc>().add(
      RefreshReports(userId: user.id),
    );
    context.read<SessionBloc>().add(AuthLoggedIn(user));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RootScreen()),
      (route) => false,
    );
  }

  void _showPhoneModal(BuildContext context, SigninState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (modalContext) => AddPhoneNumberModal(
        userId: state.user!.id,
        onComplete: (UserModel user) {
          Navigator.pop(modalContext); // Close modal
          _navigateToHome(context, user); // Now refresh and go home
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<SigninBloc, SigninState>(
          listenWhen: (previous, current) {
            return previous.status != current.status ||
                previous.googleSignInStatus != current.googleSignInStatus;
          },
          listener: (context, state) {
            final isSuccess =
                state.status == SigninStatus.success ||
                state.googleSignInStatus == GoogleSignInStatus.success;

            final isFailure =
                state.status == SigninStatus.failure ||
                state.googleSignInStatus == GoogleSignInStatus.failure;

            if (isSuccess && state.user != null) {
              _emailController.clear();
              _passwordController.clear();
              if (state.hasPhoneNumber) {
                _navigateToHome(context, state.user!);
              } else {
                _showPhoneModal(context, state);
              }
            } else if (isFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage ?? 'Sign in failed',
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
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // App Logo/Icon with animation
                      Container(
                            padding: const EdgeInsets.all(24),
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
                            child: Icon(
                              Icons.remove_red_eye,
                              size: 70,
                              color: Colors.white,
                            ),
                          )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOut)
                          .shimmer(delay: 600.ms, duration: 1000.ms),

                      const SizedBox(height: 32),

                      // Header
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to report emergencies and stay connected',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(),

                      const SizedBox(height: 48),

                      // Email Field
                      BlocBuilder<SigninBloc, SigninState>(
                        buildWhen: (previous, current) =>
                            previous.email != current.email,
                        builder: (context, state) {
                          return TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: GoogleFonts.inter(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: GoogleFonts.inter(),
                              hintText: 'juan@example.com',
                              hintStyle: GoogleFonts.inter(
                                color: Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.red[700],
                              ),
                              errorText: state.email.displayError != null
                                  ? _getEmailErrorText(state.email.error)
                                  : null,
                              errorStyle: GoogleFonts.inter(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.red[700]!,
                                  width: 2,
                                ),
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
                              context.read<SigninBloc>().add(
                                SigninEmailChanged(value),
                              );
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 400.ms).slideX(),

                      const SizedBox(height: 20),

                      // Password Field
                      BlocBuilder<SigninBloc, SigninState>(
                        buildWhen: (previous, current) =>
                            previous.password != current.password,
                        builder: (context, state) {
                          return TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            style: GoogleFonts.inter(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: GoogleFonts.inter(),
                              hintText: 'Enter your password',
                              hintStyle: GoogleFonts.inter(
                                color: Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.red[700],
                              ),
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
                              errorStyle: GoogleFonts.inter(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.red[700]!,
                                  width: 2,
                                ),
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
                              context.read<SigninBloc>().add(
                                SigninPasswordChanged(value),
                              );
                            },
                            onFieldSubmitted: (value) {
                              if (context.read<SigninBloc>().state.isValid) {
                                context.read<SigninBloc>().add(
                                  SigninSubmitted(),
                                );
                              }
                            },
                          );
                        },
                      ).animate().fadeIn(delay: 500.ms).slideX(),

                      const SizedBox(height: 12),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Forgot password feature coming soon!',
                                  style: GoogleFonts.inter(),
                                ),
                                backgroundColor: Colors.blue[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 24),

                      // Sign In Button
                      BlocBuilder<SigninBloc, SigninState>(
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
                              onPressed: state.status == SigninStatus.loading
                                  ? null
                                  : state.isValid
                                  ? () {
                                      FocusScope.of(context).unfocus();
                                      context.read<SigninBloc>().add(
                                        SigninSubmitted(),
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
                              child: state.status == SigninStatus.loading
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
                                      'Sign In',
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

                      // OR Divider - NOW HERE, AFTER SIGN IN BUTTON
                      OAuthDivider().animate().fadeIn(delay: 750.ms),

                      const SizedBox(height: 24),

                      // Google Sign In Button - BELOW THE DIVIDER
                      BlocBuilder<SigninBloc, SigninState>(
                        builder: (context, state) {
                          return GoogleSignInButton(
                            onPressed: _handleGoogleSignIn,
                            isLoading:
                                state.googleSignInStatus ==
                                GoogleSignInStatus.loading,
                          );
                        },
                      ).animate().fadeIn(delay: 800.ms).slideX(),

                      const Spacer(),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 900.ms),

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
}
