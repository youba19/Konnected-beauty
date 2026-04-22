import 'package:equatable/equatable.dart';

abstract class CampaignActionsEvent extends Equatable {
  const CampaignActionsEvent();

  @override
  List<Object> get props => [];
}

class AcceptCampaign extends CampaignActionsEvent {
  final String campaignId;

  const AcceptCampaign({required this.campaignId});

  @override
  List<Object> get props => [campaignId];
}

class RejectCampaign extends CampaignActionsEvent {
  final String campaignId;
  final String? replyMessage;

  const RejectCampaign({
    required this.campaignId,
    this.replyMessage,
  });

  @override
  List<Object> get props => [campaignId, replyMessage ?? ''];
}
