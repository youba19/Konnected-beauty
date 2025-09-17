abstract class CampaignsEvent {}

class LoadCampaigns extends CampaignsEvent {
  final int page;
  final int limit;
  final String? search;
  final String? status;

  LoadCampaigns({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
  });
}

class LoadMoreCampaigns extends CampaignsEvent {
  final int page;
  final int limit;
  final String? search;
  final String? status;

  LoadMoreCampaigns({
    required this.page,
    this.limit = 10,
    this.search,
    this.status,
  });
}

class RefreshCampaigns extends CampaignsEvent {
  final int page;
  final int limit;
  final String? search;
  final String? status;

  RefreshCampaigns({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
  });
}

class DeleteCampaign extends CampaignsEvent {
  final String campaignId;

  DeleteCampaign({required this.campaignId});

  List<Object> get props => [campaignId];
}
