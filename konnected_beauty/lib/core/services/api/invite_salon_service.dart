import 'dart:convert';
import 'http_interceptor.dart';
import '../storage/token_storage_service.dart';
import '../../config/api_base_url.dart';
import '../../utils/stripe_link_error.dart';

class InviteSalonService {
  static String get baseUrl => ApiBaseUrl.value;

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
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        // Some APIs return HTTP 200 with an error payload (e.g. statusCode 499 in body).
        final bodyCode = StripeLinkError.parseStatusCode(responseData['statusCode']);
        final bodyMessage = StripeLinkError.messageFrom(responseData);
        if (bodyCode == 499 ||
            StripeLinkError.isAccountNotLinked(bodyMessage, bodyCode)) {
          print('❌ Invite blocked: Stripe account not linked (body)');
          return {
            'success': false,
            'message': bodyMessage.isNotEmpty
                ? bodyMessage
                : 'Stripe account id not linked',
            'statusCode': bodyCode ?? 499,
            'stripeAccountNotLinked': true,
          };
        }
        print('✅ Invitation sent successfully');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Invitation sent successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final errorData =
            json.decode(response.body) as Map<String, dynamic>;
        final msg = StripeLinkError.messageFrom(errorData);
        final bodyCode = StripeLinkError.parseStatusCode(errorData['statusCode']);
        final effectiveCode = bodyCode ?? response.statusCode;
        final stripeNotLinked = effectiveCode == 499 ||
            StripeLinkError.isAccountNotLinked(msg, effectiveCode);
        print('❌ Failed to send invitation: $msg');
        return {
          'success': false,
          'message': msg.isNotEmpty ? msg : 'Failed to send invitation',
          'statusCode': effectiveCode,
          'stripeAccountNotLinked': stripeNotLinked,
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
