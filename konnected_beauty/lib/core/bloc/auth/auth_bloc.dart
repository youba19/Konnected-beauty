import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/storage/token_storage_service.dart';
import '../../services/api/salon_auth_service.dart';

// Events
abstract class AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class Logout extends AuthEvent {}

class RefreshToken extends AuthEvent {}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String email;
  final String role;
  final String accessToken;

  AuthAuthenticated({
    required this.email,
    required this.role,
    required this.accessToken,
  });
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<Logout>(_onLogout);
    on<RefreshToken>(_onRefreshToken);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 === AUTH STATUS CHECK ===');
    emit(AuthLoading());

    try {
      // Debug: Print stored tokens
      await TokenStorageService.printStoredTokens();

      // Check if user is logged in
      final isLoggedIn = await TokenStorageService.isLoggedIn();
      print('🔐 Is logged in: $isLoggedIn');

      if (!isLoggedIn) {
        print('🔐 User not logged in, emitting AuthUnauthenticated');
        emit(AuthUnauthenticated());
        return;
      }

      // Check if access token is expired
      final isExpired = await TokenStorageService.isAccessTokenExpired();

      if (isExpired) {
        // Try to refresh the token
        final refreshToken = await TokenStorageService.getRefreshToken();
        if (refreshToken != null) {
          final refreshResult =
              await SalonAuthService.refreshToken(refreshToken: refreshToken);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);

            // Get user info
            final email = await TokenStorageService.getUserEmail();
            final role = await TokenStorageService.getUserRole();

            emit(AuthAuthenticated(
              email: email ?? '',
              role: role ?? '',
              accessToken: newAccessToken,
            ));
            return;
          }
        }

        // If refresh failed, logout
        await TokenStorageService.clearAuthData();
        emit(AuthUnauthenticated());
        return;
      }

      // Token is valid, get user info
      final email = await TokenStorageService.getUserEmail();
      final role = await TokenStorageService.getUserRole();
      final accessToken = await TokenStorageService.getAccessToken();

      print('🔐 Token is valid, user info:');
      print('   📧 Email: $email');
      print('   👤 Role: $role');
      print('   🔑 Access Token: ${accessToken?.substring(0, 50)}...');

      emit(AuthAuthenticated(
        email: email ?? '',
        role: role ?? '',
        accessToken: accessToken ?? '',
      ));
      print('🔐 Emitted AuthAuthenticated state');
    } catch (e) {
      emit(AuthError('Authentication check failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(
    Logout event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('🚪 === LOGOUT PROCESS ===');
      print('🚪 Clearing all app data to prevent cross-user contamination');

      // Clear all app data to ensure no cross-user data remains
      await TokenStorageService.clearAllData();

      print('🚪 === LOGOUT COMPLETED ===');
      emit(AuthUnauthenticated());
    } catch (e) {
      print('❌ Logout failed: $e');
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshToken(
    RefreshToken event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final refreshToken = await TokenStorageService.getRefreshToken();
      if (refreshToken != null) {
        final refreshResult =
            await SalonAuthService.refreshToken(refreshToken: refreshToken);
        if (refreshResult['success']) {
          final newAccessToken = refreshResult['data']['access_token'];
          await TokenStorageService.saveAccessToken(newAccessToken);

          // Get current state and update if authenticated
          if (state is AuthAuthenticated) {
            final currentState = state as AuthAuthenticated;
            emit(AuthAuthenticated(
              email: currentState.email,
              role: currentState.role,
              accessToken: newAccessToken,
            ));
          }
        }
      }
    } catch (e) {
      // Don't emit error for refresh token failure
      print('Token refresh failed: $e');
    }
  }
}
