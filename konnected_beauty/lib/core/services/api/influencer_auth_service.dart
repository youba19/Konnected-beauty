import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_interceptor.dart';

class InfluencerAuthService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  /// Helper method to format message (handle both string and list cases)
  static String formatMessage(dynamic message) {
    if (message == null) return '';
    if (message is String) return message;
    if (message is List) {
      return message.join(', ');
    }
    return message.toString();
  }

  /// Login influencer using exact same logic as salon login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('🎯 Using http package with proper headers');

    try {
      print('🔐 === LOGIN REQUEST ===');
      print('🔗 URL: $baseUrl/influencer-auth/login');
      print('📧 Email (original): $email');
      final normalizedEmail = email.trim().toLowerCase();
      print('📧 Email (normalized): $normalizedEmail');
      print('🔑 Password: ${'*' * password.length}');
      print('🕐 Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
      print('📦 Request Body: ${jsonEncode({
            'email': normalizedEmail,
            'password': password
          })}');

      // Use proper headers that match curl
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/login'),
        headers: requestHeaders,
        body: jsonEncode({
          'email': normalizedEmail,
          'password': password,
        }),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      // SHOW RAW API RESPONSE DIRECTLY
      print('🎯 === RAW API RESPONSE FROM LOGIN ===');
      print('🎯 Status Code: ${response.statusCode}');
      print('🎯 Raw Response: ${response.body}');
      print('🎯 === END RAW API RESPONSE ===');

      // SHOW STATUS DIRECTLY FROM API RESPONSE
      print('🎯 === STATUS FROM API RESPONSE ===');
      print('🎯 Full Response Data: $responseData');
      print('🎯 Status Field: ${responseData['data']?['status']}');
      print('🎯 Status Type: ${responseData['data']?['status']?.runtimeType}');
      print(
          '🎯 Status Length: ${responseData['data']?['status']?.toString().length}');
      print('🎯 === END STATUS ===');

      if (response.statusCode == 200) {
        print('✅ Login Success');
        print('📊 Response Data: $responseData');
        print('📦 Data Object: ${responseData['data']}');
        print('👤 User Object: ${responseData['data']['user']}');
        print(
            '🔍 Status from user object: ${responseData['data']['user']?['status']}');
        print('🔍 Status from data object: ${responseData['data']['status']}');
        print('🔍 Raw status value: "${responseData['data']['status']}"');
        print('🔍 Status type: ${responseData['data']['status'].runtimeType}');
        print(
            '🔑 Access Token: ${responseData['data']['access_token'] != null ? responseData['data']['access_token'].substring(0, 50) + '...' : 'NULL'}');
        print(
            '🔄 Refresh Token: ${responseData['data']['refresh_token'] != null ? responseData['data']['refresh_token'].substring(0, 50) + '...' : 'NULL'}');
        print(
            '👤 User Status: ${responseData['data']['user']?['status'] ?? 'NULL'}');
        print('🔐 === END LOGIN REQUEST ===');

        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ Login Failed');
        print('📊 Error Response: $responseData');
        print('🔐 === END LOGIN REQUEST ===');

        return {
          'success': false,
          'message': formatMessage(responseData['message']),
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 Login Exception: $e');
      print('🔐 === END LOGIN REQUEST ===');

      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  // Signup
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // Validate inputs
    if (name.trim().isEmpty) {
      return {'success': false, 'message': 'Name is required'};
    }
    if (email.trim().isEmpty) {
      return {'success': false, 'message': 'Email is required'};
    }
    if (phone.trim().isEmpty) {
      return {'success': false, 'message': 'Phone is required'};
    }
    if (password.trim().isEmpty) {
      return {'success': false, 'message': 'Password is required'};
    }
    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters'
      };
    }

    // Try different phone number formats
    String formattedPhone = phone.trim();
    // Remove any non-digit characters except +
    formattedPhone = formattedPhone.replaceAll(RegExp(r'[^\d+]'), '');

    // If no + prefix, add it
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }

    // Alternative: try without + if the above fails
    String alternativePhone = phone.trim().replaceAll(RegExp(r'[^\d]'), '');
    try {
      // Try different phone number formats - start with the most common
      final requestBody = {
        'name': name.trim(),
        'phoneNumber': alternativePhone, // Try without + first
        'email': email.trim(),
        'password': password,
      };

      // Alternative request body with + prefix
      final alternativeRequestBody = {
        'name': name.trim(),
        'phoneNumber': formattedPhone, // With +
        'email': email.trim(),
        'password': password,
      };

      // Try with 'phone' instead of 'phoneNumber'
      final phoneFieldRequestBody = {
        'name': name.trim(),
        'phone': alternativePhone, // Without +
        'email': email.trim(),
        'password': password,
      };

      print('=== INFLUENCER SIGNUP DEBUG ===');
      print('URL: $baseUrl/influencer-auth/signup');
      print('Request Body (phoneNumber with +): ${jsonEncode(requestBody)}');
      print(
          'Alternative Body (phoneNumber no +): ${jsonEncode(alternativeRequestBody)}');
      print(
          'Phone Field Body (phone with +): ${jsonEncode(phoneFieldRequestBody)}');
      print('Phone Original: "$phone"');
      print('Phone Formatted (with +): "$formattedPhone"');
      print('Phone Alternative (no +): "$alternativePhone"');
      print('===============================');

      // Try the first format (without +)
      var response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // If first attempt fails with phone validation error, try with + prefix
      if (response.statusCode == 400) {
        final responseBody = response.body;
        if (responseBody.contains('phoneNumber must be a valid phone number')) {
          print('First attempt failed, trying with + prefix...');
          response = await http.post(
            Uri.parse('$baseUrl/influencer-auth/signup'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(alternativeRequestBody),
          );
        }
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        print('Signup API Success Response: $responseBody');
        print('Response Body Type: ${responseBody.runtimeType}');

        // If the API doesn't have a 'success' field, add it
        if (responseBody is Map<String, dynamic>) {
          if (!responseBody.containsKey('success')) {
            responseBody['success'] = true;
          }
        }

        return responseBody;
      } else {
        // Get the error response body for better debugging
        final errorBody = response.body;
        print('Signup API Error Response: $errorBody');
        print('Signup API Status Code: ${response.statusCode}');
        print('Signup API Request Body: ${jsonEncode({
              'name': name.trim(),
              'phoneNumber': formattedPhone,
              'email': email.trim(),
              'password': password,
            })}');

        // Try to parse error response
        try {
          final errorData = jsonDecode(errorBody);
          return errorData; // Return the error response so bloc can handle it
        } catch (e) {
          return {
            'success': false,
            'message': 'Signup failed: ${response.statusCode} - $errorBody'
          };
        }
      }
    } catch (e) {
      throw Exception('Signup error: $e');
    }
  }

  // Validate OTP
  static Future<Map<String, dynamic>> validateOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/validate-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to validate OTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('OTP validation error: $e');
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/resend-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to resend OTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Resend OTP error: $e');
    }
  }

  /// Add profile information
  static Future<Map<String, dynamic>> addProfile({
    required String pseudo,
    required String bio,
    required String zone,
    String? profilePicture,
  }) async {
    print('🔐 === ADD PROFILE DEBUG ===');
    print('🔗 URL: $baseUrl/influencer/add-profile');
    print('👤 Pseudo: $pseudo');
    print('📝 Bio: $bio');
    print('📍 Zone: $zone');
    print('🖼️ Profile Picture: $profilePicture');

    try {
      final requestBody = {
        "pseudo": pseudo,
        "bio": bio,
        "zone": zone,
        if (profilePicture != null) "profilePicture": profilePicture,
      };

      print('📦 Request Body: ${jsonEncode(requestBody)}');

      // Use HTTP interceptor for automatic token refresh
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/influencer/add-profile',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Profile added successfully: $responseData');
        return responseData;
      } else {
        print('❌ Profile addition failed with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to add profile: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in addProfile: $e');
      return {
        'success': false,
        'message': 'Error adding profile: $e',
        'statusCode': 0,
      };
    }
  }

  // Add Socials
  static Future<Map<String, dynamic>> addSocials({
    required List<Map<String, String>> socials,
  }) async {
    try {
      print('🔐 === ADDING SOCIALS ===');
      print('📱 Socials: $socials');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/influencer/add-socials',
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "socials": socials,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add socials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Add socials error: $e');
    }
  }
}
