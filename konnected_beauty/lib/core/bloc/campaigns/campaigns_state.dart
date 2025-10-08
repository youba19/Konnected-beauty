abstract class CampaignsState {}

class CampaignsInitial extends CampaignsState {}

class CampaignsLoading extends CampaignsState {}

class CampaignsLoadingMore extends CampaignsState {
  final List<Map<String, dynamic>> campaigns;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;

  CampaignsLoadingMore({
    required this.campaigns,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.hasMore,
  });
}

class CampaignsLoaded extends CampaignsState {
  final List<Map<String, dynamic>> campaigns;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;
  final String? currentSearch;
  final String? currentStatus;

  CampaignsLoaded({
    required this.campaigns,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.hasMore,
    this.currentSearch,
    this.currentStatus,
  });
}

class CampaignsError extends CampaignsState {
  final String message;
  final int? statusCode;

  CampaignsError({required this.message, this.statusCode});
}

class CampaignDeleted extends CampaignsState {
  final String message;

  CampaignDeleted({required this.message});
}
