import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';
import 'payment_information_event.dart';
import 'payment_information_state.dart';

class PaymentInformationBloc
    extends Bloc<PaymentInformationEvent, PaymentInformationState> {
  PaymentInformationBloc() : super(PaymentInformationInitial()) {
    on<UpdatePaymentInformation>(_onUpdatePaymentInformation);
  }

  Future<void> _onUpdatePaymentInformation(
    UpdatePaymentInformation event,
    Emitter<PaymentInformationState> emit,
  ) async {
    try {
      emit(PaymentInformationLoading());

      final result = await InfluencersService.updatePaymentInformation(
        businessName: event.businessName,
        registryNumber: event.registryNumber,
        iban: event.iban,
      );

      if (result['success'] == true) {
        emit(PaymentInformationSuccess(
          message: 'Payment information updated',
        ));
      } else {
        emit(PaymentInformationError(
          message: result['message'] ?? 'Failed to update payment information',
        ));
      }
    } catch (e) {
      emit(PaymentInformationError(
        message: 'Error updating payment information: $e',
      ));
    }
  }
}
