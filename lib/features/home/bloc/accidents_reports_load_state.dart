import 'package:equatable/equatable.dart';
import 'package:eyesos/features/home/domain/entities/accident_report_entity.dart';

abstract class AccidentsReportsLoadState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RecentReportLoadsInitial extends AccidentsReportsLoadState {
  RecentReportLoadsInitial();

  @override
  List<Object> get props => [];
}

class RecentReportsLoadLoading extends AccidentsReportsLoadState {}

class RecentReportsLoaded extends AccidentsReportsLoadState {
  final List<AccidentReportEntity> reports;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  RecentReportsLoaded({
    required this.reports,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  RecentReportsLoaded copyWith({
    List<AccidentReportEntity>? reports,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return RecentReportsLoaded(
      reports: reports ?? this.reports,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [reports, isLoadingMore, hasMore, currentPage];
}

class RecentReportsError extends AccidentsReportsLoadState {
  final String message;
  RecentReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
