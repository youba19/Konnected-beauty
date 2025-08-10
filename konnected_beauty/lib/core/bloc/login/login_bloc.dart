import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../translations/app_translations.dart';

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

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Validate inputs
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(LoginError(state, 'Please enter your email and password'));
        return;
      }

      // Simulate login logic
      if (event.email == 'test@test.com' && event.password == 'password') {
        emit(LoginSuccess(state));
        // TODO: Navigate to home screen
      } else {
        emit(LoginError(
            state, 'Wrong Credentials! Enter your correct information please'));
      }
    } catch (e) {
      emit(LoginError(state, 'An error occurred. Please try again.'));
    }
  }
}
