import 'package:equatable/equatable.dart';

abstract class CampaignActionsState extends Equatable {
  const CampaignActionsState();

  @override
  List<Object> get props => [];
}

class CampaignActionsInitial extends CampaignActionsState {}

class CampaignActionsLoading extends CampaignActionsState {}

class CampaignAccepted extends CampaignActionsState {
  final String message;

  const CampaignAccepted({required this.message});

  @override
  List<Object> get props => [message];
}

class CampaignRejected extends CampaignActionsState {
  final String message;

  const CampaignRejected({required this.message});

  @override
  List<Object> get props => [message];
}

class CampaignActionsError extends CampaignActionsState {
  final String message;

  const CampaignActionsError({required this.message});

  @override
  List<Object> get props => [message];
}
