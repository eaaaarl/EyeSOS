abstract class AccidentsReportsLoadEvent {}

class LoadRecentReports extends AccidentsReportsLoadEvent {
  final String userId;
  LoadRecentReports({required this.userId});
}

class LoadMoreReports extends AccidentsReportsLoadEvent {
  final String userId;
  LoadMoreReports({required this.userId});
}

class RefreshReports extends AccidentsReportsLoadEvent {
  final String userId;
  RefreshReports({required this.userId});
}

class ResetReports extends AccidentsReportsLoadEvent {
  ResetReports();
}
