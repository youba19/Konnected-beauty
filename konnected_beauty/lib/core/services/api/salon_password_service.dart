import 'dart:convert';
import 'http_interceptor.dart';

class SalonPasswordService {
  // Change salon password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('🔍 === CHANGING SALON PASSWORD ===');
      
      // Prepare request body
      final requestBody = {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      print('🔍 Request body: $requestBody');

      // Make request through interceptor using authenticatedRequest
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/salon/change-password',
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Password changed successfully');
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Password changed successfully',
        };
      } else {
        print('❌ Failed to change password: ${response.statusCode}');
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to change password: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error changing salon password: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
