import 'dart:convert';
import 'package:http/http.dart' as http;

class SalonAuthService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  // Signup endpoint
  static const String signupEndpoint = '/salon-auth/signup';

  // OTP validation endpoint
  static const String validateOtpEndpoint = '/salon-auth/validate-otp';

  // Resend OTP endpoint
  static const String resendOtpEndpoint = '/salon-auth/resend-otp';

  // Login endpoint
  static const String loginEndpoint = '/salon-auth/login';

  // Refresh token endpoint
  static const String refreshTokenEndpoint = '/salon-auth/refresh-token';

  // Headers for API requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  /// Helper method to format message (handle both string and list cases)
  static String formatMessage(dynamic message) {
    if (message == null) return '';
    if (message is String) return message;
    if (message is List) {
      return message.join(', ');
    }
    return message.toString();
  }

  /// Signup a new salon
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$signupEndpoint'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'phoneNumber': phoneNumber,
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': formatMessage(responseData['message']) ?? 'Signup failed',
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Validate OTP
  static Future<Map<String, dynamic>> validateOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$validateOtpEndpoint'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message':
              formatMessage(responseData['message']) ?? 'OTP validation failed',
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Resend OTP
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$resendOtpEndpoint'),
        headers: headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'statusCode': responseData['statusCode'],
        };
      } else {
        // Handle specific error cases
        String userMessage =
            formatMessage(responseData['message']) ?? 'Failed to resend OTP';

        // If the salon is already verified, show a more helpful message
        if (response.statusCode == 409 &&
            userMessage.toLowerCase().contains('already verified')) {
          userMessage =
              'Your account is already verified. You can proceed to the next step.';
        }

        return {
          'success': false,
          'message': userMessage,
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Login salon
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': formatMessage(responseData['message']) ?? 'Login failed',
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Refresh access token
  static Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$refreshTokenEndpoint'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $refreshToken',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message':
              formatMessage(responseData['message']) ?? 'Token refresh failed',
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }
}
