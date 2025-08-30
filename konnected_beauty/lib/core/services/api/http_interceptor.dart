import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage_service.dart';
import 'influencer_auth_service.dart';
import 'salon_auth_service.dart';

class HttpInterceptor {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  /// Intercept HTTP requests and automatically handle token refresh
  static Future<http.Response> interceptRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      print('🔍 HTTP Interceptor: Making initial request...');

      // Make the initial request
      final response = await request();

      print('🔍 HTTP Interceptor: Response status: ${response.statusCode}');

      // If the request is successful, return the response
      if (response.statusCode != 401) {
        print('🔍 HTTP Interceptor: Request successful, returning response');
        return response;
      }

      // If we get 401, try to refresh the token
      print('🔄 Token expired, attempting to refresh...');
      final refreshResult = await _refreshToken();

      if (!refreshResult['success']) {
        print('❌ Token refresh failed: ${refreshResult['message']}');
        // If refresh fails, we should clear the tokens and redirect to login
        await _clearExpiredTokens();
        return response; // Return the original 401 response
      }

      // Token refreshed successfully, retry the original request
      print(
          '✅ HTTP Interceptor: Token refreshed successfully, retrying request...');
      final retryResponse = await request();
      print(
          '🔍 HTTP Interceptor: Retry response status: ${retryResponse.statusCode}');
      return retryResponse;
    } catch (e) {
      print('❌ HTTP Interceptor error: $e');
      rethrow;
    }
  }

  /// Refresh the access token using the stored refresh token
  static Future<Map<String, dynamic>> _refreshToken() async {
    try {
      final refreshToken = await TokenStorageService.getRefreshToken();
      final userRole = await TokenStorageService.getUserRole();

      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No refresh token available for refresh');
        return {
          'success': false,
          'message': 'No refresh token available',
          'error': 'NoRefreshToken',
        };
      }

      // Determine which refresh endpoint to use based on user role
      String refreshEndpoint;
      if (userRole == 'influencer') {
        refreshEndpoint = '/influencer-auth/refresh-token';
      } else {
        refreshEndpoint = '/salon-auth/refresh-token';
      }

      print(
          '🔄 Refreshing token for role: $userRole using endpoint: $refreshEndpoint');

      // Call the appropriate refresh token endpoint using the service
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

      print('📊 Refresh result: $refreshResult');

      if (refreshResult['success'] == true) {
        // Extract new tokens from response (API uses snake_case)
        final newAccessToken = refreshResult['data']?['access_token'] ??
            refreshResult['data']?['accessToken'];
        final newRefreshToken = refreshResult['data']?['refresh_token'] ??
            refreshResult['data']?['refreshToken'];

        print('🔍 === TOKEN EXTRACTION DEBUG ===');
        print('🔍 Refresh Result: $refreshResult');
        print('🔍 Data Object: ${refreshResult['data']}');
        print(
            '🔍 Access Token from data.access_token: ${refreshResult['data']?['access_token']}');
        print(
            '🔍 Access Token from data.accessToken: ${refreshResult['data']?['accessToken']}');
        print('🔍 Final Access Token: $newAccessToken');
        print('🔍 === END TOKEN EXTRACTION ===');

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Store the new access token
          await TokenStorageService.saveAccessToken(newAccessToken);

          // If a new refresh token is provided, store it too
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await TokenStorageService.saveRefreshToken(newRefreshToken);
          }

          print('✅ Token refreshed and stored successfully');
          return {
            'success': true,
            'message': 'Token refreshed successfully',
            'accessToken': newAccessToken,
          };
        } else {
          print('❌ No valid access token found in refresh response');
          print('❌ Response structure: $refreshResult');
          return {
            'success': false,
            'message': 'No access token in refresh response',
            'error': 'NoAccessTokenInResponse',
          };
        }
      } else {
        return {
          'success': false,
          'message': refreshResult['message'] ?? 'Token refresh failed',
          'error': refreshResult['error'],
          'statusCode': refreshResult['statusCode'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Token refresh error: ${e.toString()}',
        'error': 'RefreshError',
      };
    }
  }

  /// Clear expired tokens when refresh fails
  static Future<void> _clearExpiredTokens() async {
    try {
      await TokenStorageService.clearAuthData();
      print('🗑️ Expired tokens cleared');
    } catch (e) {
      print('❌ Error clearing tokens: $e');
    }
  }

  /// Helper method to make authenticated requests with automatic token refresh
  static Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    print('🔐 === AUTHENTICATED REQUEST ===');
    print('🔗 Method: $method');
    print('🔗 Endpoint: $endpoint');
    print('🔗 Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    return interceptRequest(() async {
      final accessToken = await TokenStorageService.getAccessToken();
      final userRole = await TokenStorageService.getUserRole();
      final userEmail = await TokenStorageService.getUserEmail();

      print('🔐 === TOKEN INFO ===');
      print(
          '🔑 Access Token: ${accessToken != null ? '${accessToken.substring(0, 20)}...' : 'NULL'}');
      print('👤 User Role: $userRole');
      print('📧 User Email: $userEmail');
      print('🔐 === END TOKEN INFO ===');

      final requestHeaders = Map<String, String>.from(headers ?? {});
      if (accessToken != null && accessToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
        print('✅ Authorization header added');
      } else {
        print('❌ No access token available - request will fail with 401');
      }

      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParameters);

      print('🔗 Full URL: $uri');

      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(uri, headers: requestHeaders);
        case 'POST':
          return await http.post(uri, headers: requestHeaders, body: body);
        case 'PUT':
          return await http.put(uri, headers: requestHeaders, body: body);
        case 'DELETE':
          return await http.delete(uri, headers: requestHeaders);
        case 'PATCH':
          return await http.patch(uri, headers: requestHeaders, body: body);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    });
  }
}
