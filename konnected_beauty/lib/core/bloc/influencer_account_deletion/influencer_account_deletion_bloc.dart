import 'package:flutter_bloc/flutter_bloc.dart';
import 'influencer_account_deletion_event.dart';
import 'influencer_account_deletion_state.dart';
import '../../services/api/reports_service.dart';

class InfluencerAccountDeletionBloc
    extends Bloc<InfluencerAccountDeletionEvent, InfluencerAccountDeletionState> {
  final ReportsService reportsService;

  InfluencerAccountDeletionBloc({ReportsService? service})
      : reportsService = service ?? ReportsService(),
        super(InfluencerAccountDeletionInitial()) {
    on<RequestInfluencerAccountDeletion>(_onRequestAccountDeletion);
  }

  Future<void> _onRequestAccountDeletion(
    RequestInfluencerAccountDeletion event,
    Emitter<InfluencerAccountDeletionState> emit,
  ) async {
    final trimmed = event.reason.trim();
    if (trimmed.isEmpty) {
      emit(InfluencerAccountDeletionError(message: 'Reason is required'));
      return;
    }
    
    emit(InfluencerAccountDeletionLoading());
    
    final result = await reportsService.requestInfluencerAccountDeletion(
      reason: trimmed,
    );
    
    if (result['success'] == true) {
      emit(InfluencerAccountDeletionSuccess(
        message: result['message'] ?? 'Account deletion request submitted successfully',
      ));
    } else {
      emit(InfluencerAccountDeletionError(
        message: result['message'] ?? 'Failed to submit account deletion request',
      ));
    }
  }
}
