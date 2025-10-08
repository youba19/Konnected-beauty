import 'dart:convert';
import 'http_interceptor.dart';
import '../storage/token_storage_service.dart';

class SaloonsService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  /// Fetch all saloons with search and pagination
  static Future<Map<String, dynamic>> getSaloons({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('🏢 === FETCHING SALOONS ===');
      print('📄 Page: $page');
      print('📏 Limit: $limit');
      print('🔍 Search: "${search ?? 'None'}"');

      // Build query parameters
      final queryParams = <String, dynamic>{};
      queryParams['page'] = page;
      queryParams['limit'] = limit;

      if (search != null && search.isNotEmpty) {
        queryParams['domain'] =
            search; // Use 'domain' parameter as per API spec
      }

      print('🔗 Query Parameters: $queryParams');

      // Check authentication status before making request
      print('🔐 === CHECKING AUTH STATUS BEFORE REQUEST ===');
      final accessToken = await TokenStorageService.getAccessToken();
      final refreshToken = await TokenStorageService.getRefreshToken();
      final userRole = await TokenStorageService.getUserRole();
      final userEmail = await TokenStorageService.getUserEmail();
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'NULL'}');
      print('🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'NULL'}');
      print('👤 User Role: $userRole');
      print('📧 User Email: $userEmail');
      print('🔐 === END AUTH STATUS CHECK ===');

      // Make request through interceptor
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('🌐 === HTTP RESPONSE RECEIVED ===');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Saloons fetched successfully');
        print('📊 Response Data: $responseData');

        // Parse the saloons data with proper structure
        final List<dynamic> rawSaloons = responseData['data'] ?? [];
        final List<Map<String, dynamic>> processedSaloons =
            rawSaloons.map((salon) {
          final salonInfo = salon['salonInfo'] as Map<String, dynamic>? ?? {};
          final salonProfile =
              salon['salonProfile'] as Map<String, dynamic>? ?? {};
          final services = salon['services'] as List<dynamic>? ?? [];

          return {
            'id': salon['id'],
            'createdAt': salon['createdAt'],
            'name': salonInfo['name'] ?? 'Unknown Salon',
            'domain': salonInfo['domain'] ?? 'Unknown Domain',
            'address': salonInfo['address'] ?? 'Unknown Address',
            'openingHour': salonProfile['openingHour'],
            'closingHour': salonProfile['closingHour'],
            'description': salonProfile['description'],
            'services': services,
            'salonInfo': salonInfo,
            'salonProfile': salonProfile,
          };
        }).toList();

        print('📊 Processed Saloons: ${processedSaloons.length}');
        for (int i = 0; i < processedSaloons.length; i++) {
          final salon = processedSaloons[i];
          final salonServices = salon['services'] as List<dynamic>? ?? [];
          print(
              '📊 Salon ${i + 1}: ${salon['name']} - ${salon['domain']} - ${salon['address']}');
          print(
              '📊 Services (${salonServices.length}): ${salonServices.map((s) => s['name']).join(', ')}');
        }

        return {
          'success': true,
          'data': processedSaloons,
          'message': responseData['message'] ?? 'Saloons fetched successfully',
          'statusCode': response.statusCode,
          'total': responseData['total'] ?? 0,
          'totalPages': responseData['totalPages'] ?? 1,
          'currentPage': responseData['currentPage'] ?? 1,
        };
      } else {
        print('❌ Failed to fetch saloons: ${response.statusCode}');
        print('❌ Response Body: ${response.body}');

        return {
          'success': false,
          'message': 'Failed to fetch saloons',
          'statusCode': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e) {
      print('❌ Error fetching saloons: $e');
      return {
        'success': false,
        'message': 'Error fetching saloons: $e',
        'error': e.toString(),
      };
    }
  }

  /// Fetch saloon services for a specific saloon
  static Future<Map<String, dynamic>> getSaloonServices(String saloonId) async {
    try {
      print('🔧 === FETCHING SALOON SERVICES ===');
      print('🏢 Saloon ID: $saloonId');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon/$saloonId/services',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Saloon services fetched successfully');

        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'message': responseData['message'] ?? 'Services fetched successfully',
        };
      } else {
        print('❌ Failed to fetch saloon services: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to fetch saloon services',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error fetching saloon services: $e');
      return {
        'success': false,
        'message': 'Error fetching saloon services: $e',
        'error': e.toString(),
      };
    }
  }
}
