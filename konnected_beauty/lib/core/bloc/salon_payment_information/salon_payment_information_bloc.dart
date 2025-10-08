import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_profile_service.dart';
import 'salon_payment_information_event.dart';
import 'salon_payment_information_state.dart';

class SalonPaymentInformationBloc
    extends Bloc<SalonPaymentInformationEvent, SalonPaymentInformationState> {
  SalonPaymentInformationBloc() : super(SalonPaymentInformationInitial()) {
    on<UpdateSalonPaymentInformation>(_onUpdateSalonPaymentInformation);
  }

  Future<void> _onUpdateSalonPaymentInformation(
    UpdateSalonPaymentInformation event,
    Emitter<SalonPaymentInformationState> emit,
  ) async {
    try {
      emit(SalonPaymentInformationLoading());

      final salonProfileService = SalonProfileService();
      final result = await salonProfileService.updatePaymentInformation(
        businessName: event.businessName,
        registryNumber: event.registryNumber,
        iban: event.iban,
      );

      if (result['success'] == true) {
        emit(SalonPaymentInformationSuccess(
          message:
              'Payment information updated', // Hardcoded for translation in UI
        ));
      } else {
        emit(SalonPaymentInformationError(
          message: result['message'] ?? 'Failed to update payment information',
        ));
      }
    } catch (e) {
      emit(SalonPaymentInformationError(
        message: 'Error updating payment information: $e',
      ));
    }
  }
}
