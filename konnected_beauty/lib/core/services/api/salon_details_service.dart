import 'dart:convert';
import 'http_interceptor.dart';
import '../storage/token_storage_service.dart';

class SalonDetailsService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  /// Fetch salon details by ID
  static Future<Map<String, dynamic>> getSalonDetails(String salonId,
      {String? salonName, String? salonDomain, String? salonAddress}) async {
    try {
      print('🏢 === FETCHING SALON DETAILS ===');
      print('🏢 Salon ID: $salonId');

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
        endpoint: '/salon/details/$salonId',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🌐 === HTTP RESPONSE RECEIVED ===');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Salon details fetched successfully');
        print('📊 Response Data: $responseData');

        // Parse the salon details data
        final salonData = responseData['data'] ?? {};
        final salonInfo = salonData['salonInfo'] as Map<String, dynamic>?;
        final salonProfile = salonData['salonProfile'] as Map<String, dynamic>?;
        final services = salonData['services'] as List<dynamic>? ?? [];
        final pictures = salonProfile?['pictures'] as List<dynamic>? ?? [];

        final processedSalonDetails = {
          'id': salonData['id'],
          'name': salonInfo?['name'] ?? salonName ?? 'Salon Name',
          'domain': salonInfo?['domain'] ?? salonDomain ?? 'salon.domain',
          'address': salonInfo?['address'] ?? salonAddress ?? 'Salon Address',
          'openingHour': salonProfile?['openingHour'],
          'closingHour': salonProfile?['closingHour'],
          'description': salonProfile?['description'] ??
              'The best salon in Europe and especially in PARIS',
          'pictures': pictures,
          'services': services,
          'averageRating': (salonData['averageRating'] ?? 0).toDouble(),
          'totalRatings': salonData['totalRatings'] ?? 0,
          'salonInfo': salonInfo,
          'salonProfile': salonProfile,
        };

        print('📊 Processed Salon Details:');
        print('📊 Name: ${processedSalonDetails['name']}');
        print('📊 Domain: ${processedSalonDetails['domain']}');
        print('📊 Address: ${processedSalonDetails['address']}');
        print('📊 Description: ${processedSalonDetails['description']}');
        print('📊 Pictures Count: ${pictures.length}');
        print('📊 Services Count: ${services.length}');
        print('📊 Services: ${services.map((s) => s['name']).join(', ')}');
        print('📊 Average Rating: ${processedSalonDetails['averageRating']}');
        print('📊 Total Ratings: ${processedSalonDetails['totalRatings']}');

        return {
          'success': true,
          'data': processedSalonDetails,
          'message':
              responseData['message'] ?? 'Salon details fetched successfully',
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to fetch salon details: ${response.statusCode}');
        print('❌ Response Body: ${response.body}');

        return {
          'success': false,
          'message': 'Failed to fetch salon details',
          'statusCode': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e) {
      print('❌ Error fetching salon details: $e');
      return {
        'success': false,
        'message': 'Error fetching salon details: $e',
        'error': e.toString(),
      };
    }
  }
}
