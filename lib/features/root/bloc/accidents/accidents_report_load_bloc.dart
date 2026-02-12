import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_event.dart';
import 'package:eyesos/features/root/bloc/accidents/accidents_reports_load_state.dart';
import 'package:eyesos/features/root/models/accidents_reports_model.dart';
import 'package:eyesos/features/root/repository/accident_report_repository.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccidentsReportLoadBloc
    extends Bloc<AccidentsReportsLoadEvent, AccidentsReportsLoadState> {
  final AccidentReportRepository _accidentReportRepository;

  static const int _pageSize = 5; // Number of items per page

  AccidentsReportLoadBloc(this._accidentReportRepository)
    : super(RecentReportLoadsInitial()) {
    on<LoadRecentsReports>((event, emit) async {
      emit(RecentReportsLoadLoading());
      try {
        final List<AccidentReport> response = await _accidentReportRepository
            .getRecentsReports(
              userId: event.userId,
              page: 1,
              pageSize: _pageSize,
            );

        final hasMore = response.length >= _pageSize;

        emit(
          RecentReportsLoaded(
            reports: response,
            hasMore: hasMore,
            currentPage: 1,
          ),
        );
      } on PostgrestException catch (e) {
        emit(RecentReportsError('Database error: ${e.message}'));
      } catch (e) {
        emit(RecentReportsError('Failed to load reports: $e'));
      }
    });

    on<LoadMoreReports>((event, emit) async {
      final currentState = state;
      if (currentState is! RecentReportsLoaded) return;
      if (currentState.isLoadingMore) return;
      if (!currentState.hasMore) return;
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final nextPage = currentState.currentPage + 1;

        final List<AccidentReport> newReports = await _accidentReportRepository
            .getRecentsReports(
              userId: event.userId,
              page: nextPage,
              pageSize: _pageSize,
            );
        final hasMore = newReports.length >= _pageSize;
        final allReports = [...currentState.reports, ...newReports];

        emit(
          RecentReportsLoaded(
            reports: allReports,
            hasMore: hasMore,
            currentPage: nextPage,
            isLoadingMore: false,
          ),
        );
      } on PostgrestException catch (_) {
        emit(currentState.copyWith(isLoadingMore: false));
      } catch (_) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    });
    on<RefreshReports>((event, emit) async {
      final currentState = state;
      if (currentState is RecentReportsLoaded) {
        emit(currentState.copyWith(isLoadingMore: true));
      } else {
        emit(RecentReportsLoadLoading());
      }

      try {
        final List<AccidentReport> response = await _accidentReportRepository
            .getRecentsReports(
              userId: event.userId,
              page: 1,
              pageSize: _pageSize,
            );

        final hasMore = response.length >= _pageSize;

        emit(
          RecentReportsLoaded(
            reports: response,
            hasMore: hasMore,
            currentPage: 1,
          ),
        );
      } on PostgrestException catch (e) {
        emit(RecentReportsError('Database error: ${e.message}'));
      } catch (e) {
        emit(RecentReportsError('Failed to refresh reports: $e'));
      }
    });

    on<ResetReports>((event, emit) async {
      emit(RecentReportLoadsInitial());
    });
  }
}
