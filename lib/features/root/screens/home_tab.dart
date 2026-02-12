import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/core/widgets/add_phone_number_modal.dart';
import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_event.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/auth/bloc/signin_bloc.dart';
import 'package:eyesos/features/auth/bloc/signin_event.dart';
import 'package:eyesos/features/auth/bloc/signin_state.dart';
import 'package:eyesos/features/auth/models/user_model.dart';
import 'package:eyesos/features/auth/screens/sign_in_screen.dart';
import 'package:eyesos/features/auth/screens/sign_up_screen.dart';
import 'package:eyesos/features/auth/widgets/oauth_widget.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_report_load_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_state.dart';
import 'package:eyesos/features/root/screens/accident_report_screen.dart';
import 'package:eyesos/features/root/widgets/home/emergency_button.dart';
import 'package:eyesos/features/root/widgets/home/quick_stats_card.dart';
import 'package:eyesos/features/root/widgets/home/report_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final sessionState = context.read<SessionBloc>().state;
      if (sessionState is AuthAuthenticated) {
        final reportsState = context.read<AccidentsReportLoadBloc>().state;

        if (reportsState is RecentReportsLoaded &&
            !reportsState.isLoadingMore &&
            reportsState.hasMore) {
          context.read<AccidentsReportLoadBloc>().add(
            LoadMoreReports(userId: sessionState.userId),
          );
        }
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger when 200 pixels from bottom
    return currentScroll >= (maxScroll - 200);
  }

  Future<void> _onRefresh() async {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is AuthAuthenticated) {
      context.read<AccidentsReportLoadBloc>().add(
        RefreshReports(userId: sessionState.userId),
      );

      // Wait for the refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _showReportDetails({
    required BuildContext context,
    required dynamic report, // Replace with your actual report model type
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ReportDetailsModal(
          id: report.id,
          title: 'Road Accident',
          reportNumber: report.reportNumber,
          location: report.locationAddress,
          createdAt: report.createdAt,
          notes: report.reporterNotes,
          imageUrls: report.imageUrls,
          // Optional fields - add if available in your report model
          // severity: report.severity,
          // status: report.status,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, state) {
        final isAuthenticated = state is AuthAuthenticated;
        final userName = isAuthenticated && state.fullName != null
            ? state.fullName!
                  .split(' ')
                  .first // Get first name
            : 'Guest';

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: Colors.red[700],
          backgroundColor: Colors.white,
          displacement: 40,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics:
                const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even with little content
            child: Column(
              children: [
                // Hero Header Section with Gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red[700]!, Colors.red[900]!],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personalized Greeting
                          Text(
                            'Hello, $userName!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideX(),

                          const SizedBox(height: 4),

                          // App Name with Animation
                          Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye,
                                color: Colors.white,
                                size: 32,
                              ).animate().scale(delay: 300.ms),
                              const SizedBox(width: 8),
                              Text(
                                'EyeSOS',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ).animate().fadeIn(delay: 200.ms).slideX(),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Animated Description
                          DefaultTextStyle(
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  'Report emergencies instantly with real-time alerts',
                                  speed: const Duration(milliseconds: 50),
                                ),
                              ],
                              totalRepeatCount: 1,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quick Stats Row
                          Row(
                            children: [
                              QuickStatsCard(
                                icon: Icons.speed,
                                label: 'Fast Response',
                                color: Colors.white,
                              ).animate().fadeIn(delay: 400.ms).slideX(),

                              const SizedBox(width: 16),

                              QuickStatsCard(
                                icon: Icons.location_on,
                                label: 'Real-time Location',
                                color: Colors.white,
                              ).animate().fadeIn(delay: 500.ms).slideX(),

                              const SizedBox(width: 16),

                              QuickStatsCard(
                                icon: Icons.camera_alt,
                                label: 'Photo Evidence',
                                color: Colors.white,
                              ).animate().fadeIn(delay: 600.ms).slideX(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Guest User Notice (if not authenticated)
                if (!isAuthenticated)
                  Container(
                    width: double.infinity,
                    color: Colors.orange[50],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.orange[800],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You\'re exploring as a guest',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[900],
                                ),
                              ),
                              Text(
                                'Sign in to report emergencies',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showLoginPrompt(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(),

                // Emergency Buttons Section
                Container(
                  width: double.infinity,
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (!isAuthenticated)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 14,
                                      color: Colors.orange[800],
                                    ),
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
                        ),
                        const SizedBox(height: 20),

                        // Send Accident Report Button
                        BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
                          builder: (context, connectivityState) {
                            final isOffline =
                                connectivityState ==
                                ConnectivityStatus.disconnected;

                            return EmergencyButton(
                              context: context,
                              label: 'Send Accident Report',
                              subtitle: isAuthenticated
                                  ? (isOffline
                                        ? 'No internet connection'
                                        : 'Report traffic accidents with details')
                                  : 'Sign in to report emergencies',
                              icon: Icons.car_crash,
                              color: isOffline
                                  ? Colors.grey[500]!
                                  : Colors.orange[700]!,
                              isLocked: !isAuthenticated || isOffline,
                              onPressed: () {
                                if (isOffline) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.cloud_off,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Please connect to the internet to report emergencies',
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
                                } else if (isAuthenticated) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AccidentReportScreen(),
                                    ),
                                  );
                                } else {
                                  _showLoginPrompt(context);
                                }
                              },
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent Reports Card - Only show for authenticated users
                if (isAuthenticated)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Reports',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Pull down to refresh',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'View All Reports - Coming Soon',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: Colors.blue[700],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'View All',
                                    style: GoogleFonts.inter(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        BlocBuilder<
                          AccidentsReportLoadBloc,
                          AccidentsReportsLoadState
                        >(
                          builder: (context, state) {
                            // Loading State
                            if (state is RecentReportsLoadLoading ||
                                state is RecentReportLoadsInitial) {
                              return Skeletonizer(
                                enabled: true,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    return _buildReportItem(
                                      id: '',
                                      title: '',
                                      reportNumber: '',
                                      location: '',
                                      time: '',
                                      notes: '',
                                      imageUrl: '',
                                      imageCount: 1,
                                      onTap: () {},
                                      isLast: index == 2,
                                      isLoading: true,
                                    );
                                  },
                                ),
                              );
                            }

                            // Error State
                            if (state is RecentReportsError) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Failed to Load Reports',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    /* Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    ), */
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final sessionState = context
                                            .read<SessionBloc>()
                                            .state;

                                        String userId;
                                        if (sessionState is AuthAuthenticated) {
                                          userId = sessionState.userId;
                                          context
                                              .read<AccidentsReportLoadBloc>()
                                              .add(
                                                LoadRecentsReports(
                                                  userId: userId,
                                                ),
                                              );
                                        }
                                      },
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: Text(
                                        'Try Again',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Loaded State
                            if (state is RecentReportsLoaded) {
                              final reports = state.reports;
                              if (reports.isEmpty) {
                                return Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.inbox_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No Reports Yet',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Be the first to report an emergency\nin your community',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Pull down to refresh',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Reports List with Load More Indicator
                              return Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: reports.length,
                                    itemBuilder: (context, index) {
                                      final report = reports[index];
                                      return _buildReportItem(
                                        id: report.id,
                                        title: 'Road Accident',
                                        reportNumber: report.reportNumber,
                                        location: report.locationAddress,
                                        time: timeago.format(report.createdAt),
                                        notes: report.reporterNotes,
                                        imageUrl: report.imageUrls.isNotEmpty
                                            ? report.imageUrls[0]
                                            : null,
                                        imageCount: report.imageUrls.length,
                                        onTap: () {
                                          _showReportDetails(
                                            context: context,
                                            report: report,
                                          );
                                        },
                                        isLast: index == reports.length - 1,
                                        isLoading: false,
                                      );
                                    },
                                  ),

                                  // Loading More Indicator
                                  if (state.isLoadingMore)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.red[700]!,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Loading more reports...',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // End of List Indicator
                                  if (!state.hasMore && reports.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[300],
                                                  thickness: 1,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                child: Icon(
                                                  Icons.check_circle_outline,
                                                  size: 20,
                                                  color: Colors.green[600],
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.grey[300],
                                                  thickness: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'You\'re all caught up!',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pull down to refresh',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }

                            // Default/Unknown State
                            return Skeletonizer(
                              enabled: true,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  return _buildReportItem(
                                    id: '',
                                    title: '',
                                    reportNumber: '',
                                    location: '',
                                    time: '',
                                    notes: '',
                                    imageUrl: '',
                                    imageCount: 1,
                                    onTap: () {},
                                    isLast: index == 2,
                                    isLoading: true,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else
                  // Guest User - Show message to sign in
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
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
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_person_outlined,
                              size: 56,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Sign In to View Reports',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create an account or sign in to submit and view emergency reports in your area.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showLoginPrompt(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sign In Now',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportItem({
    required String id,
    required String title,
    required String reportNumber,
    required String location,
    required String time,
    required String? notes,
    required String? imageUrl,
    required int imageCount,
    required VoidCallback onTap,
    required bool isLast,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image (skeleton or actual)
                if (isLoading)
                  Bone.square(size: 80, borderRadius: BorderRadius.circular(8))
                else if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: _buildImageWithSkeleton(imageUrl, imageCount),
                  ),

                if (!isLoading && (imageUrl != null && imageUrl.isNotEmpty))
                  const SizedBox(width: 0)
                else if (isLoading)
                  const SizedBox(width: 14),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Severity Badge Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and ID
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isLoading)
                                    Bone(width: 100, height: 16)
                                  else
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                        height: 1.2,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (isLoading)
                                    Bone(width: 120, height: 12)
                                  else
                                    Text(
                                      'ID: $reportNumber',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        height: 1.33,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading)
                            Bone.square(size: 14)
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: isLoading
                                ? Bone(width: 150, height: 12)
                                : Text(
                                    location,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      height: 1.33,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),

                      // Notes (if available or loading)
                      if (isLoading || (notes != null && notes.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        if (isLoading)
                          Bone(width: 200, height: 14)
                        else
                          Text(
                            notes!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],

                      const SizedBox(height: 8),

                      // Time and "Tap to view" Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Time
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLoading)
                                  Bone.square(size: 13)
                                else
                                  Icon(
                                    Icons.access_time,
                                    size: 13,
                                    color: Colors.grey[400],
                                  ),
                                const SizedBox(width: 4),
                                if (isLoading)
                                  Bone(width: 50, height: 12)
                                else
                                  Text(
                                    time,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Tap to view
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading)
                                Bone(width: 50, height: 12)
                              else
                                Text(
                                  'Tap to view',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              const SizedBox(width: 4),
                              if (isLoading)
                                Bone.square(size: 14)
                              else
                                Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: Colors.grey[400],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithSkeleton(String imageUrl, int count) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildShimmerPlaceholder(),
            errorWidget: (context, url, error) => _buildErrorWidget(),
          ),
        ),
        if (count > 1) _buildCountOverlay(count),
      ],
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
    );
  }

  Widget _buildCountOverlay(int count) {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '+${count - 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocListener<SigninBloc, SigninState>(
        listener: (listenerContext, state) {
          final isSuccess =
              state.googleSignInStatus == GoogleSignInStatus.success;
          final isFailure =
              state.googleSignInStatus == GoogleSignInStatus.failure;

          if (isSuccess && state.user != null) {
            if (state.hasPhoneNumber) {
              Navigator.pop(modalContext);
              context.read<AccidentsReportLoadBloc>().add(
                RefreshReports(userId: state.user!.id),
              );
              context.read<SessionBloc>().add(AuthLoggedIn(state.user!));
            } else {
              Navigator.pop(modalContext);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                isDismissible: false,
                builder: (phoneModalContext) => AddPhoneNumberModal(
                  userId: state.user!.id,
                  onComplete: (UserModel user) {
                    Navigator.pop(phoneModalContext);
                    context.read<AccidentsReportLoadBloc>().add(
                      RefreshReports(userId: user.id),
                    );

                    context.read<SessionBloc>().add(AuthLoggedIn(user));
                  },
                ),
              );
            }
          }

          if (isFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
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
                  'Sign In Required',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Please sign in to report emergencies and access all features.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Benefits
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitRow(
                        Icons.report,
                        'Submit emergency reports',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitRow(Icons.history, 'Track report history'),
                      const SizedBox(height: 12),
                      _buildBenefitRow(
                        Icons.notifications_active,
                        'Get real-time alerts',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Google Sign In Button
                BlocBuilder<SigninBloc, SigninState>(
                  builder: (context, state) {
                    return GoogleSignInButton(
                      onPressed: () {
                        context.read<SigninBloc>().add(GoogleSigninRequested());
                      },
                      isLoading:
                          state.googleSignInStatus ==
                          GoogleSignInStatus.loading,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Divider with "OR"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 16),

                // Email Sign In Button
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
                      Navigator.pop(modalContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
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
                        Icon(Icons.email_outlined, size: 20),
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
                  onPressed: () {
                    Navigator.pop(modalContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
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
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
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
