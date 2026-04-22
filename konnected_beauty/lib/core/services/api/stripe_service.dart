import 'dart:convert';
import '../storage/token_storage_service.dart';
import 'http_interceptor.dart';
import 'salon_auth_service.dart';
import 'influencer_auth_service.dart';
import '../../config/api_base_url.dart';

class StripeService {
  static String get baseUrl => ApiBaseUrl.value;

  // Stripe Express endpoints
  static const String onboardEndpoint = '/stripe/express/onboard';
  static const String loginLinkEndpoint = '/stripe/express/login-link';

  /// Create Stripe Express onboarding link
  /// Returns: { success: bool, data: { onboardingUrl: String, accountId: String } }
  static Future<Map<String, dynamic>> createOnboardingLink() async {
    try {
      print('💳 === CREATE STRIPE ONBOARDING LINK ===');
      print('🔗 URL: $baseUrl$onboardEndpoint');

      // Get access token
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'No access token found',
          'error': 'Unauthorized',
        };
      }

      // Use authenticated request
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: onboardEndpoint,
        body: null, // No body needed for this endpoint
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Accept both 200 (OK) and 201 (Created) as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Stripe onboarding link created successfully');
        final data = responseData['data'] ?? responseData;
        final onboardingUrl = data['onboardingUrl'] as String?;
        final accountId = data['accountId'] as String?;

        print('🌐 Onboarding URL: $onboardingUrl');
        print('🆔 Account ID: $accountId');

        return {
          'success': true,
          'data': {
            'onboardingUrl': onboardingUrl,
            'accountId': accountId,
          },
          'message':
              responseData['message'] ?? 'Onboarding link created successfully',
          'statusCode': responseData['statusCode'] ?? response.statusCode,
        };
      } else if (response.statusCode == 409) {
        // 409 Conflict - Profile not completed
        print(
            '❌ Failed to create Stripe onboarding link: Profile not completed');
        return {
          'success': false,
          'message': responseData['message'] ??
              'Please complete your salon profile first before setting up Stripe payment.',
          'error': responseData['error'] ?? 'Conflict',
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to create Stripe onboarding link');
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to create onboarding link',
          'error': responseData['error'] ?? 'Unknown error',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error creating Stripe onboarding link: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Get Stripe Express login link
  /// Returns: { success: bool, data: { loginUrl: String, accountId: String } }
  static Future<Map<String, dynamic>> getLoginLink() async {
    try {
      print('💳 === GET STRIPE LOGIN LINK ===');
      print('🔗 URL: $baseUrl$loginLinkEndpoint');

      // Check if token is expired and refresh if needed BEFORE making request
      print('🔍 === CHECKING TOKEN EXPIRY ===');
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔍 Token expired: $isExpired');

      if (isExpired) {
        print('⚠️ Access token is expired, refreshing using refresh token...');
        final refreshToken = await TokenStorageService.getRefreshToken();
        final userRole = await TokenStorageService.getUserRole();

        if (refreshToken == null || refreshToken.isEmpty) {
          print('❌ No refresh token available');
          return {
            'success': false,
            'message': 'No refresh token available',
            'error': 'Unauthorized',
          };
        }

        // Refresh token using the appropriate service
        Map<String, dynamic> refreshResult;
        if (userRole == 'influencer') {
          refreshResult = await InfluencerAuthService.refreshToken(
            refreshToken: refreshToken,
          );
        } else {
          refreshResult = await SalonAuthService.refreshToken(
            refreshToken: refreshToken,
          );
        }

        if (refreshResult['success'] == true) {
          final newAccessToken = refreshResult['data']?['access_token'] ??
              refreshResult['data']?['accessToken'];
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await TokenStorageService.saveAccessToken(newAccessToken);
            print('✅ Token refreshed successfully using refresh token');
          } else {
            print('❌ No access token in refresh response');
            return {
              'success': false,
              'message': 'Failed to refresh token',
              'error': 'TokenRefreshFailed',
            };
          }
        } else {
          print('❌ Token refresh failed: ${refreshResult['message']}');
          return {
            'success': false,
            'message': refreshResult['message'] ?? 'Failed to refresh token',
            'error': 'TokenRefreshFailed',
          };
        }
      }

      // Get access token (may have been refreshed)
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'No access token found',
          'error': 'Unauthorized',
        };
      }

      // Use authenticated request (which will also handle refresh if needed)
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: loginLinkEndpoint,
        body: null,
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Accept both 200 (OK) and 201 (Created) as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Stripe login link retrieved successfully');
        final data = responseData['data'] ?? responseData;
        final loginUrl = data['loginUrl'] as String?;
        final accountId = data['accountId'] as String?;

        print('🌐 Login URL: $loginUrl');
        print('🆔 Account ID: $accountId');

        return {
          'success': true,
          'data': {
            'loginUrl': loginUrl,
            'accountId': accountId,
          },
          'message':
              responseData['message'] ?? 'Login link generated successfully',
          'statusCode': responseData['statusCode'] ?? response.statusCode,
        };
      } else {
        print('❌ Failed to get Stripe login link');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get login link',
          'error': responseData['error'] ?? 'Unknown error',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error getting Stripe login link: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Verify Stripe account status by attempting to get login link
  /// If login link can be retrieved, account exists and is configured
  /// Returns: { success: bool, data: { isOnboarded: bool, accountId: String } }
  static Future<Map<String, dynamic>> verifyAccountStatus() async {
    try {
      print('💳 === VERIFY STRIPE ACCOUNT STATUS (via login-link) ===');

      // Try to get login link - if successful, account exists and is onboarded
      final loginLinkResult = await getLoginLink();

      if (loginLinkResult['success'] == true) {
        final data = loginLinkResult['data'] as Map<String, dynamic>?;
        final accountId = data?['accountId'] as String?;

        print('✅ Stripe account verified - login link available');
        print('🆔 Account ID: $accountId');

        return {
          'success': true,
          'data': {
            'isOnboarded': true,
            'accountId': accountId,
          },
          'message': 'Account is onboarded and ready',
          'statusCode': 200,
        };
      } else {
        print(
            '⚠️ Stripe account not fully onboarded - login link not available');
        return {
          'success': false,
          'data': {
            'isOnboarded': false,
            'accountId': null,
          },
          'message':
              loginLinkResult['message'] ?? 'Account not fully onboarded',
          'error': loginLinkResult['error'] ?? 'AccountNotReady',
          'statusCode': loginLinkResult['statusCode'] ?? 0,
        };
      }
    } catch (e) {
      print('❌ Error verifying Stripe account status: $e');
      return {
        'success': false,
        'data': {
          'isOnboarded': false,
          'accountId': null,
        },
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }
}
