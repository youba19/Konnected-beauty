import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/storage/token_storage_service.dart';
import '../../services/api/salon_auth_service.dart';
import '../../services/api/influencer_auth_service.dart';

// Events
abstract class AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class CheckProfileStatus extends AuthEvent {}

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

class AuthProfileIncomplete extends AuthState {
  final String email;
  final String role;
  final String accessToken;

  AuthProfileIncomplete({
    required this.email,
    required this.role,
    required this.accessToken,
  });
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<CheckProfileStatus>(_onCheckProfileStatus);
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
        print('🔐 This means either:');
        print('🔐   1. No tokens stored');
        print('🔐   2. Tokens were cleared');
        print('🔐   3. TokenStorageService.isLoggedIn() returned false');
        emit(AuthUnauthenticated());
        return;
      }

      // Get user info first to debug
      final email = await TokenStorageService.getUserEmail();
      final role = await TokenStorageService.getUserRole();
      final accessToken = await TokenStorageService.getAccessToken();

      print('🔐 Stored user info:');
      print('   📧 Email: $email');
      print('   👤 Role: $role');
      print('   🔑 Access Token: ${accessToken?.substring(0, 50)}...');

      // Check if access token is expired
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔐 Token expired check: $isExpired');

      if (isExpired) {
        print('🔐 Token is expired, attempting refresh...');
        // Try to refresh the token
        final refreshToken = await TokenStorageService.getRefreshToken();
        if (refreshToken != null) {
          print('🔐 Refresh token found, attempting refresh...');

          // Check if refresh token is also expired
          final isRefreshTokenExpired =
              await TokenStorageService.isRefreshTokenExpired();
          if (isRefreshTokenExpired) {
            print(
                '🔐 Refresh token is also expired, user needs to login again');
            await TokenStorageService.clearAuthData();
            emit(AuthUnauthenticated());
            return;
          }

          // Get user role to determine which service to use
          final userRole = await TokenStorageService.getUserRole();
          print('🔐 Using role for refresh: $userRole');

          final refreshResult = userRole == 'influencer'
              ? await InfluencerAuthService.refreshToken(
                  refreshToken: refreshToken)
              : await SalonAuthService.refreshToken(refreshToken: refreshToken);

          print('🔐 Refresh result: $refreshResult');

          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);
            print('🔐 New access token saved');

            // Also save new refresh token if provided
            final newRefreshToken = refreshResult['data']?['refresh_token'];
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await TokenStorageService.saveRefreshToken(newRefreshToken);
              print('🔐 New refresh token saved');
            }

            // Get user info
            final email = await TokenStorageService.getUserEmail();
            final role = await TokenStorageService.getUserRole();

            print('🔐 Token refreshed, checking user status/profile...');
            print('   📧 Email: $email');
            print('   👤 Role: $role');

            // Check profile status after token refresh
            if (role == 'influencer') {
              print('👤 Checking influencer profile status after refresh...');
              final profileResult = await InfluencerAuthService.getProfile();

              if (profileResult['success'] && profileResult['data'] != null) {
                final profileData = profileResult['data'];
                final userStatus =
                    profileData['status']?.toString().toLowerCase().trim() ??
                        '';

                print('👤 Influencer status: "$userStatus"');

                if (userStatus == 'pending' ||
                    userStatus == 'active' ||
                    userStatus == 'verified' ||
                    userStatus == 'approved') {
                  print(
                      '✅ Influencer profile is complete, emitting AuthAuthenticated');
                  emit(AuthAuthenticated(
                    email: email ?? '',
                    role: role ?? '',
                    accessToken: newAccessToken,
                  ));
                } else {
                  print(
                      '⚠️ Influencer profile is incomplete, emitting AuthProfileIncomplete');
                  emit(AuthProfileIncomplete(
                    email: email ?? '',
                    role: role ?? '',
                    accessToken: newAccessToken,
                  ));
                }
              } else {
                print(
                    '⚠️ Failed to get influencer profile, emitting AuthProfileIncomplete');
                emit(AuthProfileIncomplete(
                  email: email ?? '',
                  role: role ?? '',
                  accessToken: newAccessToken,
                ));
              }
            } else if (role == 'saloon') {
              print('🏢 Checking salon profile status after refresh...');
              final profileResult = await SalonAuthService.getSalonProfile();

              if (profileResult['success'] && profileResult['data'] != null) {
                final profileData = profileResult['data'];
                final salonStatus =
                    profileData['status']?.toString().toLowerCase().trim() ??
                        '';

                print('🏢 Salon status: "$salonStatus"');

                if (salonStatus == 'pending' ||
                    salonStatus == 'active' ||
                    salonStatus == 'verified' ||
                    salonStatus == 'approved') {
                  print(
                      '✅ Salon profile is complete, emitting AuthAuthenticated');
                  emit(AuthAuthenticated(
                    email: email ?? '',
                    role: role ?? '',
                    accessToken: newAccessToken,
                  ));
                } else {
                  print(
                      '⚠️ Salon profile is incomplete, emitting AuthProfileIncomplete');
                  emit(AuthProfileIncomplete(
                    email: email ?? '',
                    role: role ?? '',
                    accessToken: newAccessToken,
                  ));
                }
              } else {
                print(
                    '⚠️ Failed to get salon profile, emitting AuthProfileIncomplete');
                emit(AuthProfileIncomplete(
                  email: email ?? '',
                  role: role ?? '',
                  accessToken: newAccessToken,
                ));
              }
            } else {
              print('⚠️ Unknown role, emitting AuthAuthenticated');
              emit(AuthAuthenticated(
                email: email ?? '',
                role: role ?? '',
                accessToken: newAccessToken,
              ));
            }
            return;
          } else {
            print('🔐 Token refresh failed: ${refreshResult['message']}');
            // Don't logout immediately - might be a temporary network issue
            // Only logout if refresh token is expired
            final isRefreshTokenExpiredAfterFailure =
                await TokenStorageService.isRefreshTokenExpired();
            if (isRefreshTokenExpiredAfterFailure) {
              print(
                  '🔐 Refresh token expired after failed refresh, clearing auth data');
              await TokenStorageService.clearAuthData();
              emit(AuthUnauthenticated());
              return;
            } else {
              print(
                  '⚠️ Refresh failed but refresh token still valid. Checking user status...');
              // Keep user logged in with existing token, but check status
              final email = await TokenStorageService.getUserEmail();
              final role = await TokenStorageService.getUserRole();

              // Check profile status even if refresh failed
              if (role == 'influencer') {
                try {
                  final profileResult =
                      await InfluencerAuthService.getProfile();
                  if (profileResult['success'] &&
                      profileResult['data'] != null) {
                    final profileData = profileResult['data'];
                    final userStatus = profileData['status']
                            ?.toString()
                            .toLowerCase()
                            .trim() ??
                        '';
                    if (userStatus == 'pending' ||
                        userStatus == 'active' ||
                        userStatus == 'verified' ||
                        userStatus == 'approved') {
                      emit(AuthAuthenticated(
                        email: email ?? '',
                        role: role ?? '',
                        accessToken: accessToken ?? '',
                      ));
                    } else {
                      emit(AuthProfileIncomplete(
                        email: email ?? '',
                        role: role ?? '',
                        accessToken: accessToken ?? '',
                      ));
                    }
                  } else {
                    emit(AuthProfileIncomplete(
                      email: email ?? '',
                      role: role ?? '',
                      accessToken: accessToken ?? '',
                    ));
                  }
                } catch (e) {
                  // If profile check fails, keep authenticated to avoid logout
                  emit(AuthAuthenticated(
                    email: email ?? '',
                    role: role ?? '',
                    accessToken: accessToken ?? '',
                  ));
                }
              } else if (role == 'saloon') {
                try {
                  final profileResult =
                      await SalonAuthService.getSalonProfile();
                  if (profileResult['success'] &&
                      profileResult['data'] != null) {
                    final profileData = profileResult['data'];
                    final salonStatus = profileData['status']
                            ?.toString()
                            .toLowerCase()
                            .trim() ??
                        '';
                    if (salonStatus == 'pending' ||
                        salonStatus == 'active' ||
                        salonStatus == 'verified' ||
                        salonStatus == 'approved') {
                      emit(AuthAuthenticated(
                        email: email ?? '',
                        role: role ?? '',
                        accessToken: accessToken ?? '',
                      ));
                    } else {
                      emit(AuthProfileIncomplete(
                        email: email ?? '',
                        role: role ?? '',
                        accessToken: accessToken ?? '',
                      ));
                    }
                  } else {
                    emit(AuthProfileIncomplete(
                      email: email ?? '',
                      role: role ?? '',
                      accessToken: accessToken ?? '',
                    ));
                  }
                } catch (e) {
                  // If profile check fails, keep authenticated to avoid logout
                  emit(AuthAuthenticated(
                    email: email ?? '',
                    role: role ?? '',
                    accessToken: accessToken ?? '',
                  ));
                }
              } else {
                emit(AuthAuthenticated(
                  email: email ?? '',
                  role: role ?? '',
                  accessToken: accessToken ?? '',
                ));
              }
              return;
            }
          }
        } else {
          print('🔐 No refresh token found, user needs to login again');
          await TokenStorageService.clearAuthData();
          emit(AuthUnauthenticated());
          return;
        }
      }

      // Token is valid, now check user status/profile completeness
      print('🔐 Token is valid, checking user status/profile...');
      print('🔐 Final user info:');
      print('   📧 Email: $email');
      print('   👤 Role: $role');
      print('   🔑 Access Token: ${accessToken?.substring(0, 50)}...');

      // Check profile status based on role
      if (role == 'influencer') {
        print('👤 Checking influencer profile status...');
        final profileResult = await InfluencerAuthService.getProfile();

        if (profileResult['success'] && profileResult['data'] != null) {
          final profileData = profileResult['data'];
          final userStatus =
              profileData['status']?.toString().toLowerCase().trim() ?? '';

          print('👤 Influencer status: "$userStatus"');
          print('👤 Profile data: $profileData');

          // Check if status is pending or active
          if (userStatus == 'pending' ||
              userStatus == 'active' ||
              userStatus == 'verified' ||
              userStatus == 'approved') {
            print('✅ Influencer profile is complete (status: $userStatus)');
            emit(AuthAuthenticated(
              email: email ?? '',
              role: role ?? '',
              accessToken: accessToken ?? '',
            ));
            print('🔐 Emitted AuthAuthenticated state');
          } else {
            print('⚠️ Influencer profile is incomplete (status: $userStatus)');
            emit(AuthProfileIncomplete(
              email: email ?? '',
              role: role ?? '',
              accessToken: accessToken ?? '',
            ));
            print('🔐 Emitted AuthProfileIncomplete state');
          }
        } else {
          print('⚠️ Failed to get influencer profile, treating as incomplete');
          emit(AuthProfileIncomplete(
            email: email ?? '',
            role: role ?? '',
            accessToken: accessToken ?? '',
          ));
          print('🔐 Emitted AuthProfileIncomplete state');
        }
      } else if (role == 'saloon') {
        print('🏢 Checking salon profile status...');
        final profileResult = await SalonAuthService.getSalonProfile();

        if (profileResult['success'] && profileResult['data'] != null) {
          final profileData = profileResult['data'];
          final salonStatus =
              profileData['status']?.toString().toLowerCase().trim() ?? '';

          print('🏢 Salon status: "$salonStatus"');
          print('🏢 Profile data: $profileData');

          // Check if status is pending or active
          if (salonStatus == 'pending' ||
              salonStatus == 'active' ||
              salonStatus == 'verified' ||
              salonStatus == 'approved') {
            print('✅ Salon profile is complete (status: $salonStatus)');
            emit(AuthAuthenticated(
              email: email ?? '',
              role: role ?? '',
              accessToken: accessToken ?? '',
            ));
            print('🔐 Emitted AuthAuthenticated state');
          } else {
            print('⚠️ Salon profile is incomplete (status: $salonStatus)');
            emit(AuthProfileIncomplete(
              email: email ?? '',
              role: role ?? '',
              accessToken: accessToken ?? '',
            ));
            print('🔐 Emitted AuthProfileIncomplete state');
          }
        } else {
          print('⚠️ Failed to get salon profile, treating as incomplete');
          emit(AuthProfileIncomplete(
            email: email ?? '',
            role: role ?? '',
            accessToken: accessToken ?? '',
          ));
          print('🔐 Emitted AuthProfileIncomplete state');
        }
      } else {
        // Unknown role, just authenticate
        print('⚠️ Unknown role: $role, emitting AuthAuthenticated');
        emit(AuthAuthenticated(
          email: email ?? '',
          role: role ?? '',
          accessToken: accessToken ?? '',
        ));
        print('🔐 Emitted AuthAuthenticated state');
      }
    } catch (e) {
      print('🔐 Error during auth check: $e');
      print('🔐 Stack trace: ${StackTrace.current}');
      emit(AuthError('Authentication check failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckProfileStatus(
    CheckProfileStatus event,
    Emitter<AuthState> emit,
  ) async {
    print('🏢 === CHECKING PROFILE STATUS ===');
    print('🏢 Event received: ${event.runtimeType}');
    print('🏢 Starting profile status check...');
    emit(AuthLoading());

    try {
      // First check if user is authenticated
      final isLoggedIn = await TokenStorageService.isLoggedIn();
      if (!isLoggedIn) {
        print('🔐 User not logged in, emitting AuthUnauthenticated');
        emit(AuthUnauthenticated());
        return;
      }

      // Get user role to determine which profile to check
      final role = await TokenStorageService.getUserRole();
      print('👤 User role: $role');

      if (role == 'saloon') {
        // Check salon profile
        final profileResult = await SalonAuthService.getSalonProfile();

        if (profileResult['success']) {
          final profileData = profileResult['data'];
          print('🏢 Salon profile found: $profileData');

          // Check if profile is complete based on status
          final hasCompleteProfile =
              profileData != null && profileData['status'] == 'pending';

          print('🏢 === PROFILE COMPLETENESS CHECK ===');
          print('🏢 Profile data: $profileData');
          print('🏢 Status: ${profileData['status']}');
          print('🏢 salonInfo: ${profileData['salonInfo']}');
          print('🏢 salonProfile: ${profileData['salonProfile']}');
          print(
              '🏢 Has complete profile (status == pending): $hasCompleteProfile');

          if (hasCompleteProfile) {
            print('✅ Profile complete, navigating to home');
            print('✅ Emitting AuthAuthenticated state');
            // Profile is complete, emit authenticated state
            final email = await TokenStorageService.getUserEmail();
            final accessToken = await TokenStorageService.getAccessToken();

            emit(AuthAuthenticated(
              email: email ?? '',
              role: role ?? '',
              accessToken: accessToken ?? '',
            ));
            print('✅ AuthAuthenticated state emitted successfully');
          } else {
            print('⚠️ Profile incomplete, navigating to registration');

            // Check if status is "email-verified" and refresh token if needed
            if (profileData['status'] == 'email-verified') {
              print('🔄 Status is email-verified, refreshing token...');
              final refreshToken = await TokenStorageService.getRefreshToken();
              if (refreshToken != null) {
                final userRole = await TokenStorageService.getUserRole();
                final refreshResult = userRole == 'influencer'
                    ? await InfluencerAuthService.refreshToken(
                        refreshToken: refreshToken)
                    : await SalonAuthService.refreshToken(
                        refreshToken: refreshToken);

                if (refreshResult['success']) {
                  final newAccessToken = refreshResult['data']['access_token'];
                  await TokenStorageService.saveAccessToken(newAccessToken);
                  print(
                      '✅ Token refreshed successfully for email-verified user');
                } else {
                  print('❌ Failed to refresh token for email-verified user');
                }
              }
            }

            print('⚠️ Emitting AuthProfileIncomplete state');
            // Profile is incomplete, emit profile incomplete state to show registration
            final email = await TokenStorageService.getUserEmail();
            final accessToken = await TokenStorageService.getAccessToken();

            emit(AuthProfileIncomplete(
              email: email ?? '',
              role: role ?? '',
              accessToken: accessToken ?? '',
            ));
            print('⚠️ AuthProfileIncomplete state emitted successfully');
          }
        } else {
          print('❌ Failed to get salon profile: ${profileResult['message']}');
          // If profile check fails, assume profile is incomplete
          emit(AuthUnauthenticated());
        }
      } else {
        // For other roles, just check authentication
        print('👤 Non-salon role, checking basic authentication');
        await _onCheckAuthStatus(CheckAuthStatus(), emit);
      }
    } catch (e) {
      print('❌ Error checking profile status: $e');
      emit(AuthError('Profile check failed: ${e.toString()}'));
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
        final userRole = await TokenStorageService.getUserRole();
        final refreshResult = userRole == 'influencer'
            ? await InfluencerAuthService.refreshToken(
                refreshToken: refreshToken)
            : await SalonAuthService.refreshToken(refreshToken: refreshToken);

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
