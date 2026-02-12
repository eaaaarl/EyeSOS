import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_report_load_bloc.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_state.dart';
import 'package:eyesos/features/root/widgets/home/emergency_button_section.dart';
import 'package:eyesos/features/root/widgets/home/guest_notice_banner.dart';
import 'package:eyesos/features/root/widgets/home/guest_signin_card.dart';
import 'package:eyesos/features/root/widgets/home/home_hero_header.dart';
import 'package:eyesos/features/root/widgets/home/login_prompt_modal.dart';
import 'package:eyesos/features/root/widgets/home/recent_reports_section.dart';
import 'package:eyesos/features/root/widgets/home/report_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return currentScroll >= (maxScroll - 200);
  }

  Future<void> _onRefresh() async {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is AuthAuthenticated) {
      context.read<AccidentsReportLoadBloc>().add(
        RefreshReports(userId: sessionState.userId),
      );

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _showReportDetails({
    required BuildContext context,
    required dynamic report,
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
        ),
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LoginPromptModal(),
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
                HomeHeroHeader(userName: userName),

                // Guest User Notice (if not authenticated)
                if (!isAuthenticated)
                  GuestNoticeBanner(
                    onPressSignIn: () => _showLoginPrompt(context),
                  ),

                // Emergency Buttons Section
                EmergencyButtonSection(
                  isAuthenticated: isAuthenticated,
                  onPressSignIn: () => _showLoginPrompt(context),
                ),

                // Recent Reports Card - Only show for authenticated users
                if (isAuthenticated)
                  RecentReportsSection(
                    onReportTap: (report) {
                      _showReportDetails(context: context, report: report);
                    },
                  )
                else
                  // Guest User - Show message to sign in
                  GuestSigninCard(
                    onPressSignIn: () => _showLoginPrompt(context),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
