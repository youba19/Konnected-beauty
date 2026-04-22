import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../storage/token_storage_service.dart';
import 'http_interceptor.dart';

class InfluencerAuthService {
  static const String baseUrl = 'https://server.konectedbeauty.com';

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
    print('🔐 === VALIDATING OTP ===');
    print('📧 Email: $email');
    print('🔢 OTP: $otp');
    print('🔗 URL: $baseUrl/influencer-auth/validate-otp');

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

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ OTP validation successful');
        print('📊 Response data: $responseData');

        // Check if tokens are present in response
        if (responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          final accessToken = data['access_token'];
          final refreshToken = data['refresh_token'];

          print(
              '🔑 Access Token in response: ${accessToken != null ? "Present" : "Missing"}');
          print(
              '🔄 Refresh Token in response: ${refreshToken != null ? "Present" : "Missing"}');
      } else {
          print('⚠️ No data field in OTP response');
        }

        return responseData;
      } else {
        print('❌ OTP validation failed with status: ${response.statusCode}');
        print('🔍 Error response: ${response.body}');
        throw Exception(
            'Failed to validate OTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in validateOtp: $e');
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

  /// Refresh access token using refresh token
  static Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    print('🔄 === REFRESH TOKEN REQUEST ===');
    print('🔗 URL: $baseUrl/influencer-auth/refresh-token');
    print('🔄 Refresh Token: ${refreshToken.substring(0, 20)}...');
    print('🔄 Full Refresh Token: $refreshToken');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Token refreshed successfully');
        return {
          'success': true,
          'message': 'Token refreshed successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        print('❌ Token refresh failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        print('❌ Error message: ${responseData['message']}');
        print('❌ Error details: ${responseData['error']}');
        print('❌ Full response data: $responseData');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Token refresh failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in refreshToken: $e');
      return {
        'success': false,
        'message': 'Error refreshing token: $e',
        'statusCode': 0,
      };
    }
  }

  /// Add profile information
  static Future<Map<String, dynamic>> addProfile({
    required String pseudo,
    required String bio,
    required String zone,
    File? profilePicture,
  }) async {
    print('🔐 === ADD PROFILE DEBUG ===');
    print('🔗 URL: $baseUrl/influencer/add-profile');
    print('👤 Pseudo: $pseudo');
    print('📝 Bio: $bio');
    print('📍 Zone: $zone');
    print('🖼️ Profile Picture: $profilePicture');

    try {
      print('🔍 Preparing multipart request for add influencer profile');
      print('🔍 Profile picture: ${profilePicture ?? 'None'}');

      // Check if token is expired and refresh if needed
      print('🔍 === TOKEN EXPIRY CHECK ===');

      // Debug: Check what tokens are available
      final storedAccessToken = await TokenStorageService.getAccessToken();
      final storedRefreshToken = await TokenStorageService.getRefreshToken();
      print(
          '🔍 Stored access token: ${storedAccessToken != null ? "Present" : "Missing"}');
      print(
          '🔍 Stored refresh token: ${storedRefreshToken != null ? "Present" : "Missing"}');

      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔍 Access token expired: $isExpired');

      if (isExpired) {
        print('⚠️ Access token is expired, attempting to refresh...');
        final storedRefreshToken = await TokenStorageService.getRefreshToken();
        print(
            '🔄 Stored refresh token: ${storedRefreshToken != null ? 'Present' : 'Missing'}');

        if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
          print('🔄 Attempting token refresh...');
          final refreshResult = await InfluencerAuthService.refreshToken(
              refreshToken: storedRefreshToken);
          print('🔄 Refresh result: $refreshResult');

          if (refreshResult['success']) {
            print('✅ Token refreshed successfully');
            final newAccessToken = refreshResult['data']['access_token'];
            print('🆕 New access token: ${newAccessToken.substring(0, 20)}...');
            await TokenStorageService.saveAccessToken(newAccessToken);
            print('💾 New access token saved');

            // Also save new refresh token if provided (some APIs rotate refresh tokens)
            final newRefreshToken = refreshResult['data']['refresh_token'];
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await TokenStorageService.saveRefreshToken(newRefreshToken);
              print('💾 New refresh token saved');
            } else {
              print('ℹ️ No new refresh token provided, keeping existing one');
            }
          } else {
            print('❌ Token refresh failed: ${refreshResult['message']}');
            print(
                '❌ Refresh error details: ${refreshResult['errorDetails'] ?? 'No details'}');

            // If refresh fails, clear invalid tokens and return error
            await TokenStorageService.clearAuthData();
            print('🗑️ Invalid tokens cleared');

            return {
              'success': false,
              'message': 'Token refresh failed. Please login again.',
              'statusCode': 401,
            };
          }
        } else {
          print('❌ No refresh token available');
          return {
            'success': false,
            'message': 'No refresh token available. Please login again.',
            'statusCode': 401,
          };
        }
      } else {
        print('✅ Access token is still valid');
      }

      // Get access token and user role from storage
      final accessToken = await TokenStorageService.getAccessToken();
      final userRole = await TokenStorageService.getUserRole();

      print('👤 === ADD INFLUENCER PROFILE REQUEST ===');
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'Missing'}');
      print('👤 User Role: $userRole');
      print('🎯 Expected Role: influencer');

      // Check if user has the correct role
      if (userRole != 'influencer') {
        print('❌ Role mismatch! User role: $userRole, Expected: influencer');
        print('❌ This endpoint requires an influencer role');
        return {
          'success': false,
          'message':
              'Access denied: This endpoint requires an influencer role. Current role: $userRole',
          'statusCode': 403,
        };
      }

      final uri = Uri.parse('$baseUrl/influencer/add-profile');

      // Create multipart request for file upload
      final request = http.MultipartRequest('POST', uri);

      // Set authorization header
      if (accessToken != null && accessToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $accessToken';
        print(
            '🔐 Authorization header set: Bearer ${accessToken.substring(0, 20)}...');
      } else {
        print('❌ No access token available for authorization header');
      }

      // Add text fields as form data
      request.fields['pseudo'] = pseudo;
      request.fields['bio'] = bio;
      request.fields['zone'] = zone;

      // Add profile picture if provided
      if (profilePicture != null) {
        try {
          if (await profilePicture.exists()) {
            final filename = profilePicture.path.split('/').last;

            // Validate file type - only allow image files
            final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
            final fileExtension = filename.toLowerCase();
            final isValidImage =
                validExtensions.any((ext) => fileExtension.endsWith(ext));

            if (!isValidImage) {
              print(
                  '❌ Invalid file type: $filename. Only JPG, PNG, GIF, WEBP are allowed.');
              print('❌ File extension: $fileExtension');
            } else {
              print(
                  '📁 File: $filename, Size: ${await profilePicture.length()} bytes');

              // Create multipart file with proper content type
              final stream = http.ByteStream(profilePicture.openRead());
              final length = await profilePicture.length();

              // Determine MIME type based on file extension
              String mimeType = 'image/jpeg'; // default
              if (fileExtension.endsWith('.png')) {
                mimeType = 'image/png';
              } else if (fileExtension.endsWith('.jpg') ||
                  fileExtension.endsWith('.jpeg')) {
                mimeType = 'image/jpeg';
              } else if (fileExtension.endsWith('.gif')) {
                mimeType = 'image/gif';
              } else if (fileExtension.endsWith('.webp')) {
                mimeType = 'image/webp';
              }

              final multipartFile = http.MultipartFile(
                'profilePicture',
                stream,
                length,
                filename: filename,
                contentType: MediaType.parse(mimeType), // ✅ Add content type
              );
              request.files.add(multipartFile);
            }
          } else {
            print('❌ Profile picture file does not exist: $profilePicture');
          }
        } catch (e) {
          print('❌ Error processing profile picture: $e');
        }
      }

      print('📦 Request fields: ${request.fields}');
      print('📁 Request files: ${request.files.length}');
      print('🔐 Request headers: ${request.headers}');

      // Send multipart request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Profile added successfully: $responseData');

        // Check if the API response indicates profile is added
        // Since the API doesn't return a data.status field, we'll use the message to determine success
        final status = responseData['data']?['status'] ??
            (responseData['message']
                        ?.toString()
                        .toLowerCase()
                        .contains('successfully') ==
                    true
                ? 'influencer-profile-added'
                : null);
        print('📊 API Response Status: $status');
        print(
            '📊 Determined Status: ${status ?? 'Using message-based detection'}');

        // Add the status to the response for the BLoC to handle
        return {
          ...responseData,
          'success': true, // Explicitly set success to true
          'profileStatus': status ??
              'influencer-profile-added', // Default to profile-added if no status
          'shouldNavigateToSocials':
              true, // Always navigate to socials after profile creation
        };
      } else {
        print('❌ Profile addition failed with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Parse error response for better error messages
        String errorMessage = 'Failed to add profile';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          print('⚠️ Could not parse error response: $e');
        }

        // Handle specific error codes
        switch (response.statusCode) {
          case 409:
            errorMessage =
                'Profile already exists or conflict detected. $errorMessage';
            break;
          case 400:
            errorMessage = 'Invalid data provided. $errorMessage';
            break;
          case 401:
            errorMessage = 'Unauthorized. Please login again.';
            break;
          case 403:
            errorMessage = 'Access denied. $errorMessage';
            break;
          case 422:
            errorMessage = 'Validation error. $errorMessage';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Error ${response.statusCode}: $errorMessage';
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
          'errorDetails': response.body,
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
      print('🔐 === ADDING SOCIALS ===');
      print('📱 Socials: $socials');
    print('🔗 URL: $baseUrl/influencer/add-socials');

    try {
      // Check if token is expired and refresh if needed
      print('🔍 === TOKEN EXPIRY CHECK ===');
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔍 Token expired: $isExpired');

      if (isExpired) {
        print('⚠️ Access token is expired, attempting to refresh...');
        final storedRefreshToken = await TokenStorageService.getRefreshToken();
        print(
            '🔄 Stored refresh token: ${storedRefreshToken != null ? 'Present' : 'Missing'}');

        if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
          print('🔄 Attempting token refresh...');
          final refreshResult = await InfluencerAuthService.refreshToken(
              refreshToken: storedRefreshToken);
          print('🔄 Refresh result: $refreshResult');

          if (refreshResult['success']) {
            print('✅ Token refreshed successfully');
            final newAccessToken = refreshResult['data']['access_token'];
            print('🆕 New access token: ${newAccessToken.substring(0, 20)}...');
            await TokenStorageService.saveAccessToken(newAccessToken);
            print('💾 New access token saved');

            // Also save new refresh token if provided (some APIs rotate refresh tokens)
            final newRefreshToken = refreshResult['data']['refresh_token'];
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await TokenStorageService.saveRefreshToken(newRefreshToken);
              print('💾 New refresh token saved');
            } else {
              print('ℹ️ No new refresh token provided, keeping existing one');
            }
          } else {
            print('❌ Token refresh failed: ${refreshResult['message']}');
            print(
                '❌ Refresh error details: ${refreshResult['errorDetails'] ?? 'No details'}');

            // If refresh fails, clear invalid tokens and return error
            await TokenStorageService.clearAuthData();
            print('🗑️ Invalid tokens cleared');

            return {
              'success': false,
              'message': 'Token refresh failed. Please login again.',
              'statusCode': 401,
            };
          }
        } else {
          print('❌ No refresh token available');
          return {
            'success': false,
            'message': 'No refresh token available. Please login again.',
            'statusCode': 401,
          };
        }
      } else {
        print('✅ Access token is still valid');
      }

      // Get access token from storage
      print('💾 === GETTING ACCESS TOKEN ===');
      var accessToken = await TokenStorageService.getAccessToken();
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'Missing'}');
      print('🔑 Token Length: ${accessToken?.length ?? 0}');
      print(
          '🔑 Token Preview: ${accessToken != null ? '${accessToken.substring(0, 20)}...' : 'NULL'}');

      // Also check refresh token
      final refreshToken = await TokenStorageService.getRefreshToken();
      print(
          '🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'Missing'}');
      print('🔄 Refresh Token Length: ${refreshToken?.length ?? 0}');

      // Print all stored tokens for debugging
      await TokenStorageService.printStoredTokens();

      // Additional debugging: Check if token was just refreshed
      if (isExpired) {
        print('🔍 === TOKEN REFRESH DEBUG ===');
        print('🔍 Token was expired, checking if refresh was successful...');
        final currentToken = await TokenStorageService.getAccessToken();
        print(
            '🔍 Current token after refresh: ${currentToken != null ? 'Present' : 'Missing'}');
        print('🔍 Token changed: ${currentToken != accessToken}');
        if (currentToken != null && currentToken != accessToken) {
          print('🔍 Using refreshed token for API call');
          accessToken = currentToken;
        }
      }

      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token available for socials API call');
        return {
          'success': false,
          'message': 'No access token available. Please login again.',
          'statusCode': 401,
        };
      }

      final uri = Uri.parse('$baseUrl/influencer/add-socials');
      final requestBody = jsonEncode({
        "socials": socials,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      print('🔗 Request URL: $uri');
      print('📋 Request Headers: $headers');
      print(
          '🔑 Authorization Header: Bearer ${accessToken.substring(0, 20)}...');
      print('📦 Request Body: $requestBody');

      final response = await http.post(
        uri,
        headers: headers,
        body: requestBody,
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Socials added successfully: $responseData');
        return responseData;
      } else {
        print('❌ Socials addition failed with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to add socials: ${response.statusCode}';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
            'errorDetails': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to add socials: ${response.statusCode}',
            'statusCode': response.statusCode,
            'rawResponse': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Exception in addSocials: $e');
      return {
        'success': false,
        'message': 'Error adding socials: $e',
        'statusCode': 0,
      };
    }
  }

  /// Request password reset
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      print('🔐 === REQUEST PASSWORD RESET ===');
      print('📧 Email: $email');
      print('🔗 URL: $baseUrl/influencer-auth/request-password-reset');

      final response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/request-password-reset'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Password reset request successful');
        return {
          'success': true,
          'message': responseData['message'] ??
              'Password reset email sent successfully',
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Password reset request failed');
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to send password reset email',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in requestPasswordReset: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Verify reset password OTP
  static Future<Map<String, dynamic>> verifyResetPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      print('🔐 === VERIFY RESET PASSWORD OTP ===');
      print('📧 Email: $email');
      print('🔢 OTP: $otp');
      print('🔗 URL: $baseUrl/influencer-auth/verify-reset-password-otp');

      final response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/verify-reset-password-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'role': 'influencer',
        }),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ OTP verification successful');
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP verified successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ OTP verification failed');
        return {
          'success': false,
          'message': responseData['message'] ?? 'OTP verification failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in verifyResetPasswordOtp: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String newPassword,
    required String confirmPassword,
    String? resetToken,
    String? email,
  }) async {
    try {
      print('🔐 === RESET PASSWORD ===');
      print('🔑 New Password: ${newPassword.substring(0, 3)}***');
      print('🔑 Confirm Password: ${confirmPassword.substring(0, 3)}***');
      print('🔗 URL: $baseUrl/influencer-auth/reset-password');

      final requestBody = <String, dynamic>{
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };

      if (email != null) {
        requestBody['email'] = email;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add authorization header if resetToken is provided
      if (resetToken != null) {
        headers['Authorization'] = 'Bearer $resetToken';
        print('🔑 Adding Authorization header with reset token');
        print('🔑 Reset Token Preview: ${resetToken.substring(0, 20)}...');
      }

      print('📤 Request Headers: $headers');
      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/influencer-auth/reset-password'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Password reset successful');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Password reset failed');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in resetPassword: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Get influencer profile using HTTP interceptor for automatic token management
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      print('👤 === GETTING INFLUENCER PROFILE ===');
      print('🔗 URL: $baseUrl/influencer/profile');

      // Use HTTP interceptor to automatically handle token refresh
      final response = await HttpInterceptor.interceptRequest(() async {
        final accessToken = await TokenStorageService.getAccessToken();

        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token available');
        }

        return await http.get(
          Uri.parse('$baseUrl/influencer/profile'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );
      });

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Profile fetched successfully');
        print('📊 Profile Data: $responseData');

        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile fetched successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        print('❌ Profile fetch failed');
        print('📊 Error Response: $responseData');

        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in getProfile: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Check if influencer registration is complete
  static Future<Map<String, dynamic>> checkRegistrationComplete() async {
    try {
      print('🔍 === CHECKING INFLUENCER REGISTRATION COMPLETION ===');

      // First check if profile exists
      final profileResponse = await getProfile();
      if (!profileResponse['success']) {
        print('❌ Profile not found or incomplete');
        return {
          'success': false,
          'isComplete': false,
          'message': 'Profile not found',
          'hasProfile': false,
          'hasSocials': false,
        };
      }

      // Check if socials exist
      final socialsResponse = await getSocials();
      if (!socialsResponse['success']) {
        print('❌ Socials not found or incomplete');
        return {
          'success': false,
          'isComplete': false,
          'message': 'Socials not found',
          'hasProfile': true,
          'hasSocials': false,
        };
      }

      // Check if both profile and socials have data
      final profileData = profileResponse['data'];
      final socialsData = socialsResponse['data'];

      final hasProfileData = profileData != null &&
          profileData['pseudo'] != null &&
          profileData['bio'] != null &&
          profileData['zone'] != null;

      final hasSocialsData =
          socialsData != null && socialsData is List && socialsData.isNotEmpty;

      final isComplete = hasProfileData && hasSocialsData;

      print('✅ Registration check complete');
      print('📊 Has Profile Data: $hasProfileData');
      print('📊 Has Socials Data: $hasSocialsData');
      print('📊 Is Complete: $isComplete');

      return {
        'success': true,
        'isComplete': isComplete,
        'message':
            isComplete ? 'Registration complete' : 'Registration incomplete',
        'hasProfile': hasProfileData,
        'hasSocials': hasSocialsData,
      };
    } catch (e) {
      print('❌ Exception in checkRegistrationComplete: $e');
      return {
        'success': false,
        'isComplete': false,
        'message': 'Network error: ${e.toString()}',
        'hasProfile': false,
        'hasSocials': false,
      };
    }
  }

  /// Get influencer social media links using HTTP interceptor for automatic token management
  static Future<Map<String, dynamic>> getSocials() async {
    try {
      print('📱 === GETTING INFLUENCER SOCIALS ===');
      print('🔗 URL: $baseUrl/influencer/socials');

      // Use HTTP interceptor to automatically handle token refresh
      final response = await HttpInterceptor.interceptRequest(() async {
        final accessToken = await TokenStorageService.getAccessToken();

        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token available');
        }

        return await http.get(
          Uri.parse('$baseUrl/influencer/socials'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );
      });

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Socials fetched successfully');
        print('📊 Socials Data: $responseData');

        return {
          'success': true,
          'message': responseData['message'] ?? 'Socials fetched successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        print('❌ Socials fetch failed');
        print('📊 Error Response: $responseData');

        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch socials',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in getSocials: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Update influencer social media links using HTTP interceptor for automatic token management
  static Future<Map<String, dynamic>> updateSocials(
      List<Map<String, String>> socials) async {
    try {
      print('📱 === UPDATING INFLUENCER SOCIALS ===');
      print('🔗 URL: $baseUrl/influencer/socials');
      print('📊 Socials Data: $socials');

      // Use HTTP interceptor to automatically handle token refresh
      final response = await HttpInterceptor.interceptRequest(() async {
        final accessToken = await TokenStorageService.getAccessToken();

        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token available');
        }

        return await http.patch(
          Uri.parse('$baseUrl/influencer/socials'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'socials': socials,
          }),
        );
      });

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Socials updated successfully');
        print('📊 Response Data: $responseData');

        return {
          'success': true,
          'message': responseData['message'] ?? 'Socials updated successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        print('❌ Socials update failed');
        print('📊 Error Response: $responseData');

        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update socials',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in updateSocials: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Logout influencer using HTTP interceptor for automatic token management
  static Future<Map<String, dynamic>> logout() async {
    try {
      print('🚪 === INFLUENCER LOGOUT REQUEST ===');
      print('🔗 URL: $baseUrl/influencer-auth/logout');

      // Use HTTP interceptor to automatically handle token refresh
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/influencer-auth/logout',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Logout successful');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Logout successful',
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        print('❌ Logout failed');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Logout failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in logout: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Change influencer password using HTTP interceptor for automatic token management
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('🔐 === CHANGING INFLUENCER PASSWORD ===');
      print('🔗 URL: $baseUrl/influencer/change-password');
      print(
          '📊 Password Data: {oldPassword: ${'*' * oldPassword.length}, newPassword: ${'*' * newPassword.length}, confirmPassword: ${'*' * confirmPassword.length}}');

      // Use HTTP interceptor to automatically handle token refresh
      final response = await HttpInterceptor.interceptRequest(() async {
        final accessToken = await TokenStorageService.getAccessToken();

        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('No access token available');
        }

        return await http.post(
          Uri.parse('$baseUrl/influencer/change-password'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        body: jsonEncode({
            'oldPassword': oldPassword,
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
        }),
      );
      });

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Password changed successfully');
        print('📊 Response Data: $responseData');

        return {
          'success': true,
          'message': responseData['message'] ?? 'Password changed successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        print('❌ Password change failed');
        print('📊 Error Response: $responseData');

        // Extract clean error message from response
        String cleanErrorMessage = 'Failed to change password';

        if (responseData['message'] != null) {
          final messageData = responseData['message'];

          if (messageData is List && messageData.isNotEmpty) {
            // Handle array of error messages
            cleanErrorMessage = messageData.join(', ');
          } else if (messageData is String) {
            // Handle single string message
            cleanErrorMessage = messageData;
          } else {
            // Fallback for other formats
            cleanErrorMessage = messageData.toString();
          }
        }

        return {
          'success': false,
          'message': cleanErrorMessage,
          'details': responseData
              .toString(), // Include full error response for debugging
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in changePassword: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'details': e.toString(),
        'statusCode': 0,
      };
    }
  }
}
