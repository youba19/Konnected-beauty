import 'dart:convert';
import 'http_interceptor.dart';
import '../storage/token_storage_service.dart';

class InviteSalonService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  /// Invite salon for campaign
  static Future<Map<String, dynamic>> inviteSalon({
    required String receiverId,
    required int promotion,
    required String promotionType,
    required String invitationMessage,
  }) async {
    try {
      print('📧 === INVITING SALON FOR CAMPAIGN ===');
      print('📧 Receiver ID: $receiverId');
      print('📧 Promotion: $promotion');
      print('📧 Promotion Type: $promotionType');
      print('📧 Message: $invitationMessage');

      // Check authentication status before making request
      final token = await TokenStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        print('❌ No authentication token found');
        return {
          'success': false,
          'message': 'Authentication required',
          'statusCode': 401,
        };
      }

      print('🔑 Token found: ${token.substring(0, 20)}...');

      final requestBody = {
        'receiverId': receiverId,
        'promotion': promotion,
        'promotionType': promotionType,
        'invitationMessage': invitationMessage,
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/invite-salon',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Invitation sent successfully');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Invitation sent successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = json.decode(response.body);
        print('❌ Failed to send invitation: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to send invitation',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in inviteSalon: $e');
      return {
        'success': false,
        'message': 'Error sending invitation: ${e.toString()}',
        'statusCode': 500,
      };
    }
  }
}
