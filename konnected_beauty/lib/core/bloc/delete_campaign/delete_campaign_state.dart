abstract class DeleteCampaignState {}

class DeleteCampaignInitial extends DeleteCampaignState {}

class DeleteCampaignLoading extends DeleteCampaignState {}

class DeleteCampaignSuccess extends DeleteCampaignState {
  final String message;

  DeleteCampaignSuccess({required this.message});
}

class DeleteCampaignError extends DeleteCampaignState {
  final String message;

  DeleteCampaignError({required this.message});
}
