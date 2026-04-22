import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_auth_service.dart';
import '../../services/api/influencer_auth_service.dart';
import '../../services/api/http_interceptor.dart';
import '../../services/storage/token_storage_service.dart';
import '../../services/firebase_notification_service.dart';

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
  final String userStatus;

  LoginSuccess(LoginState state, {required this.userStatus})
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
      } else if (event.role == LoginRole.influencer) {
        // Call influencer login API using exact same logic
        result = await InfluencerAuthService.login(
          email: event.email,
          password: event.password,
        );
      } else {
        emit(LoginError(state, 'Invalid role selected'));
        return;
      }

      if (result['success']) {
        // Login successful
        final data = result['data'];

        print('🎉 === LOGIN SUCCESS ===');
        print('📊 Complete Login Result: $result');
        print('📦 Login Data: $data');

        // Extract tokens directly from API response
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final user = data['user']; // Extract user object if present

        // Print detailed response information
        print('🔐 === LOGIN TOKENS ===');
        print('📧 Email: ${event.email}');
        print('👤 Role: ${event.role.name}');
        print('📊 Direct Status from API: ${data['status']}');
        print('🔍 Status from data.status: ${data['status']}');
        print('🔍 Status from data.user?.status: ${user?['status']}');
        print('👤 User Object: $user');
        print('🔑 Access Token: $accessToken');
        print('🔄 Refresh Token: $refreshToken');
        print('🔐 === END TOKENS ===');
        print('🎉 === END LOGIN SUCCESS ===');

        // Use API response directly without any storage or variables
        print('🎯 Using API response directly - no storage, no variables');

        // Get the status directly from the API response data
        final directStatus = data['status'];
        print('🎯 Direct status from API: $directStatus');
        print('🎯 Direct status type: ${directStatus.runtimeType}');

        // Store tokens only for API calls
        await TokenStorageService.saveAuthData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          email: event.email,
          role: event.role.name,
        );

        // Register FCM token for notifications (non-blocking)
        _registerFCMTokenAfterLogin(event.role.name).catchError((error) {
          print('⚠️ Failed to register FCM token after login: $error');
          // Don't block login success if FCM registration fails
        });

        // Use the direct status from API response
        emit(LoginSuccess(state, userStatus: directStatus.toString()));
      } else {
        // Login failed
        print('❌ === LOGIN FAILED ===');
        print('📊 Failed Login Result: $result');
        print('📄 Error Message: ${result['message']}');
        print('🔢 Status Code: ${result['statusCode']}');
        print('❌ === END LOGIN FAILED ===');

        emit(LoginError(state, result['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(LoginError(state, 'Network error: ${e.toString()}'));
    }
  }

  /// Register FCM token after successful login
  Future<void> _registerFCMTokenAfterLogin(String userRole) async {
    try {
      print('📱 === REGISTERING FCM TOKEN AFTER LOGIN ===');

      // Get FCM token from FirebaseNotificationService
      final notificationService = FirebaseNotificationService();
      String? fcmToken = notificationService.fcmToken;

      // If token is not available, try to retrieve it
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⏳ FCM token not available, attempting to retrieve...');
        fcmToken = await notificationService.retrieveFCMToken();
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ FCM token is not available yet, skipping registration');
        print('ℹ️ Token will be registered when it becomes available');
        return;
      }

      print('✅ FCM token available: ${fcmToken.substring(0, 20)}...');

      // Register token using HttpInterceptor
      final result = await HttpInterceptor.registerFCMToken(
        token: fcmToken,
        userRole: userRole,
      );

      if (result['success'] == true) {
        print('✅ FCM token registered successfully after login');
      } else {
        print('❌ Failed to register FCM token: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error registering FCM token after login: $e');
      // Don't throw - this is a non-critical operation
    }
  }
}
