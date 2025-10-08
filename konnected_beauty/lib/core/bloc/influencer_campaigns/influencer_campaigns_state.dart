abstract class InfluencerCampaignsState {}

class InfluencerCampaignsInitial extends InfluencerCampaignsState {}

class InfluencerCampaignsLoading extends InfluencerCampaignsState {}

class InfluencerCampaignsLoaded extends InfluencerCampaignsState {
  final List<dynamic> campaigns;
  final String message;
  final int currentPage;
  final bool hasMore;
  final String? currentStatus;
  final String? currentSearch;
  final int total;
  final int totalPages;

  InfluencerCampaignsLoaded({
    required this.campaigns,
    required this.message,
    required this.currentPage,
    required this.hasMore,
    this.currentStatus,
    this.currentSearch,
    required this.total,
    required this.totalPages,
  });
}

class InfluencerCampaignsError extends InfluencerCampaignsState {
  final String message;
  final int? statusCode;

  InfluencerCampaignsError(this.message, {this.statusCode});
}

class InfluencerCampaignsLoadingMore extends InfluencerCampaignsState {
  final List<dynamic> campaigns;
  final String message;
  final int currentPage;
  final bool hasMore;
  final String? currentStatus;
  final String? currentSearch;
  final int total;
  final int totalPages;

  InfluencerCampaignsLoadingMore({
    required this.campaigns,
    required this.message,
    required this.currentPage,
    required this.hasMore,
    this.currentStatus,
    this.currentSearch,
    required this.total,
    required this.totalPages,
  });
}
