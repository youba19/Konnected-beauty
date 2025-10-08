import 'package:flutter_bloc/flutter_bloc.dart';
import 'salon_account_deletion_event.dart';
import 'salon_account_deletion_state.dart';
import '../../services/api/reports_service.dart';

class SalonAccountDeletionBloc
    extends Bloc<SalonAccountDeletionEvent, SalonAccountDeletionState> {
  final ReportsService reportsService;

  SalonAccountDeletionBloc({ReportsService? service})
      : reportsService = service ?? ReportsService(),
        super(SalonAccountDeletionInitial()) {
    on<RequestSalonAccountDeletion>(_onRequestAccountDeletion);
  }

  Future<void> _onRequestAccountDeletion(
    RequestSalonAccountDeletion event,
    Emitter<SalonAccountDeletionState> emit,
  ) async {
    final trimmed = event.reason.trim();
    if (trimmed.isEmpty) {
      emit(SalonAccountDeletionError(message: 'Reason is required'));
      return;
    }
    
    emit(SalonAccountDeletionLoading());
    
    final result = await reportsService.requestSalonAccountDeletion(
      reason: trimmed,
    );
    
    if (result['success'] == true) {
      emit(SalonAccountDeletionSuccess(
        message: result['message'] ?? 'Account deletion request submitted successfully',
      ));
    } else {
      emit(SalonAccountDeletionError(
        message: result['message'] ?? 'Failed to submit account deletion request',
      ));
    }
  }
}
