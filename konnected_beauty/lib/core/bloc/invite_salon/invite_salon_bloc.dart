import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/invite_salon_service.dart';
import 'invite_salon_event.dart';
import 'invite_salon_state.dart';

class InviteSalonBloc extends Bloc<InviteSalonEvent, InviteSalonState> {
  InviteSalonBloc() : super(InviteSalonInitial()) {
    on<InviteSalon>(_onInviteSalon);
  }

  Future<void> _onInviteSalon(
    InviteSalon event,
    Emitter<InviteSalonState> emit,
  ) async {
    print('📧 === INVITING SALON BLOC ===');
    print('📧 Receiver ID: ${event.receiverId}');
    print('📧 Promotion: ${event.promotion}');
    print('📧 Promotion Type: ${event.promotionType}');
    print('📧 Message: ${event.invitationMessage}');

    emit(InviteSalonLoading());

    try {
      final result = await InviteSalonService.inviteSalon(
        receiverId: event.receiverId,
        promotion: event.promotion,
        promotionType: event.promotionType,
        invitationMessage: event.invitationMessage,
      );

      if (result['success'] == true) {
        print('✅ Invitation sent successfully');
        emit(InviteSalonSuccess(
          invitationData: result['data'],
          message: result['message'] ?? 'Invitation sent successfully',
        ));
      } else {
        print('❌ Failed to send invitation: ${result['message']}');
        emit(InviteSalonError(
          result['message'] ?? 'Failed to send invitation',
          stripeAccountNotLinked: result['stripeAccountNotLinked'] == true,
        ));
      }
    } catch (e) {
      print('❌ Error in invite salon bloc: $e');
      emit(InviteSalonError('Error sending invitation: ${e.toString()}'));
    }
  }
}
