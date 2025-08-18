import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage_service.dart';

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

      // Call the appropriate refresh token endpoint
      final response = await http.post(
        Uri.parse('$baseUrl$refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      final responseData = jsonDecode(response.body);
      print('📊 Refresh response data: $responseData');

      if (response.statusCode == 200) {
        // Extract new tokens from response (API uses snake_case)
        final newAccessToken =
            responseData['access_token'] ?? responseData['accessToken'];
        final newRefreshToken =
            responseData['refresh_token'] ?? responseData['refreshToken'];

        if (newAccessToken != null) {
          // Store the new access token
          await TokenStorageService.saveAccessToken(newAccessToken);

          // If a new refresh token is provided, store it too
          if (newRefreshToken != null) {
            await TokenStorageService.saveRefreshToken(newRefreshToken);
          }

          print('✅ Token refreshed and stored successfully');
          return {
            'success': true,
            'message': 'Token refreshed successfully',
            'accessToken': newAccessToken,
          };
        } else {
          return {
            'success': false,
            'message': 'No access token in refresh response',
            'error': 'NoAccessTokenInResponse',
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Token refresh failed',
          'error': responseData['error'],
          'statusCode': response.statusCode,
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
    return interceptRequest(() async {
      final accessToken = await TokenStorageService.getAccessToken();

      final requestHeaders = Map<String, String>.from(headers ?? {});
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }

      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParameters);

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
