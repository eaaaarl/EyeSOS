import 'package:eyesos/core/presentation/widgets/add_phone_number_modal.dart';
import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_event.dart';
import 'package:eyesos/features/auth/bloc/signin_bloc.dart';
import 'package:eyesos/features/auth/bloc/signin_event.dart';
import 'package:eyesos/features/auth/bloc/signin_state.dart';
import 'package:eyesos/features/auth/domain/entities/user_entity.dart';
import 'package:eyesos/features/auth/presentation/widgets/oauth_widget.dart';
import 'package:eyesos/features/home/bloc/accidents_report_load_bloc.dart';
import 'package:eyesos/features/home/bloc/accidents_reports_load_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class LoginBenefit {
  final IconData icon;
  final String text;

  const LoginBenefit({required this.icon, required this.text});
}

class LoginPromptSheet extends StatelessWidget {
  const LoginPromptSheet({
    super.key,
    required this.parentContext,
    this.title = 'Sign In Required',
    this.description =
        'Please sign in to access this feature and enjoy the full EyeSOS experience.',
    this.benefits = const [
      LoginBenefit(icon: Icons.history, text: 'Track report history'),
      LoginBenefit(icon: Icons.person, text: 'Save your profile'),
      LoginBenefit(
        icon: Icons.notifications_active,
        text: 'Get emergency alerts',
      ),
    ],
    this.onSignUpPressed,
  });

  final BuildContext parentContext;
  final String title;
  final String description;
  final List<LoginBenefit> benefits;
  final VoidCallback? onSignUpPressed;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SigninBloc, SigninState>(
      listener: (listenerContext, state) {
        final isSuccess =
            state.googleSignInStatus == GoogleSignInStatus.success;
        final isFailure =
            state.googleSignInStatus == GoogleSignInStatus.failure;

        if (isSuccess && state.user != null) {
          if (state.hasPhoneNumber) {
            context.pop();
            parentContext.read<AccidentsReportLoadBloc>().add(
              RefreshReports(userId: state.user!.id),
            );
            parentContext.read<SessionBloc>().add(AuthLoggedIn(state.user!));
          } else {
            context.pop();
            showModalBottomSheet(
              context: parentContext,
              isScrollControlled: true,
              isDismissible: false,
              builder: (modalContext) => AddPhoneNumberModal(
                userId: state.user!.id,
                onComplete: (UserEntity user) {
                  context.pop();
                  parentContext.read<AccidentsReportLoadBloc>().add(
                    RefreshReports(userId: user.id),
                  );
                  parentContext.read<SessionBloc>().add(AuthLoggedIn(user));
                },
              ),
            );
          }
        }

        if (isFailure) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errorMessage ?? 'Google sign in failed',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(parentContext).viewInsets.bottom,
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
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person,
                  size: 48,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Benefits
              if (benefits.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: benefits.asMap().entries.map((entry) {
                      final index = entry.key;
                      final benefit = entry.value;
                      final isLast = index == benefits.length - 1;
                      return Column(
                        children: [
                          _BenefitRow(icon: benefit.icon, text: benefit.text),
                          if (!isLast) const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),

              BlocBuilder<SigninBloc, SigninState>(
                builder: (context, state) {
                  return GoogleSignInButton(
                    onPressed: () {
                      context.read<SigninBloc>().add(GoogleSigninRequested());
                    },
                    isLoading:
                        state.googleSignInStatus == GoogleSignInStatus.loading,
                  );
                },
              ),
              const SizedBox(height: 16),
              const OAuthDivider(),
              const SizedBox(height: 16),

              // Sign In Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.push('/signin');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Sign In with Email',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Create Account Link
              TextButton(
                onPressed:
                    onSignUpPressed ??
                    () {
                      context.pop();
                      context.push('/signup');
                    },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Sign Up',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.red[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
      ],
    );
  }
}
