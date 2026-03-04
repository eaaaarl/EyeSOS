import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eyesos/features/auth/domain/entities/user_entity.dart';
import 'package:eyesos/features/home/bloc/accidents_report_load_bloc.dart';
import 'package:eyesos/features/home/bloc/accidents_reports_load_event.dart';
import 'package:eyesos/core/presentation/widgets/add_phone_number_modal.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user_model.dart';
import '../../bloc/session_bloc.dart';
import '../../bloc/session_event.dart';
import '../../bloc/session_state.dart';
import '../../bloc/signin_bloc.dart';
import '../../bloc/signin_event.dart';
import '../../bloc/signin_state.dart';
import '../validation/email.dart';
import '../validation/password.dart';
import '../widgets/oauth_widget.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
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

  Future<void> _handleGoogleSignIn() async {
    context.read<SigninBloc>().add(const GoogleSigninRequested());
  }

  void _navigateToHome(BuildContext context, UserModel user) {
    context.read<AccidentsReportLoadBloc>().add(
      RefreshReports(userId: user.id),
    );
    context.read<SessionBloc>().add(AuthLoggedIn(user));
  }

  void _showPhoneModal(BuildContext context, SigninState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (modalContext) => AddPhoneNumberModal(
        userId: state.user!.id,
        onComplete: (UserEntity user) {
          context.pop();
          _navigateToHome(context, user as UserModel);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<SessionBloc, SessionState>(
          listenWhen: (previous, current) {
            return previous.runtimeType != current.runtimeType ||
                (current is AuthAuthenticated &&
                    previous is! AuthAuthenticated);
          },
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/maps');
            }
          },
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
                  _navigateToHome(context, state.user as UserModel);
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
                              child: const Icon(
                                Icons.remove_red_eye,
                                size: 70,
                                color: Colors.white,
                              ),
                            )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOut)
                            .shimmer(delay: 600.ms, duration: 1000.ms),
                        const SizedBox(height: 32),
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
                                prefixIcon: const Icon(Icons.email_outlined),
                                errorText: state.email.displayError != null
                                    ? _getEmailErrorText(state.email.error)
                                    : null,
                              ),
                              onChanged: (value) => context
                                  .read<SigninBloc>()
                                  .add(SigninEmailChanged(value)),
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
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _isPasswordVisible =
                                        !_isPasswordVisible,
                                  ),
                                ),
                                errorText: state.password.displayError != null
                                    ? _getPasswordErrorText(
                                        state.password.error,
                                      )
                                    : null,
                              ),
                              onChanged: (value) => context
                                  .read<SigninBloc>()
                                  .add(SigninPasswordChanged(value)),
                            );
                          },
                        ).animate().fadeIn(delay: 500.ms).slideX(),

                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {}, // Forgot password logic
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 24),

                        // Submit Button
                        BlocBuilder<SigninBloc, SigninState>(
                          builder: (context, state) {
                            return SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    state.isValid &&
                                        state.status != SigninStatus.loading
                                    ? () => context.read<SigninBloc>().add(
                                        SigninSubmitted(),
                                      )
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: state.isValid
                                      ? null // Use theme color
                                      : Colors.grey[300],
                                ),
                                child: state.status == SigninStatus.loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            );
                          },
                        ).animate().fadeIn(delay: 700.ms).slideY(),

                        const SizedBox(height: 24),
                        const OAuthDivider().animate().fadeIn(delay: 750.ms),
                        const SizedBox(height: 24),

                        // Google Sign In
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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () => context.push('/signup'),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
