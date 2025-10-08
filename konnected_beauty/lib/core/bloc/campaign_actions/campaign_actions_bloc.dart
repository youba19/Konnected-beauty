import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';
import 'campaign_actions_event.dart';
import 'campaign_actions_state.dart';

class CampaignActionsBloc
    extends Bloc<CampaignActionsEvent, CampaignActionsState> {
  CampaignActionsBloc() : super(CampaignActionsInitial()) {
    on<AcceptCampaign>(_onAcceptCampaign);
    on<RejectCampaign>(_onRejectCampaign);
  }

  Future<void> _onAcceptCampaign(
    AcceptCampaign event,
    Emitter<CampaignActionsState> emit,
  ) async {
    try {
      emit(CampaignActionsLoading());

      final result = await InfluencersService.acceptSalonInvite(
        campaignId: event.campaignId,
      );

      if (result['success'] == true) {
        emit(CampaignAccepted(
          message: result['message'] ?? 'Campaign accepted successfully',
        ));
      } else {
        emit(CampaignActionsError(
          message: result['message'] ?? 'Failed to accept campaign',
        ));
      }
    } catch (e) {
      emit(CampaignActionsError(
        message: 'Error accepting campaign: $e',
      ));
    }
  }

  Future<void> _onRejectCampaign(
    RejectCampaign event,
    Emitter<CampaignActionsState> emit,
  ) async {
    try {
      emit(CampaignActionsLoading());

      final result = await InfluencersService.rejectSalonInvite(
        campaignId: event.campaignId,
      );

      if (result['success'] == true) {
        emit(CampaignRejected(
          message: result['message'] ?? 'Campaign rejected successfully',
        ));
      } else {
        emit(CampaignActionsError(
          message: result['message'] ?? 'Failed to reject campaign',
        ));
      }
    } catch (e) {
      emit(CampaignActionsError(
        message: 'Error rejecting campaign: $e',
      ));
    }
  }
}
