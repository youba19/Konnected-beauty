import 'dart:convert';
import 'dart:io';
import 'http_interceptor.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../storage/token_storage_service.dart';
import 'salon_auth_service.dart';
import '../../config/api_base_url.dart';

class SalonInfoService {
  static String get _baseUrl => ApiBaseUrl.value;

  // Get salon info
  Future<Map<String, dynamic>> getSalonInfo() async {
    try {
      print('🔍 === GETTING SALON INFO ===');

      // Make request through interceptor using authenticatedRequest
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon/salon-info',
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Salon info fetched successfully');
        print('📊 Salon Info Data: $responseData');

        // Convert data to Map<String, dynamic> if it exists
        Map<String, dynamic>? data;
        if (responseData['data'] != null) {
          data = Map<String, dynamic>.from(responseData['data']);

          // Show extracted fields clearly
          print('🎯 === EXTRACTED SALON INFO FIELDS ===');
          print('🏷️  Name: ${data['name'] ?? 'N/A'}');
          print('📍 Address: ${data['address'] ?? 'N/A'}');
          print('🏢 Domain: ${data['domain'] ?? 'N/A'}');
          print('🌐 Website: ${data['website'] ?? 'N/A'}');
          print('🆔 ID: ${data['id'] ?? 'N/A'}');
          print('📅 Created: ${data['createdAt'] ?? 'N/A'}');
          print('📅 Updated: ${data['updatedAt'] ?? 'N/A'}');
          print('🎯 === END EXTRACTED FIELDS ===');
        } else {
          print('⚠️  No data field found in response');
        }

        return {
          'success': true,
          'data': data,
          'message': responseData['message'],
        };
      } else {
        print('❌ Failed to fetch salon info: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to fetch salon info: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error fetching salon info: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get salon profile
  Future<Map<String, dynamic>> getSalonProfile() async {
    try {
      print('🔍 === GETTING SALON PROFILE ===');

      // Make request through interceptor using authenticatedRequest
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon/salon-profile',
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Salon profile fetched successfully');
        print('📊 Salon Profile Data: $responseData');

        // Convert data to Map<String, dynamic> if it exists
        Map<String, dynamic>? data;
        if (responseData['data'] != null) {
          data = Map<String, dynamic>.from(responseData['data']);

          // Parse pictures array properly
          if (data['pictures'] != null && data['pictures'] is List) {
            final List<dynamic> picturesArray = data['pictures'];
            print('🖼️ === PICTURES PARSING ===');
            print('🖼️ Raw pictures data: $picturesArray');
            print('🖼️ Pictures count: ${picturesArray.length}');

            for (int i = 0; i < picturesArray.length; i++) {
              final picture = picturesArray[i];
              print('🖼️ Picture $i:');
              print('🖼️   - ID: ${picture['id']}');
              print('🖼️   - URL: ${picture['url']}');
            }
            print('🖼️ === END PICTURES PARSING ===');
          } else {
            print('⚠️ No pictures found in profile data');
          }
        }

        return {
          'success': true,
          'data': data,
          'message': responseData['message'],
        };
      } else {
        print('❌ Failed to fetch salon profile: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to fetch salon profile: ${response.statusCode}',
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

  // Update salon info
  Future<Map<String, dynamic>> updateSalonInfo({
    String? name,
    String? address,
    String? domain,
    String? website,
  }) async {
    try {
      print('🔍 === UPDATING SALON INFO ===');

      // Build request body with only non-null values
      final Map<String, dynamic> requestBody = {};
      if (name != null && name.isNotEmpty) requestBody['name'] = name;
      if (address != null && address.isNotEmpty)
        requestBody['address'] = address;
      if (domain != null && domain.isNotEmpty) requestBody['domain'] = domain;
      if (website != null && website.isNotEmpty)
        requestBody['website'] = website;

      print('📤 Request Body: $requestBody');

      // Make request through interceptor using authenticatedRequest
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'PATCH',
        endpoint: '/salon/salon-info',
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Salon info updated successfully');
        return {
          'success': true,
          'data': responseData,
          'message':
              responseData['message'] ?? 'Salon info updated successfully',
        };
      } else {
        print('❌ Failed to update salon info: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed to update salon info: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error updating salon info: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Update salon profile
  Future<Map<String, dynamic>> updateSalonProfile({
    String? openingHour,
    String? closingHour,
    String? description,
    List<File>? pictureFiles,
  }) async {
    try {
      print('🔍 === UPDATING SALON PROFILE ===');
      print('🔍 Received parameters:');
      print('🔍 - openingHour: $openingHour');
      print('🔍 - closingHour: $closingHour');
      print('🔍 - description: $description');
      print('🔍 - pictureFiles count: ${pictureFiles?.length ?? 0}');
      print('🔍 - pictureFiles: ${pictureFiles?.map((f) => f.path).toList()}');

      print('📤 === CREATING MULTIPART REQUEST ===');

      // Get access token for authorization
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Create multipart request
      final uri = Uri.parse('$_baseUrl/salon/salon-profile');
      final request = http.MultipartRequest('PATCH', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add text fields (always include required fields)
      request.fields['openingHour'] = openingHour ?? '08:00:00';
      request.fields['closingHour'] = closingHour ?? '18:00:00';
      request.fields['description'] = description ?? '';

      print('🔤 === TEXT FIELDS ===');
      print('🔤 openingHour: ${request.fields['openingHour']}');
      print('🔤 closingHour: ${request.fields['closingHour']}');
      print('🔤 description: ${request.fields['description']}');

      // Add picture files if provided
      if (pictureFiles != null && pictureFiles.isNotEmpty) {
        print('📸 === ADDING PICTURE FILES ===');
        print('📸 Files count: ${pictureFiles.length}');

        for (int i = 0; i < pictureFiles.length; i++) {
          final file = pictureFiles[i];
          print('📸 Adding file $i: ${file.path}');

          // Determine content type based on file extension
          String fileExtension = file.path.toLowerCase().split('.').last;
          MediaType contentType;
          switch (fileExtension) {
            case 'jpg':
            case 'jpeg':
              contentType = MediaType('image', 'jpeg');
              break;
            case 'png':
              contentType = MediaType('image', 'png');
              break;
            case 'gif':
              contentType = MediaType('image', 'gif');
              break;
            case 'webp':
              contentType = MediaType('image', 'webp');
              break;
            default:
              contentType = MediaType('image', 'jpeg'); // Default fallback
          }

          print(
              '📸 File extension: $fileExtension, Content-Type: ${contentType.toString()}');

          // Add each file as a separate field with proper content type
          final multipartFile = await http.MultipartFile.fromPath(
            'pictures', // Field name
            file.path,
            contentType: contentType,
          );
          request.files.add(multipartFile);
          print(
              '📸 Added file: ${multipartFile.filename} (${multipartFile.length} bytes)');
        }
      } else {
        print('📸 === NO PICTURE FILES PROVIDED ===');
      }

      print('📤 Request URL: ${request.url}');
      print('📤 Request method: ${request.method}');
      print('📤 Request headers: ${request.headers}');
      print('📤 Request fields: ${request.fields}');
      print('📤 Request files count: ${request.files.length}');

      // Send request with manual token refresh handling
      http.Response response;
      try {
        print('📡 === SENDING MULTIPART REQUEST ===');
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);

        // Handle token refresh if needed
        if (response.statusCode == 401) {
          print('🔄 401 detected, refreshing token...');

          // Refresh token using SalonAuthService
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken == null) {
            throw Exception('No refresh token available');
          }

          final refreshResult = await SalonAuthService.refreshToken(
            refreshToken: refreshToken,
          );

          if (refreshResult['success'] == true) {
            print('✅ Token refreshed, retrying request...');

            // Extract and save new access token
            final newAccessToken = refreshResult['data']?['access_token'] ??
                refreshResult['data']?['accessToken'];

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await TokenStorageService.saveAccessToken(newAccessToken);
              print('💾 New access token saved');
            }

            // Get saved token for retry
            if (newAccessToken != null) {
              // Create new request with fresh token
              final retryRequest = http.MultipartRequest('PATCH', uri);
              retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';
              retryRequest.fields.addAll(request.fields);

              // Re-add files for retry
              if (pictureFiles != null && pictureFiles.isNotEmpty) {
                for (int i = 0; i < pictureFiles.length; i++) {
                  final file = pictureFiles[i];

                  // Determine content type based on file extension
                  String fileExtension =
                      file.path.toLowerCase().split('.').last;
                  MediaType contentType;
                  switch (fileExtension) {
                    case 'jpg':
                    case 'jpeg':
                      contentType = MediaType('image', 'jpeg');
                      break;
                    case 'png':
                      contentType = MediaType('image', 'png');
                      break;
                    case 'gif':
                      contentType = MediaType('image', 'gif');
                      break;
                    case 'webp':
                      contentType = MediaType('image', 'webp');
                      break;
                    default:
                      contentType =
                          MediaType('image', 'jpeg'); // Default fallback
                  }

                  final multipartFile = await http.MultipartFile.fromPath(
                    'pictures',
                    file.path,
                    contentType: contentType,
                  );
                  retryRequest.files.add(multipartFile);
                }
              }

              print('🔄 Retrying with fresh token...');
              final retryStreamedResponse = await retryRequest.send();
              response = await http.Response.fromStream(retryStreamedResponse);
            }
          }
        }
      } catch (e) {
        print('❌ Error sending request: $e');
        throw e;
      }

      final responseBody = response.body;

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: $responseBody');
      print('📄 Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        print('✅ Salon profile updated successfully');
        print('✅ Response Data: $responseData');
        return {
          'success': true,
          'data': responseData,
          'message':
              responseData['message'] ?? 'Salon profile updated successfully',
        };
      } else {
        print('❌ Failed to update salon profile: ${response.statusCode}');
        print('❌ Error Response: $responseBody');
        return {
          'success': false,
          'message': 'Failed to update salon profile: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error updating salon profile: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Upload images and get server URLs
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      print('📤 === UPLOADING IMAGES ===');
      print('📤 Images to upload: ${imageFiles.length}');

      final List<String> uploadedUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        print('📤 Uploading image $i: ${file.path}');

        // Create multipart request for image upload
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${HttpInterceptor.baseUrl}/upload/image'),
        );

        // Add authorization header
        final token = await TokenStorageService.getAccessToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Add file
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: file.path.split('/').last,
        );

        request.files.add(multipartFile);

        // Send request
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        print('📤 Image $i upload response: ${response.statusCode}');
        print('📤 Response body: $responseBody');

        if (response.statusCode == 200) {
          final responseData = json.decode(responseBody);
          final imageUrl = responseData['data']?['url'] ?? responseData['url'];
          if (imageUrl != null) {
            uploadedUrls.add(imageUrl);
            print('📤 ✅ Image $i uploaded successfully: $imageUrl');
          } else {
            print('📤 ❌ Image $i: No URL in response');
          }
        } else {
          print('📤 ❌ Image $i upload failed: ${response.statusCode}');
        }
      }

      print('📤 === UPLOAD COMPLETE ===');
      print(
          '📤 Successfully uploaded: ${uploadedUrls.length}/${imageFiles.length} images');
      print('📤 Uploaded URLs: $uploadedUrls');

      return uploadedUrls;
    } catch (e) {
      print('📤 ❌ Error uploading images: $e');
      return [];
    }
  }

  // Helper method to build form data body for salon profile update
  String _buildFormDataBody(String? openingHour, String? closingHour,
      String? description, List<String>? pictures) {
    final Map<String, String> fields = {};
    if (openingHour != null && openingHour.isNotEmpty) {
      fields['openingHour'] = openingHour;
    }
    if (closingHour != null && closingHour.isNotEmpty) {
      fields['closingHour'] = closingHour;
    }
    if (description != null && description.isNotEmpty) {
      fields['description'] = description;
    }
    if (pictures != null && pictures.isNotEmpty) {
      for (int i = 0; i < pictures.length; i++) {
        fields['pictures[$i]'] = pictures[i];
      }
    }
    return fields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
  }
}
