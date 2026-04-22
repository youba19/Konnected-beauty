import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../storage/token_storage_service.dart';
import 'http_interceptor.dart';

class SalonAuthService {
  static const String baseUrl = 'https://server.konectedbeauty.com';

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

  // Add salon info endpoint
  static const String addSalonInfoEndpoint = '/salon/add-info';

  // Add salon profile endpoint
  static const String addSalonProfileEndpoint = '/salon/add-profile';

  // Reset password endpoints
  static const String requestPasswordResetEndpoint =
      '/salon-auth/request-password-reset';
  static const String verifyResetPasswordOtpEndpoint =
      '/salon-auth/verify-reset-password-otp';
  static const String resetPasswordEndpoint = '/salon-auth/reset-password';
  static const String salonServicesEndpoint = '/salon-service';

  // Account deletion endpoint
  static const String deleteAccountEndpoint = '/salon-auth/delete-account';

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
          'message': formatMessage(responseData['message']),
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
      final requestBody = {
        'email': email,
        'otp': otp,
      };

      print('🔐 === OTP VALIDATION REQUEST ===');
      print('📧 Email: $email');
      print('🔢 OTP: $otp');
      print('🌐 URL: $baseUrl$validateOtpEndpoint');
      print('📦 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl$validateOtpEndpoint'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ OTP Validation Success');
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ OTP Validation Failed');
        print('❌ Error Message: ${formatMessage(responseData['message'])}');
        return {
          'success': false,
          'message': formatMessage(responseData['message']),
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 OTP Validation Exception: $e');
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
        String userMessage = formatMessage(responseData['message']);

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
    print('🎯 Using http package with proper headers');

    try {
      print('🔐 === LOGIN REQUEST ===');
      print('🔗 URL: $baseUrl$loginEndpoint');
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
        Uri.parse('$baseUrl$loginEndpoint'),
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
      print('🎯 === END STATUS FROM API ===');

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

  /// Refresh access token
  static Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      print('🔄 === REFRESH TOKEN REQUEST ===');
      print('🔗 URL: $baseUrl$refreshTokenEndpoint');
      print('🔑 Refresh Token: ${refreshToken.substring(0, 50)}...');

      final response = await http.post(
        Uri.parse('$baseUrl$refreshTokenEndpoint'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $refreshToken',
        },
      );

      print('📡 Refresh Response Status: ${response.statusCode}');
      print('📄 Refresh Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Refresh Token Success');
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ Refresh Token Failed');
        return {
          'success': false,
          'message': formatMessage(responseData['message']),
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 Refresh Token Exception: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Add salon information
  static Future<Map<String, dynamic>> addSalonInfo({
    required String name,
    required String address,
    required String domain,
    String? website,
    required String accessToken, // Use token directly from login response
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': name,
        'address': address,
        'domain': domain,
      };
      if (website != null && website.trim().isNotEmpty) {
        // Ensure the website is a valid URL format
        try {
          final uri = Uri.parse(website.trim());
          if (uri.hasScheme && uri.host.isNotEmpty) {
            requestBody['website'] = uri.toString();
            print('🌐 Website added to request: ${uri.toString()}');
          } else {
            print('⚠️ Website is not a valid URL, skipping');
          }
        } catch (e) {
          print('⚠️ Error parsing website URL: $e, skipping');
        }
      } else {
        print('🌐 No website provided or website is empty');
      }

      print('🏢 === ADD SALON INFO REQUEST ===');
      print('🔗 URL: $baseUrl$addSalonInfoEndpoint');
      print('📦 Request Body: ${jsonEncode(requestBody)}');

      // Print stored tokens for debugging
      await TokenStorageService.printStoredTokens();

      // Use the access token provided directly from login response
      print('🔑 Using access token provided directly from login response');

      String currentAccessToken = accessToken;

      Future<http.Response> doRequest(String token) {
        final requestHeaders = {
          ...headers,
          'Authorization': 'Bearer $token',
        };

        print('🔑 Access Token: Present');
        print('🔑 Token Value: ${token.substring(0, 50)}...');
        print('🔑 Headers: $requestHeaders');

        return http.post(
          Uri.parse('$baseUrl$addSalonInfoEndpoint'),
          headers: requestHeaders,
          body: jsonEncode(requestBody),
        );
      }

      // First attempt
      http.Response response = await doRequest(currentAccessToken);
      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      // If unauthorized, try to refresh token once and retry
      if (response.statusCode == 401) {
        print(
            '⚠️ Received 401 Unauthorized. Attempting token refresh and retry...');
        final storedRefreshToken = await TokenStorageService.getRefreshToken();
        if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
          final refreshResult =
              await refreshToken(refreshToken: storedRefreshToken);
          if (refreshResult['success'] == true) {
            final newAccessToken =
                refreshResult['data']['access_token'] as String?;
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await TokenStorageService.saveAccessToken(newAccessToken);
              currentAccessToken = newAccessToken;
              print('✅ Token refreshed. Retrying add-info with new token...');
              response = await doRequest(currentAccessToken);
              print('📡 Retry Response Status Code: ${response.statusCode}');
              print('📄 Retry Response Body: ${response.body}');
            }
          } else {
            print('❌ Token refresh failed: ${refreshResult['message']}');
          }
        } else {
          print('❌ No refresh token available for retry');
        }
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Add Salon Info Success');
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ Add Salon Info Failed');
        print('📊 Error Response: $responseData');
        return {
          'success': false,
          'message': formatMessage(responseData['message']),
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 Add Salon Info Exception: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Add salon profile
  static Future<Map<String, dynamic>> addSalonProfile({
    required String openingHour,
    required String closingHour,
    required String description,
    required List<String> pictures,
  }) async {
    try {
      print('🔍 Preparing multipart request for add profile');
      print('🔍 Pictures count: ${pictures.length}');

      // Helper function to build multipart request
      Future<http.MultipartRequest> _buildMultipartRequest() async {
        final accessToken = await TokenStorageService.getAccessToken();
        final uri = Uri.parse('$baseUrl$addSalonProfileEndpoint');
        final request = http.MultipartRequest('POST', uri);

        // Set Authorization header
        if (accessToken != null && accessToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $accessToken';
        }

        // Add text fields
        request.fields['openingHour'] = openingHour;
        request.fields['closingHour'] = closingHour;
        request.fields['description'] = description;

        // Attach files as 'pictures'[] (array)
        for (int i = 0; i < pictures.length; i++) {
          final path = pictures[i];
          try {
            final file = File(path);
            if (await file.exists()) {
              final stream = http.ByteStream(file.openRead());
              final length = await file.length();
              final filename = path.split('/').last;

              // Validate file type - only allow image files
              final validExtensions = [
                '.jpg',
                '.jpeg',
                '.png',
                '.gif',
                '.webp'
              ];
              final fileExtension = filename.toLowerCase();
              final isValidImage =
                  validExtensions.any((ext) => fileExtension.endsWith(ext));

              if (!isValidImage) {
                print(
                    '❌ Invalid file type: $filename. Only JPG, PNG, GIF, WEBP are allowed.');
                print('❌ File extension: $fileExtension');
                continue; // Skip this file
              }

              // Ensure filename has proper extension
              String finalFilename = filename;
              if (!fileExtension.contains('.')) {
                // If no extension, assume it's JPEG
                finalFilename = '$filename.jpg';
                print(
                    '⚠️ No file extension found, assuming JPEG: $finalFilename');
              }

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

              print('📁 File: $filename, MIME: $mimeType, Size: $length bytes');

              final multipartFile = http.MultipartFile(
                'pictures',
                stream,
                length,
                filename: finalFilename,
                contentType: MediaType.parse(mimeType),
              );
              request.files.add(multipartFile);
            } else {
              print('⚠️ File not found, skipping: $path');
            }
          } catch (e) {
            print('⚠️ Error attaching file "$path": $e');
          }
        }

        return request;
      }

      print('🏢 === ADD SALON PROFILE REQUEST ===');

      // Use interceptRequest to handle token refresh automatically
      final response = await HttpInterceptor.interceptRequest(() async {
        final request = await _buildMultipartRequest();
        print(
            '📤 Sending multipart request with ${request.fields.length} fields and ${request.files.length} files');
        final streamed = await request.send();
        return await http.Response.fromStream(streamed);
      });

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Add Salon Profile Success');
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ Add Salon Profile Failed');
        String errorMessage = formatMessage(responseData['message']);

        // Provide more helpful error messages
        if (response.statusCode == 422 &&
            errorMessage.toLowerCase().contains('invalid file type')) {
          errorMessage =
              'Invalid file type. Please select only JPG, PNG, GIF, or WEBP images.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 Add Salon Profile Exception: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
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
      print('🔗 URL: $baseUrl$requestPasswordResetEndpoint');
      print('📧 Email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl$requestPasswordResetEndpoint'),
        headers: headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Request Password Reset Success');
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ Request Password Reset Failed');
        return {
          'success': false,
          'message': formatMessage(responseData['message']),
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 Request Password Reset Exception: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
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
      print('🔗 URL: $baseUrl$verifyResetPasswordOtpEndpoint');
      print('📧 Email: $email');
      print('🔢 OTP: $otp');

      final response = await http.post(
        Uri.parse('$baseUrl$verifyResetPasswordOtpEndpoint'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      print('🔍 OTP Response Data Keys: ${responseData.keys.toList()}');
      if (responseData['data'] != null) {
        print('🔍 OTP Data Keys: ${responseData['data'].keys.toList()}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Verify Reset Password OTP Success');
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ Verify Reset Password OTP Failed');
        return {
          'success': false,
          'message': formatMessage(responseData['message']),
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 Verify Reset Password OTP Exception: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
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
      print('🔗 URL: $baseUrl$resetPasswordEndpoint');
      print('🔑 New Password: ${'*' * newPassword.length}');
      print('🔑 Confirm Password: ${'*' * confirmPassword.length}');
      print('🔑 Reset Token: ${resetToken != null ? 'Present' : 'Missing'}');
      print('📧 Email: ${email ?? 'Not provided'}');

      // Prepare headers with authorization if token is provided
      final requestHeaders = Map<String, String>.from(headers);
      if (resetToken != null && resetToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $resetToken';
      }

      final response = await http.post(
        Uri.parse('$baseUrl$resetPasswordEndpoint'),
        headers: requestHeaders,
        body: jsonEncode({
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
          if (email != null) 'email': email,
        }),
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Reset Password Success');
        return {
          'success': true,
          'message': formatMessage(responseData['message']),
          'data': responseData['data'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        print('❌ Reset Password Failed');
        return {
          'success': false,
          'message': formatMessage(responseData['message']),
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('💥 Reset Password Exception: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': 'NetworkError',
        'statusCode': 0,
      };
    }
  }

  /// Check current authentication status
  static Future<void> checkAuthStatus() async {
    print('🔐 === CHECKING AUTH STATUS ===');
    await TokenStorageService.printStoredTokens();

    final isLoggedIn = await TokenStorageService.isLoggedIn();
    final isExpired = await TokenStorageService.isAccessTokenExpired();

    print('🔐 Is Logged In: $isLoggedIn');
    print('🔐 Is Token Expired: $isExpired');
    print('🔐 === END AUTH STATUS ===');
  }

  /// Create new salon service
  static Future<Map<String, dynamic>> createSalonService({
    required String name,
    required int price,
    required String description,
  }) async {
    try {
      print('🏢 === CREATE SALON SERVICE ===');
      print('🔗 URL: $baseUrl$salonServicesEndpoint');
      print('📝 Service Name: $name');
      print('💰 Price: $price');
      print('📄 Description: $description');

      // Check authentication status first
      await checkAuthStatus();

      // Get access token
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'No access token found',
          'error': 'Unauthorized',
        };
      }

      print('🔑 Access Token: Present');
      print('🔑 Token: ${accessToken.substring(0, 50)}...');

      // Check if token is expired
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔑 Token Expired: $isExpired');

      // If token is expired, try to refresh it first
      String tokenToUse = accessToken;
      if (isExpired) {
        print('🔐 Token is expired, refreshing before request...');
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);
            tokenToUse = newAccessToken;
            print('🔄 Token refreshed successfully before request');
          } else {
            print('❌ Failed to refresh token before request');
          }
        }
      }

      // Prepare headers with authorization
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders['Authorization'] = 'Bearer $tokenToUse';

      final response = await http.post(
        Uri.parse('$baseUrl$salonServicesEndpoint'),
        headers: requestHeaders,
        body: jsonEncode({
          'name': name,
          'price': price,
          'description': description,
        }),
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Salon Service Created Successfully');
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Service created successfully',
        };
      } else if (response.statusCode == 401) {
        print('🔐 Token expired, attempting to refresh...');

        // Try to refresh the token
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);

            print('🔄 Token refreshed, retrying service creation...');

            // Retry the request with the new token
            final retryHeaders = Map<String, String>.from(headers);
            retryHeaders['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await http.post(
              Uri.parse('$baseUrl$salonServicesEndpoint'),
              headers: retryHeaders,
              body: jsonEncode({
                'name': name,
                'price': price,
                'description': description,
              }),
            );

            print('📡 Retry Response Status Code: ${retryResponse.statusCode}');
            print('📄 Retry Response Body: ${retryResponse.body}');

            if (retryResponse.statusCode == 200 ||
                retryResponse.statusCode == 201) {
              final retryResponseData = jsonDecode(retryResponse.body);
              print(
                  '✅ Salon Service Created Successfully (after token refresh)');
              return {
                'success': true,
                'data': retryResponseData['data'] ?? retryResponseData,
                'message': retryResponseData['message'] ??
                    'Service created successfully',
              };
            }
          }
        }

        // If refresh failed or retry failed, return the original error
        print('❌ Failed to create salon service (after token refresh attempt)');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create service',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to create salon service');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create service',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error creating salon service: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Update salon service
  static Future<Map<String, dynamic>> updateSalonService({
    required String serviceId,
    String? name,
    int? price,
    String? description,
  }) async {
    try {
      print('🏢 === UPDATE SALON SERVICE ===');
      print('🔗 URL: $baseUrl$salonServicesEndpoint/$serviceId');
      print('🆔 Service ID: $serviceId');
      print('📝 Service Name: $name');
      print('💰 Price: $price');
      print('📄 Description: $description');

      // Check authentication status first
      await checkAuthStatus();

      // Get access token
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'No access token found',
          'error': 'Unauthorized',
        };
      }

      print('🔑 Access Token: Present');
      print('🔑 Token: ${accessToken.substring(0, 50)}...');

      // Check if token is expired
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔑 Token Expired: $isExpired');

      // If token is expired, try to refresh it first
      String tokenToUse = accessToken;
      if (isExpired) {
        print('🔐 Token is expired, refreshing before request...');
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);
            tokenToUse = newAccessToken;
            print('🔄 Token refreshed successfully before request');
          } else {
            print('❌ Failed to refresh token before request');
          }
        }
      }

      // Prepare headers with authorization
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders['Authorization'] = 'Bearer $tokenToUse';

      // Prepare request body with only provided fields
      final requestBody = <String, dynamic>{};
      if (name != null) requestBody['name'] = name;
      if (price != null) requestBody['price'] = price;
      if (description != null) requestBody['description'] = description;

      final response = await http.patch(
        Uri.parse('$baseUrl$salonServicesEndpoint/$serviceId'),
        headers: requestHeaders,
        body: jsonEncode(requestBody),
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Salon Service Updated Successfully');
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': responseData['message'] ?? 'Service updated successfully',
        };
      } else if (response.statusCode == 401) {
        print('🔐 Token expired, attempting to refresh...');

        // Try to refresh the token
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);

            print('🔄 Token refreshed, retrying service update...');

            // Retry the request with the new token
            final retryHeaders = Map<String, String>.from(headers);
            retryHeaders['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await http.patch(
              Uri.parse('$baseUrl$salonServicesEndpoint/$serviceId'),
              headers: retryHeaders,
              body: jsonEncode(requestBody),
            );

            print('📡 Retry Response Status Code: ${retryResponse.statusCode}');
            print('📄 Retry Response Body: ${retryResponse.body}');

            if (retryResponse.statusCode == 200 ||
                retryResponse.statusCode == 201) {
              final retryResponseData = jsonDecode(retryResponse.body);
              print(
                  '✅ Salon Service Updated Successfully (after token refresh)');
              return {
                'success': true,
                'data': retryResponseData['data'] ?? retryResponseData,
                'message': retryResponseData['message'] ??
                    'Service updated successfully',
              };
            }
          }
        }

        // If refresh failed or retry failed, return the original error
        print('❌ Failed to update salon service (after token refresh attempt)');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update service',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to update salon service');
        final errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['message'] ?? 'Failed to update service';

        // Provide more specific error messages
        if (response.statusCode == 404) {
          errorMessage =
              'Service not found. Please check if the service exists.';
        } else if (response.statusCode == 403) {
          errorMessage = 'You do not have permission to update this service.';
        } else if (response.statusCode == 400) {
          errorMessage = 'Invalid data provided. Please check your input.';
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error updating salon service: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Delete salon service
  static Future<Map<String, dynamic>> deleteSalonService({
    required String serviceId,
  }) async {
    try {
      print('🏢 === DELETE SALON SERVICE ===');
      print('🔗 URL: $baseUrl$salonServicesEndpoint/$serviceId');
      print('🆔 Service ID: $serviceId');

      // Check authentication status first
      await checkAuthStatus();

      // Get access token
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'No access token found',
          'error': 'Unauthorized',
        };
      }

      print('🔑 Access Token: Present');
      print('🔑 Token: ${accessToken.substring(0, 50)}...');

      // Check if token is expired
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔑 Token Expired: $isExpired');

      // If token is expired, try to refresh it first
      String tokenToUse = accessToken;
      if (isExpired) {
        print('🔐 Token is expired, refreshing before request...');
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);
            tokenToUse = newAccessToken;
            print('🔄 Token refreshed successfully before request');
          } else {
            print('❌ Failed to refresh token before request');
          }
        }
      }

      // Prepare headers with authorization
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders['Authorization'] = 'Bearer $tokenToUse';

      final response = await http.delete(
        Uri.parse('$baseUrl$salonServicesEndpoint/$serviceId'),
        headers: requestHeaders,
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        print('✅ Salon Service Deleted Successfully');
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Service deleted successfully',
        };
      } else if (response.statusCode == 401) {
        print('🔐 Token expired, attempting to refresh...');

        // Try to refresh the token
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);

            print('🔄 Token refreshed, retrying service deletion...');

            // Retry the request with the new token
            final retryHeaders = Map<String, String>.from(headers);
            retryHeaders['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await http.delete(
              Uri.parse('$baseUrl$salonServicesEndpoint/$serviceId'),
              headers: retryHeaders,
            );

            print('📡 Retry Response Status Code: ${retryResponse.statusCode}');
            print('📄 Retry Response Body: ${retryResponse.body}');

            if (retryResponse.statusCode == 200 ||
                retryResponse.statusCode == 204) {
              final retryResponseData = retryResponse.body.isNotEmpty
                  ? jsonDecode(retryResponse.body)
                  : {};
              print(
                  '✅ Salon Service Deleted Successfully (after token refresh)');
              return {
                'success': true,
                'data': retryResponseData,
                'message': retryResponseData['message'] ??
                    'Service deleted successfully',
              };
            }
          }
        }

        // If refresh failed or retry failed, return the original error
        print('❌ Failed to delete salon service (after token refresh attempt)');
        final errorData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete service',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to delete salon service');
        final errorData =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete service',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error deleting salon service: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Get salon services
  static Future<Map<String, dynamic>> getSalonServices({
    int? minPrice,
    int? maxPrice,
    String? search,
  }) async {
    try {
      print('🏢 === GET SALON SERVICES ===');

      // Build URL with query parameters
      String url = '$baseUrl$salonServicesEndpoint';
      List<String> queryParams = [];

      if (minPrice != null) {
        queryParams.add('minPrice=$minPrice');
      }
      if (maxPrice != null) {
        queryParams.add('maxPrice=$maxPrice');
      }
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('🔗 URL: $url');
      print('💰 Min Price: $minPrice');
      print('💰 Max Price: $maxPrice');
      print('🔍 Search: $search');

      // Check authentication status first
      await checkAuthStatus();

      // Get access token
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'No access token found',
          'error': 'Unauthorized',
        };
      }

      print('🔑 Access Token: Present');
      print('🔑 Token: ${accessToken.substring(0, 50)}...');

      // Check if token is expired
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔑 Token Expired: $isExpired');

      // If token is expired, try to refresh it first
      String tokenToUse = accessToken;
      if (isExpired) {
        print('🔐 Token is expired, refreshing before request...');
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);
            tokenToUse = newAccessToken;
            print('🔄 Token refreshed successfully before request');
          } else {
            print('❌ Failed to refresh token before request');
          }
        }
      }

      // Prepare headers with authorization
      final requestHeaders = Map<String, String>.from(headers);
      requestHeaders['Authorization'] = 'Bearer $tokenToUse';

      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Salon Services Retrieved Successfully');
        print('📊 Services Count: ${responseData['data']?.length ?? 0}');
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'message':
              responseData['message'] ?? 'Services retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        print('🔐 Token expired, attempting to refresh...');

        // Try to refresh the token
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);

            print('🔄 Token refreshed, retrying services request...');

            // Retry the request with the new token
            final retryHeaders = Map<String, String>.from(headers);
            retryHeaders['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await http.get(
              Uri.parse(url),
              headers: retryHeaders,
            );

            print('📡 Retry Response Status Code: ${retryResponse.statusCode}');
            print('📄 Retry Response Body: ${retryResponse.body}');

            if (retryResponse.statusCode == 200) {
              final retryResponseData = jsonDecode(retryResponse.body);
              print(
                  '✅ Salon Services Retrieved Successfully (after token refresh)');
              print(
                  '📊 Services Count: ${retryResponseData['data']?.length ?? 0}');
              return {
                'success': true,
                'data': retryResponseData['data'] ?? [],
                'message': retryResponseData['message'] ??
                    'Services retrieved successfully',
              };
            }
          }
        }

        // If refresh failed or retry failed, return the original error
        print('❌ Failed to get salon services (after token refresh attempt)');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get services',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to get salon services');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get services',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error getting salon services: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Get salon profile to check registration status
  static Future<Map<String, dynamic>> getSalonProfile() async {
    print('🏢 === GETTING SALON PROFILE ===');

    try {
      // Check authentication status first
      await checkAuthStatus();

      // Get access token
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('❌ No access token found');
        return {
          'success': false,
          'message': 'No access token found',
          'error': 'Unauthorized',
        };
      }

      print('🔑 Access Token: Present');
      print('🔑 Token: ${accessToken.substring(0, 50)}...');

      // Check if token is expired
      final isExpired = await TokenStorageService.isAccessTokenExpired();
      print('🔑 Token Expired: $isExpired');

      // If token is expired, try to refresh it first
      String tokenToUse = accessToken;
      if (isExpired) {
        print('🔐 Token is expired, refreshing before request...');
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);
            tokenToUse = newAccessToken;
            print('🔄 Token refreshed successfully before request');
          } else {
            print('❌ Failed to refresh token before request');
          }
        }
      }

      // Prepare headers with authorization
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tokenToUse',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/salon/profile'),
        headers: requestHeaders,
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Salon Profile Retrieved Successfully');
        print('📊 Profile Data: $responseData');
        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message':
              responseData['message'] ?? 'Profile retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        print('🔐 Token expired, attempting to refresh...');

        // Try to refresh the token
        final refreshTokenValue = await TokenStorageService.getRefreshToken();
        if (refreshTokenValue != null) {
          final refreshResult =
              await refreshToken(refreshToken: refreshTokenValue);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            await TokenStorageService.saveAccessToken(newAccessToken);

            print('🔄 Token refreshed, retrying profile request...');

            // Retry the request with the new token
            final retryHeaders = <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newAccessToken',
            };

            final retryResponse = await http.get(
              Uri.parse('$baseUrl/salon/profile'),
              headers: retryHeaders,
            );

            print('📡 Retry Response Status Code: ${retryResponse.statusCode}');
            print('📄 Retry Response Body: ${retryResponse.body}');

            if (retryResponse.statusCode == 200) {
              final retryResponseData = jsonDecode(retryResponse.body);
              print(
                  '✅ Salon Profile Retrieved Successfully (after token refresh)');
              print('📊 Profile Data: $retryResponseData');
              return {
                'success': true,
                'data': retryResponseData['data'] ?? retryResponseData,
                'message': retryResponseData['message'] ??
                    'Profile retrieved successfully',
              };
            }
          }
        }

        // If refresh failed or retry failed, return the original error
        print('❌ Failed to get salon profile (after token refresh attempt)');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get profile',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to get salon profile');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get profile',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error getting salon profile: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Logout salon using HTTP interceptor for automatic token management
  static Future<Map<String, dynamic>> logout() async {
    try {
      print('🚪 === SALON LOGOUT REQUEST ===');
      print('🔗 URL: $baseUrl/salon-auth/logout');

      // Use HTTP interceptor to automatically handle token refresh
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/salon-auth/logout',
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

  /// Delete salon account permanently
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      print('🗑️ === DELETE SALON ACCOUNT ===');

      // Get access token for authentication
      final accessToken = await TokenStorageService.getAccessToken();

      if (accessToken == null) {
        print('❌ No access token available');
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'error': 'NoAccessToken',
          'statusCode': 401,
        };
      }

      // Build headers with authentication
      final Map<String, String> requestHeaders = Map.from(headers);
      requestHeaders['Authorization'] = 'Bearer $accessToken';

      print('🔗 Making DELETE request to: $baseUrl$deleteAccountEndpoint');

      final response = await http.delete(
        Uri.parse('$baseUrl$deleteAccountEndpoint'),
        headers: requestHeaders,
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Account deleted successfully');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Account deleted successfully',
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Account deletion failed: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete account',
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Exception in deleteAccount: $e');
      return {
        'success': false,
        'message': 'Error deleting account: $e',
        'error': 'Exception',
        'statusCode': 500,
      };
    }
  }
}
