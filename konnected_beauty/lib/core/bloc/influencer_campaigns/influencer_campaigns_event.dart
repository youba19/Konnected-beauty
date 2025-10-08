abstract class InfluencerCampaignsEvent {}

class LoadInfluencerCampaigns extends InfluencerCampaignsEvent {
  final String? status;
  final String? search;
  final int page;
  final int limit;

  LoadInfluencerCampaigns({
    this.status,
    this.search,
    this.page = 1,
    this.limit = 10,
  });
}

class LoadMoreInfluencerCampaigns extends InfluencerCampaignsEvent {
  final String? status;
  final String? search;

  LoadMoreInfluencerCampaigns({
    this.status,
    this.search,
  });
}

class SearchInfluencerCampaigns extends InfluencerCampaignsEvent {
  final String search;

  SearchInfluencerCampaigns(this.search);
}

class RefreshInfluencerCampaigns extends InfluencerCampaignsEvent {
  final String? status;
  final String? search;

  RefreshInfluencerCampaigns({
    this.status,
    this.search,
  });
}

class FilterInfluencerCampaigns extends InfluencerCampaignsEvent {
  final String? status;

  FilterInfluencerCampaigns(this.status);
}
