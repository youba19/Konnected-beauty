import 'dart:convert';
import 'http_interceptor.dart';

class ReportsService {
  Future<Map<String, dynamic>> sendSalonReport(
      {required String message}) async {
    try {
      final trimmed = message.trim();
      final limited =
          trimmed.length > 255 ? trimmed.substring(0, 255) : trimmed;

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/reports/salon',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': limited,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Report submitted successfully',
          'data': data['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit report',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting report: $e',
        'statusCode': 500,
      };
    }
  }

  Future<Map<String, dynamic>> sendInfluencerReport(
      {required String message}) async {
    try {
      final trimmed = message.trim();
      final limited =
          trimmed.length > 255 ? trimmed.substring(0, 255) : trimmed;

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/reports/influencer',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'message': limited}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Report submitted successfully',
          'data': data['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit report',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting report: $e',
        'statusCode': 500,
      };
    }
  }

  /// Request account deletion for salon using existing report endpoint
  Future<Map<String, dynamic>> requestSalonAccountDeletion({
    required String reason,
  }) async {
    try {
      print('🗑️ === REQUEST SALON ACCOUNT DELETION ===');
      print('📝 Reason: $reason');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/reports/salon',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': 'ACCOUNT_DELETION_REQUEST: $reason',
          'type': 'account_deletion_request',
        }),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ??
              'Account deletion request submitted successfully',
          'data': data['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              data['message'] ?? 'Failed to submit account deletion request',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in requestSalonAccountDeletion: $e');
      return {
        'success': false,
        'message': 'Error submitting account deletion request: $e',
        'statusCode': 500,
      };
    }
  }

  /// Request account deletion for influencer using existing report endpoint
  Future<Map<String, dynamic>> requestInfluencerAccountDeletion({
    required String reason,
  }) async {
    try {
      print('🗑️ === REQUEST INFLUENCER ACCOUNT DELETION ===');
      print('📝 Reason: $reason');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/reports/influencer',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': 'ACCOUNT_DELETION_REQUEST: $reason',
          'type': 'account_deletion_request',
        }),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ??
              'Account deletion request submitted successfully',
          'data': data['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              data['message'] ?? 'Failed to submit account deletion request',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in requestInfluencerAccountDeletion: $e');
      return {
        'success': false,
        'message': 'Error submitting account deletion request: $e',
        'statusCode': 500,
      };
    }
  }
}
