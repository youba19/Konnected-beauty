import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../translations/app_translations.dart';
import '../../services/api/salon_auth_service.dart';
import '../../services/storage/token_storage_service.dart';

// Events
abstract class LoginEvent {}

class UpdateEmail extends LoginEvent {
  final String email;
  UpdateEmail(this.email);
}

class UpdatePassword extends LoginEvent {
  final String password;
  UpdatePassword(this.password);
}

class SelectRole extends LoginEvent {
  final LoginRole role;
  SelectRole(this.role);
}

class Login extends LoginEvent {
  final String email;
  final String password;
  final LoginRole role;
  Login({
    required this.email,
    required this.password,
    required this.role,
  });
}

class ClearError extends LoginEvent {}

// Enums
enum LoginRole { influencer, saloon }

// States
class LoginState {
  final String email;
  final String password;
  final LoginRole selectedRole;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const LoginState({
    required this.email,
    required this.password,
    required this.selectedRole,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
  });
}

class LoginInitial extends LoginState {
  const LoginInitial()
      : super(
          email: '',
          password: '',
          selectedRole: LoginRole.influencer,
          isLoading: false,
          hasError: false,
        );
}

class LoginLoading extends LoginState {
  LoginLoading(LoginState state)
      : super(
          email: state.email,
          password: state.password,
          selectedRole: state.selectedRole,
          isLoading: true,
          hasError: false,
        );
}

class LoginError extends LoginState {
  LoginError(LoginState state, String errorMessage)
      : super(
          email: state.email,
          password: state.password,
          selectedRole: state.selectedRole,
          isLoading: false,
          hasError: true,
          errorMessage: errorMessage,
        );
}

class LoginSuccess extends LoginState {
  LoginSuccess(LoginState state)
      : super(
          email: state.email,
          password: state.password,
          selectedRole: state.selectedRole,
          isLoading: false,
          hasError: false,
        );
}

// Bloc
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginInitial()) {
    on<UpdateEmail>(_onUpdateEmail);
    on<UpdatePassword>(_onUpdatePassword);
    on<SelectRole>(_onSelectRole);
    on<Login>(_onLogin);
    on<ClearError>(_onClearError);
  }

  void _onUpdateEmail(UpdateEmail event, Emitter<LoginState> emit) {
    emit(LoginState(
      email: event.email,
      password: state.password,
      selectedRole: state.selectedRole,
      isLoading: state.isLoading,
      hasError: false,
    ));
  }

  void _onUpdatePassword(UpdatePassword event, Emitter<LoginState> emit) {
    emit(LoginState(
      email: state.email,
      password: event.password,
      selectedRole: state.selectedRole,
      isLoading: state.isLoading,
      hasError: false,
    ));
  }

  void _onSelectRole(SelectRole event, Emitter<LoginState> emit) {
    emit(LoginState(
      email: state.email,
      password: state.password,
      selectedRole: event.role,
      isLoading: state.isLoading,
      hasError: false,
    ));
  }

  void _onClearError(ClearError event, Emitter<LoginState> emit) {
    emit(LoginState(
      email: state.email,
      password: state.password,
      selectedRole: state.selectedRole,
      isLoading: state.isLoading,
      hasError: false,
    ));
  }

  Future<void> _onLogin(Login event, Emitter<LoginState> emit) async {
    emit(LoginLoading(state));

    try {
      // Validate inputs
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(LoginError(state, 'Please enter your email and password'));
        return;
      }

      // Call the appropriate API based on role
      Map<String, dynamic> result;

      if (event.role == LoginRole.saloon) {
        // Call salon login API
        result = await SalonAuthService.login(
          email: event.email,
          password: event.password,
        );
      } else {
        // For now, handle influencer login (you can add influencer API later)
        emit(LoginError(state, 'Influencer login not implemented yet'));
        return;
      }

      if (result['success']) {
        // Login successful
        final data = result['data'];

        // Extract tokens from response
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        // Save authentication data
        await TokenStorageService.saveAuthData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          email: event.email,
          role: event.role.name,
        );

        emit(LoginSuccess(state));
        // TODO: Navigate to home screen based on role
      } else {
        // Login failed
        emit(LoginError(state, result['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(LoginError(state, 'Network error: ${e.toString()}'));
    }
  }
}
