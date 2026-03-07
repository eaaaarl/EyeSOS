import 'package:equatable/equatable.dart';
import 'package:eyesos/core/domain/entities/accident_entity.dart';

abstract class AccidentsReportsLoadState extends Equatable {
  const AccidentsReportsLoadState();

  @override
  List<Object?> get props => [];
}

class RecentReportLoadsInitial extends AccidentsReportsLoadState {}

class RecentReportsLoadLoading extends AccidentsReportsLoadState {}

class RecentReportsLoaded extends AccidentsReportsLoadState {
  final List<AccidentEntity> reports;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;

  const RecentReportsLoaded({
    required this.reports,
    required this.hasMore,
    this.isLoadingMore = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [reports, hasMore, isLoadingMore, currentPage];

  RecentReportsLoaded copyWith({
    List<AccidentEntity>? reports,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
  }) {
    return RecentReportsLoaded(
      reports: reports ?? this.reports,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class RecentReportsError extends AccidentsReportsLoadState {
  final String message;

  const RecentReportsError(this.message);

  @override
  List<Object?> get props => [message];
}
