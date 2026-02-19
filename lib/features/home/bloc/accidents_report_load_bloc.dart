import 'package:eyesos/features/home/bloc/accidents_reports_load_event.dart';
import 'package:eyesos/features/home/bloc/accidents_reports_load_state.dart';
import 'package:eyesos/features/home/domain/usecases/load_recent_reports_usecase.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccidentsReportLoadBloc
    extends Bloc<AccidentsReportsLoadEvent, AccidentsReportsLoadState> {
  final LoadRecentReportsUsecase _loadRecentReportsUsecase;

  static const int _pageSize = 5;
  AccidentsReportLoadBloc({
    required LoadRecentReportsUsecase loadRecentReportsUsecase,
  }) : _loadRecentReportsUsecase = loadRecentReportsUsecase,
       super(RecentReportLoadsInitial()) {
    on<LoadRecentReports>((event, emit) async {
      emit(RecentReportsLoadLoading());
      try {
        final response = await _loadRecentReportsUsecase(
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

        final newReports = await _loadRecentReportsUsecase(
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
        final response = await _loadRecentReportsUsecase(
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
