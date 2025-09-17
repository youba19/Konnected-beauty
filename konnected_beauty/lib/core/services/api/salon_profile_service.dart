import 'dart:convert';
import 'http_interceptor.dart';

class SalonProfileService {
  static const String _baseUrl = 'http://srv950342.hstgr.cloud:3000';

  // Get salon profile
  Future<Map<String, dynamic>> getSalonProfile() async {
    try {
      print('🔍 === GETTING SALON PROFILE ===');

      final url = '$_baseUrl/salon/profile';
      print('🔗 URL: $url');

      // Make request through interceptor using authenticatedRequest
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon/profile',
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Profile fetched successfully');
        print('📊 Profile Data: $responseData');

        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        print('❌ Failed to fetch profile: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to fetch profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error fetching salon profile: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Update salon profile
  Future<Map<String, dynamic>> updateSalonProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? password,
  }) async {
    try {
      print('🔍 === UPDATING SALON PROFILE ===');

      final url = '$_baseUrl/salon';
      print('🔗 URL: $url');

      // Prepare request body with only provided fields
      final requestBody = <String, dynamic>{};

      if (name != null && name.isNotEmpty) {
        requestBody['name'] = name;
      }
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestBody['phoneNumber'] = phoneNumber;
      }
      if (password != null && password.isNotEmpty) {
        requestBody['password'] = password;
      }

      print('🔍 Request body: $requestBody');

      // Make request through interceptor using authenticatedRequest
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'PATCH',
        endpoint: '/salon',
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Profile updated successfully');

        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Profile updated successfully',
        };
      } else {
        print('❌ Failed to update profile: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to update profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error updating salon profile: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
