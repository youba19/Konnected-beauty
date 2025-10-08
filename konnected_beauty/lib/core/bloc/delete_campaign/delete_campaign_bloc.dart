import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';
import 'delete_campaign_event.dart';
import 'delete_campaign_state.dart';

class DeleteCampaignBloc
    extends Bloc<DeleteCampaignEvent, DeleteCampaignState> {
  DeleteCampaignBloc() : super(DeleteCampaignInitial()) {
    on<DeleteCampaignInvitation>(_onDeleteCampaignInvitation);
  }

  Future<void> _onDeleteCampaignInvitation(
    DeleteCampaignInvitation event,
    Emitter<DeleteCampaignState> emit,
  ) async {
    emit(DeleteCampaignLoading());

    try {
      final result = await InfluencersService.deleteInfluencerCampaignInvite(
        campaignId: event.campaignId,
      );

      if (result['success'] == true) {
        emit(DeleteCampaignSuccess(
          message:
              result['message'] ?? 'Campaign invitation deleted successfully',
        ));
      } else {
        emit(DeleteCampaignError(
          message: result['message'] ?? 'Failed to delete campaign invitation',
        ));
      }
    } catch (e) {
      emit(DeleteCampaignError(
        message: 'Error deleting campaign invitation: $e',
      ));
    }
  }
}
