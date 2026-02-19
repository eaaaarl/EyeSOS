import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/profile/presentation/widgets/help_dialog.dart';
import 'package:eyesos/features/profile/presentation/widgets/login_prompt_sheet.dart';
import 'package:eyesos/features/profile/presentation/widgets/logout_dialog.dart';
import 'package:eyesos/features/profile/presentation/widgets/personal_information_sheet.dart';
import 'package:eyesos/features/profile/presentation/widgets/profile_avatar_widgets.dart';
import 'package:eyesos/features/profile/presentation/widgets/profile_menu_card.dart';
import 'package:eyesos/features/profile/presentation/widgets/show_about_dialog_widget.dart';
import 'package:eyesos/features/profile/presentation/widgets/sign_up_prompt_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final isAuthenticated = state is AuthAuthenticated;
        return SingleChildScrollView(
          child: Column(
            children: [
              // Header Section with Gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.red[700]!, Colors.red[500]!],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        BlocSelector<SessionBloc, SessionState, String?>(
                          selector: (state) {
                            if (state is AuthAuthenticated) {
                              return state.user.avatarUrl;
                            }
                            return null;
                          },
                          builder: (context, avatarUrl) {
                            final hasImage =
                                avatarUrl != null && avatarUrl.isNotEmpty;
                            if (!hasImage) {
                              return const ProfilePlaceholder();
                            }

                            return Container(
                              width: 120,
                              height: 120,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      const ProfileShimmer(),
                                  errorWidget: (context, url, error) =>
                                      const ProfilePlaceholder(),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Full Name
                        BlocSelector<SessionBloc, SessionState, String>(
                          selector: (state) {
                            if (state is AuthAuthenticated) {
                              return state.fullName ?? 'Guest User';
                            }
                            return 'Guest User';
                          },
                          builder: (context, fullName) {
                            return Text(
                              fullName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY();
                          },
                        ),

                        const SizedBox(height: 8),

                        // Email or Guest Badge
                        if (isAuthenticated)
                          BlocSelector<SessionBloc, SessionState, String>(
                            selector: (state) {
                              if (state is AuthAuthenticated) {
                                return state.email;
                              }
                              return '';
                            },
                            builder: (context, email) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      email,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideY();
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Exploring EyeSOS',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(),

                        const SizedBox(height: 12),

                        if (isAuthenticated)
                          BlocSelector<SessionBloc, SessionState, String>(
                            selector: (state) {
                              if (state is AuthAuthenticated) {
                                return state.phoneNumber ?? '';
                              }
                              return '';
                            },
                            builder: (context, phoneNumber) {
                              if (phoneNumber.isEmpty) return const SizedBox();

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      phoneNumber,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 400.ms).slideY();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Menu Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sign In/Sign Up Banner for Guest Users
                    if (!isAuthenticated) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red[700]!, Colors.red[500]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_person_outlined,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sign in for full access',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create an account to save reports, track history, and get personalized alerts',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (modalContext) =>
                                            LoginPromptSheet(
                                              parentContext: context,
                                            ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red[700],
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Sign In',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) =>
                                            const SignUpPromptSheet(),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Account',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Personal Information Card
                    ProfileMenuCard(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'View and edit your details',
                      color: Colors.blue,
                      requiresAuth: true,
                      onTap: () {
                        if (isAuthenticated) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const PersonalInformationSheet(),
                          );
                        } else {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (modalContext) =>
                                LoginPromptSheet(parentContext: context),
                          );
                        }
                      },
                    ).animate().fadeIn(delay: 200.ms).slideX(),

                    const SizedBox(height: 12),

                    // Report History Card
                    ProfileMenuCard(
                      icon: Icons.history,
                      title: 'Report History',
                      subtitle: 'View your past emergency reports',
                      color: Colors.orange,
                      requiresAuth: true,
                      onTap: () {
                        if (isAuthenticated) {
                          _showComingSoonSnackbar(context, 'Report History');
                        } else {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (modalContext) =>
                                LoginPromptSheet(parentContext: context),
                          );
                        }
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(),

                    const SizedBox(height: 24),

                    Text(
                      'Support',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Help & Support Card (available for all)
                    ProfileMenuCard(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get assistance and FAQs',
                      color: Colors.green,
                      requiresAuth: false,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const HelpDialog(),
                        );
                      },
                    ).animate().fadeIn(delay: 400.ms).slideX(),

                    const SizedBox(height: 12),

                    // About Card (available for all)
                    ProfileMenuCard(
                      icon: Icons.info_outline,
                      title: 'About EyeSOS',
                      subtitle: 'Learn more about the app',
                      color: Colors.purple,
                      requiresAuth: false,
                      onTap: () {
                        AboutDialogWidget.show(context);
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(),

                    const SizedBox(height: 32),

                    // Logout Button (only for authenticated users)
                    if (isAuthenticated)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const LogoutDialog(),
                            );
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
                              Icon(Icons.logout, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(),

                    const SizedBox(height: 20),

                    // App Version
                    Center(
                      child: Text(
                        'EyeSOS ${dotenv.env['APP_VERSION']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showComingSoonSnackbar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$feature coming soon!', style: GoogleFonts.inter()),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
