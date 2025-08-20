import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_auth_service.dart';
import '../../services/api/influencer_auth_service.dart';

// Events
abstract class ResetPasswordEvent {}

class RequestPasswordReset extends ResetPasswordEvent {
  final String email;
  final String role;
  RequestPasswordReset(this.email, this.role);
}

class VerifyResetPasswordOtp extends ResetPasswordEvent {
  final String email;
  final String otp;
  final String role;
  VerifyResetPasswordOtp(
      {required this.email, required this.otp, required this.role});
}

class ResetPassword extends ResetPasswordEvent {
  final String newPassword;
  final String confirmPassword;
  final String? resetToken;
  final String? email;
  final String role;
  ResetPassword(
      {required this.newPassword,
      required this.confirmPassword,
      this.resetToken,
      this.email,
      required this.role});
}

class ResetResetPasswordState extends ResetPasswordEvent {}

// States
abstract class ResetPasswordState {}

class ResetPasswordInitial extends ResetPasswordState {}

class ResetPasswordLoading extends ResetPasswordState {}

class RequestPasswordResetSuccess extends ResetPasswordState {
  final String message;
  RequestPasswordResetSuccess(this.message);
}

class VerifyResetPasswordOtpSuccess extends ResetPasswordState {
  final String message;
  final String? resetToken;
  VerifyResetPasswordOtpSuccess(this.message, {this.resetToken});
}

class ResetPasswordSuccess extends ResetPasswordState {
  final String message;
  ResetPasswordSuccess(this.message);
}

class ResetPasswordError extends ResetPasswordState {
  final String message;
  ResetPasswordError(this.message);
}

// BLoC
class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc() : super(ResetPasswordInitial()) {
    on<RequestPasswordReset>(_onRequestPasswordReset);
    on<VerifyResetPasswordOtp>(_onVerifyResetPasswordOtp);
    on<ResetPassword>(_onResetPassword);
    on<ResetResetPasswordState>(_onResetResetPasswordState);
  }

  Future<void> _onRequestPasswordReset(
    RequestPasswordReset event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(ResetPasswordLoading());

    try {
      final result = event.role == 'influencer'
          ? await InfluencerAuthService.requestPasswordReset(
              email: event.email,
            )
          : await SalonAuthService.requestPasswordReset(
              email: event.email,
            );

      if (result['success']) {
        emit(RequestPasswordResetSuccess(result['message']));
      } else {
        emit(ResetPasswordError(result['message']));
      }
    } catch (e) {
      emit(ResetPasswordError('Network error: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyResetPasswordOtp(
    VerifyResetPasswordOtp event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(ResetPasswordLoading());

    try {
      final result = event.role == 'influencer'
          ? await InfluencerAuthService.verifyResetPasswordOtp(
              email: event.email,
              otp: event.otp,
            )
          : await SalonAuthService.verifyResetPasswordOtp(
              email: event.email,
              otp: event.otp,
            );

      if (result['success']) {
        // Extract reset token from response data if available
        print('🔍 BLoC: OTP Success Result Keys: ${result.keys.toList()}');
        print('🔍 BLoC: Result Data: ${result['data']}');
        if (result['data'] != null) {
          print('🔍 BLoC: Data Keys: ${result['data'].keys.toList()}');
        }

        // Extract access_token from the response data
        final resetToken = result['data']?['access_token'];
        print('🔍 BLoC: Extracted Reset Token: ${resetToken ?? 'NULL'}');

        emit(VerifyResetPasswordOtpSuccess(result['message'],
            resetToken: resetToken));
      } else {
        emit(ResetPasswordError(result['message']));
      }
    } catch (e) {
      emit(ResetPasswordError('Network error: ${e.toString()}'));
    }
  }

  Future<void> _onResetPassword(
    ResetPassword event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(ResetPasswordLoading());

    print(
        '🔍 BLoC: Reset Password Event - Token: ${event.resetToken ?? 'NULL'}');

    try {
      final result = event.role == 'influencer'
          ? await InfluencerAuthService.resetPassword(
              newPassword: event.newPassword,
              confirmPassword: event.confirmPassword,
              resetToken: event.resetToken,
              email: event.email,
            )
          : await SalonAuthService.resetPassword(
              newPassword: event.newPassword,
              confirmPassword: event.confirmPassword,
              resetToken: event.resetToken,
              email: event.email,
            );

      if (result['success']) {
        emit(ResetPasswordSuccess(result['message']));
      } else {
        emit(ResetPasswordError(result['message']));
      }
    } catch (e) {
      emit(ResetPasswordError('Network error: ${e.toString()}'));
    }
  }

  void _onResetResetPasswordState(
    ResetResetPasswordState event,
    Emitter<ResetPasswordState> emit,
  ) {
    emit(ResetPasswordInitial());
  }
}
