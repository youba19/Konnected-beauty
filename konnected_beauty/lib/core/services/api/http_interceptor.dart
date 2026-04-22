import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage_service.dart';
import 'influencer_auth_service.dart';
import 'salon_auth_service.dart';
import '../../config/api_base_url.dart';

class HttpInterceptor {
  static String get baseUrl => ApiBaseUrl.value;

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

        // Check if the refresh token itself is expired
        final isRefreshTokenExpired =
            await TokenStorageService.isRefreshTokenExpired();

        if (isRefreshTokenExpired) {
          print('❌ Refresh token is also expired, clearing auth data');
          // Only clear tokens if refresh token is expired (user needs to login again)
          await _clearExpiredTokens();
        } else {
          // If refresh token is still valid but refresh failed (network error, etc.),
          // don't clear tokens immediately - let the user retry
          print(
              '⚠️ Refresh token still valid, but refresh failed. This might be a temporary network issue.');
          print('⚠️ Not clearing tokens to avoid unnecessary logout.');
        }

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
    Map<String, dynamic>? queryParameters,
  }) async {
    print('🔐 === AUTHENTICATED REQUEST ===');
    print('🔗 Method: $method');
    print('🔗 Endpoint: $endpoint');
    print('🔗 Query Parameters: $queryParameters');
    print('🔗 Query Parameters Type: ${queryParameters.runtimeType}');
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
      if (ApiBaseUrl.useDevTunnel) {
        requestHeaders.putIfAbsent(
          'ngrok-skip-browser-warning',
          () => 'true',
        );
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
        print('✅ Authorization header added');
      } else {
        print('❌ No access token available - request will fail with 401');
      }

      // Handle query parameters, including array parameters like serviceIds[]
      String queryString = '';
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final List<String> queryParts = [];

        queryParameters.forEach((key, value) {
          if (key.endsWith('[]')) {
            // Handle array parameters - add multiple entries for the same key
            if (value is List) {
              for (final item in value) {
                queryParts.add(
                    '${Uri.encodeComponent(key)}=${Uri.encodeComponent(item.toString())}');
              }
            } else {
              queryParts.add(
                  '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}');
            }
          } else {
            queryParts.add(
                '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}');
          }
        });

        queryString = '?' + queryParts.join('&');
      }

      final uri = Uri.parse('$baseUrl$endpoint$queryString');

      print('🔗 Full URL: $uri');
      print('🔗 Query Parameters in Interceptor: $queryParameters');
      print('🔗 Query Parameters Type: ${queryParameters.runtimeType}');
      print('🔗 URL Query String: ${uri.query}');
      print('🔗 URL Query Parameters: ${uri.queryParameters}');
      print('🔗 Search Parameter in URL: ${uri.queryParameters['search']}');
      print('🔗 Expected Format: status=pending&page=1&limit=100 (in body)');
      print('🔗 Actual URL: $uri');

      // Log request headers for GET requests with query parameters (like reports filter)
      if (method == 'GET' &&
          queryParameters != null &&
          queryParameters.isNotEmpty) {
        print('═══════════════════════════════════════════════════════');
        print('📤 === REQUEST DETAILS (GET with Query Params) ===');
        print('═══════════════════════════════════════════════════════');
        print('🔗 Method: $method');
        print('🔗 Endpoint: $endpoint');
        print('🔗 Full URL: $uri');
        print('📋 Request Headers:');
        requestHeaders.forEach((key, value) {
          if (key == 'Authorization') {
            print('   • $key: ${value.substring(0, 20)}...');
          } else {
            print('   • $key: $value');
          }
        });
        print('📋 Query Parameters:');
        queryParameters.forEach((key, value) {
          print('   • $key: $value');
        });
        print('📋 Query String: ${uri.query}');
        print('═══════════════════════════════════════════════════════');
        print('');
      }

      // Convert body based on content type
      Object? requestBody = body;
      if (body is Map<String, dynamic>) {
        if (requestHeaders['Content-Type']?.contains('application/json') ==
            true) {
          requestBody = jsonEncode(body);
          print('📤 Body converted to JSON: $requestBody');
        } else if (requestHeaders['Content-Type']
                ?.contains('application/x-www-form-urlencoded') ==
            true) {
          // Convert to form data
          final formData = body.entries
              .map((e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
              .join('&');
          requestBody = formData;
          print('📤 Body converted to form data: $requestBody');
        }
      }

      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(uri, headers: requestHeaders);
        case 'POST':
          return await http.post(uri,
              headers: requestHeaders, body: requestBody);
        case 'PUT':
          return await http.put(uri,
              headers: requestHeaders, body: requestBody);
        case 'DELETE':
          return await http.delete(uri,
              headers: requestHeaders, body: requestBody);
        case 'PATCH':
          return await http.patch(uri,
              headers: requestHeaders, body: requestBody);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    });
  }

  /// Register FCM token for notifications
  /// This should be called after successful login
  static Future<Map<String, dynamic>> registerFCMToken({
    required String token,
    required String userRole,
  }) async {
    try {
      print('📱 === REGISTERING FCM TOKEN ===');
      print('👤 User Role: $userRole');
      print('🔑 FCM Token: ${token.substring(0, 20)}...');

      // Determine which endpoint to use based on user role
      String endpoint;
      if (userRole == 'influencer') {
        endpoint = '/influencer-notification/register-token';
      } else if (userRole == 'saloon' || userRole == 'salon') {
        endpoint = '/salon-notification/register-token';
      } else {
        return {
          'success': false,
          'message': 'Invalid user role: $userRole',
        };
      }

      print('🔗 Endpoint: $endpoint');

      // Make the request using authenticatedRequest
      final response = await authenticatedRequest(
        method: 'POST',
        endpoint: endpoint,
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'token': token,
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          print('✅ FCM token registered successfully');
          return {
            'success': true,
            'message': 'FCM token registered successfully',
            'data': responseData,
          };
        } catch (e) {
          print('⚠️ Could not parse response, but status is success');
          return {
            'success': true,
            'message': 'FCM token registered successfully',
          };
        }
      } else {
        print('❌ Failed to register FCM token: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to register FCM token',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error registering FCM token: $e');
      return {
        'success': false,
        'message': 'Error registering FCM token: ${e.toString()}',
      };
    }
  }
}
