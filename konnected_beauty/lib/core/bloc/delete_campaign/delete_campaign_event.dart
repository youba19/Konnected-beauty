abstract class DeleteCampaignEvent {}

class DeleteCampaignInvitation extends DeleteCampaignEvent {
  final String campaignId;

  DeleteCampaignInvitation({required this.campaignId});
}
