import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/core/bloc/connectivity_state.dart';
import 'package:eyesos/features/home/presentation/widgets/emergency_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyButtonSection extends StatelessWidget {
  final bool isAuthenticated;
  final VoidCallback onPressSignIn;

  const EmergencyButtonSection({
    super.key,
    required this.isAuthenticated,
    required this.onPressSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSendAccidentReportButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Actions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Report emergencies to MDRRMC',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        if (!isAuthenticated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.orange[800]),
                const SizedBox(width: 4),
                Text(
                  'Login Required',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSendAccidentReportButton(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
      builder: (context, connectivityState) {
        final isOffline = connectivityState == ConnectivityStatus.disconnected;

        // More descriptive subtitle logic
        String subtitle;
        if (!isAuthenticated) {
          subtitle = 'Sign in to report emergencies';
        } else if (isOffline) {
          subtitle = 'No internet connection';
        } else {
          subtitle = 'Report traffic accidents with details';
        }

        return EmergencyButton(
          context: context,
          label: 'Send Accident Report',
          subtitle: subtitle,
          icon: isOffline ? Icons.cloud_off : Icons.car_crash,
          // Subtle visual feedback — not fully grey, just slightly muted
          color: isOffline
              ? Colors.orange[700]!.withValues(alpha: 0.5)
              : Colors.orange[700]!,
          isLocked: !isAuthenticated,
          // Keep button always tappable — handle logic inside
          onPressed: () => _handleSendAccidentReport(context, isOffline),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
      },
    );
  }

  void _handleSendAccidentReport(BuildContext context, bool isOffline) {
    if (!isAuthenticated) {
      onPressSignIn();
      return;
    }

    if (isOffline) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No internet. Please reconnect to report emergencies.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      return;
    }

    context.push('/accident-report');
  }
}
