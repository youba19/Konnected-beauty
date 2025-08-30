import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_password_service.dart';

// Events
abstract class SalonPasswordEvent {
  const SalonPasswordEvent();
}

class ChangeSalonPassword extends SalonPasswordEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangeSalonPassword({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}

// States
abstract class SalonPasswordState {
  const SalonPasswordState();
}

class SalonPasswordInitial extends SalonPasswordState {}

class SalonPasswordChanging extends SalonPasswordState {}

class SalonPasswordChanged extends SalonPasswordState {
  final String message;

  const SalonPasswordChanged({required this.message});
}

class SalonPasswordError extends SalonPasswordState {
  final String error;

  const SalonPasswordError({required this.error});
}

// BLoC
class SalonPasswordBloc extends Bloc<SalonPasswordEvent, SalonPasswordState> {
  final SalonPasswordService _salonPasswordService;

  SalonPasswordBloc({required SalonPasswordService salonPasswordService})
      : _salonPasswordService = salonPasswordService,
        super(SalonPasswordInitial()) {
    on<ChangeSalonPassword>(_onChangeSalonPassword);
  }

  Future<void> _onChangeSalonPassword(
    ChangeSalonPassword event,
    Emitter<SalonPasswordState> emit,
  ) async {
    try {
      emit(SalonPasswordChanging());

      final result = await _salonPasswordService.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      if (result['success'] == true) {
        emit(SalonPasswordChanged(
          message: result['message'] ?? 'Password changed successfully',
        ));
      } else {
        emit(SalonPasswordError(
          error: result['message'] ?? 'Failed to change password',
        ));
      }
    } catch (e) {
      emit(SalonPasswordError(error: e.toString()));
    }
  }
}
