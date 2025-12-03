import 'dart:convert';
import 'http_interceptor.dart';

class ReportsService {
  Future<Map<String, dynamic>> sendSalonReport(
      {required String message}) async {
    try {
      final trimmed = message.trim();
      // Limit to 100 characters
      final limited =
          trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;

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
        // Handle case where message might be a list (validation errors)
        String errorMessage = 'Failed to submit report';
        if (data['message'] != null) {
          if (data['message'] is List) {
            // Join list of errors into a single string
            errorMessage =
                (data['message'] as List).map((e) => e.toString()).join(', ');
          } else if (data['message'] is String) {
            errorMessage = data['message'];
          }
        } else if (data['error'] != null) {
          if (data['error'] is List) {
            errorMessage =
                (data['error'] as List).map((e) => e.toString()).join(', ');
          } else if (data['error'] is String) {
            errorMessage = data['error'];
          }
        }
        return {
          'success': false,
          'message': errorMessage,
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
      // Limit to 100 characters
      final limited =
          trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;

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
        // Handle case where message might be a list (validation errors)
        String errorMessage = 'Failed to submit report';
        if (data['message'] != null) {
          if (data['message'] is List) {
            // Join list of errors into a single string
            errorMessage =
                (data['message'] as List).map((e) => e.toString()).join(', ');
          } else if (data['message'] is String) {
            errorMessage = data['message'];
          }
        } else if (data['error'] != null) {
          if (data['error'] is List) {
            errorMessage =
                (data['error'] as List).map((e) => e.toString()).join(', ');
          } else if (data['error'] is String) {
            errorMessage = data['error'];
          }
        }
        return {
          'success': false,
          'message': errorMessage,
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
