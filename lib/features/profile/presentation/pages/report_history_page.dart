import 'package:eyesos/features/auth/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/bloc/session_state.dart';
import 'package:eyesos/features/home/bloc/accidents_report_load_bloc.dart';
import 'package:eyesos/features/home/bloc/accidents_reports_load_event.dart';
import 'package:eyesos/features/home/bloc/accidents_reports_load_state.dart';
import 'package:eyesos/features/home/domain/entities/accident_report_entity.dart';
import 'package:eyesos/features/home/presentation/widgets/report_details_modal.dart';
import 'package:eyesos/features/home/presentation/widgets/report_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReportHistoryPage extends StatefulWidget {
  const ReportHistoryPage({super.key});

  @override
  State<ReportHistoryPage> createState() => _ReportHistoryPageState();
}

class _ReportHistoryPageState extends State<ReportHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial load if not already loaded or empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionState = context.read<SessionBloc>().state;
      if (sessionState is AuthAuthenticated) {
        context.read<AccidentsReportLoadBloc>().add(
          LoadRecentReports(userId: sessionState.userId),
        );
      }
    });
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
    }
  }

  void _showReportDetails(AccidentReportEntity report) {
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
          notes: report.reporterNotes ?? '',
          imageUrls: report.imageUrls,
          severity: report.severity,
          accidentStatus: report.accidentStatus,
          updatedAt: report.updatedAt,
          latitude: report.latitude,
          longitude: report.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Report History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.grey[800],
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<AccidentsReportLoadBloc, AccidentsReportsLoadState>(
        builder: (context, state) {
          if (state is RecentReportsLoadLoading ||
              state is RecentReportLoadsInitial) {
            return _buildLoadingState();
          }

          if (state is RecentReportsError) {
            return _buildErrorState(state.message);
          }

          if (state is RecentReportsLoaded) {
            final reports = state.reports;
            if (reports.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: Colors.red[700],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: reports.length + (state.isLoadingMore ? 1 : 1),
                itemBuilder: (context, index) {
                  if (index < reports.length) {
                    final report = reports[index];
                    return ReportItemCard(
                          id: report.id,
                          title: 'Road Accident',
                          reportNumber: report.reportNumber,
                          location: report.locationAddress,
                          time: timeago.format(report.createdAt),
                          notes: report.reporterNotes,
                          imageUrl: report.imageUrls.isNotEmpty
                              ? report.imageUrls[0]
                              : '',
                          imageCount: report.imageUrls.length,
                          severity: report.severity,
                          accidentStatus: report.accidentStatus,
                          updatedAt: report.updatedAt,
                          onTap: () => _showReportDetails(report),
                          isLast: index == reports.length - 1 && !state.hasMore,
                          isLoading: false,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                        .slideY(begin: 0.1, end: 0);
                  } else {
                    if (state.isLoadingMore) {
                      return _buildLoadingMoreIndicator();
                    } else if (!state.hasMore && reports.isNotEmpty) {
                      return _buildEndOfListIndicator();
                    } else {
                      return const SizedBox(height: 40);
                    }
                  }
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        itemBuilder: (context, index) {
          return ReportItemCard(
            id: '',
            title: 'Loading Report Title',
            reportNumber: 'XYZ-123-456',
            location: 'Loading location address here...',
            time: '2 hours ago',
            imageUrl: '',
            imageCount: 0,
            onTap: () {},
            isLast: index == 5,
            isLoading: true,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(Icons.history, size: 64, color: Colors.grey[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'No Report History',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You haven't submitted any emergency reports yet. Your report history will appear here once you make a report.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ).animate().fadeIn().scale(delay: 100.ms),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red[700]!),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading more reports...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndOfListIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: Colors.green[400],
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "You've reached the end of your history",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
