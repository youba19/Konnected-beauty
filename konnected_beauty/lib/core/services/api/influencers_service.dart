import 'dart:convert';
import 'http_interceptor.dart';
import '../storage/token_storage_service.dart';
import '../../models/filter_model.dart';

class InfluencersService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  /// Fetch all influencers with dynamic filter support
  static Future<Map<String, dynamic>> getInfluencersWithFilters({
    List<FilterModel> filters = const [],
  }) async {
    try {
      print('👥 === FETCHING INFLUENCERS WITH FILTERS ===');
      print('🔍 Filters Count: ${filters.length}');

      // Build query parameters from enabled filters
      final queryParams = <String, String>{};

      for (final filter in filters) {
        if (filter.enabled) {
          print('🔍 Adding filter: ${filter.key} = ${filter.value}');
          queryParams[filter.key] = filter.value;
        }
      }

      // Ensure we have at least page and limit
      if (!queryParams.containsKey('page')) {
        queryParams['page'] = '1';
      }
      if (!queryParams.containsKey('limit')) {
        queryParams['limit'] = '10';
      }
      if (!queryParams.containsKey('sortOrder')) {
        queryParams['sortOrder'] = 'DESC';
      }

      print('🔗 Query Parameters: $queryParams');

      final uri = Uri.parse('$baseUrl/influencer')
          .replace(queryParameters: queryParams);

      print('🔗 Request URL: $uri');
      print('🔧 Using HTTP interceptor for automatic token management');

      // Check authentication status before making request
      print('🔐 === CHECKING AUTH STATUS BEFORE REQUEST ===');
      final accessToken = await TokenStorageService.getAccessToken();
      final refreshToken = await TokenStorageService.getRefreshToken();
      final userRole = await TokenStorageService.getUserRole();
      final userEmail = await TokenStorageService.getUserEmail();
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'NULL'}');
      print('🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'NULL'}');
      print('👤 User Role: $userRole');
      print('📧 User Email: $userEmail');
      print('🔐 === END AUTH STATUS CHECK ===');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('🔍 === INFLUENCERS SERVICE DEBUG ===');
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body Length: ${response.body.length}');
      print(
          '🔍 Response Body Preview: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');
      print('🔍 === END INFLUENCERS SERVICE DEBUG ===');

      // Check if we got 401 and need to refresh token
      if (response.statusCode == 401) {
        print('🔐 === 401 UNAUTHORIZED DETECTED ===');
        print('🔐 This should trigger token refresh in HTTP interceptor');
        print('🔐 === END 401 DETECTED ===');
      }

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Influencers fetched successfully with filters');
        print('📊 Total Influencers: ${responseData['data']?.length ?? 0}');
        print('📄 Current Page: ${responseData['currentPage']}');
        print('📄 Total Pages: ${responseData['totalPages']}');

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Influencers fetched successfully',
          'data': responseData['data'] ?? [],
          'currentPage': responseData['currentPage'] ?? 1,
          'totalPages': responseData['totalPages'] ?? 1,
          'total': responseData['total'] ?? 0,
          'statusCode': response.statusCode,
        };
      } else {
        print(
            '❌ Failed to fetch influencers with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to fetch influencers: ${response.statusCode}';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
            'errorDetails': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to fetch influencers: ${response.statusCode}',
            'statusCode': response.statusCode,
            'rawResponse': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Exception in getInfluencersWithFilters: $e');
      return {
        'success': false,
        'message': 'Error fetching influencers: $e',
        'statusCode': 0,
      };
    }
  }

  /// Fetch all influencers with pagination and filtering support (legacy method)
  static Future<Map<String, dynamic>> getInfluencers({
    int page = 1,
    int limit = 10,
    String? search,
    String? zone,
    String? sortOrder = 'DESC',
  }) async {
    try {
      print('👥 === FETCHING INFLUENCERS ===');
      print('📄 Page: $page');
      print('📏 Limit: $limit');
      print('🔍 Search: ${search ?? 'None'}');
      print('🔗 URL: $baseUrl/influencer');

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortOrder': sortOrder ?? 'DESC',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (zone != null && zone.isNotEmpty) {
        queryParams['zone'] = zone;
      }

      final uri = Uri.parse('$baseUrl/influencer')
          .replace(queryParameters: queryParams);

      print('🔗 Request URL: $uri');
      print('🔧 Using HTTP interceptor for automatic token management');

      // Check authentication status before making request
      print('🔐 === CHECKING AUTH STATUS BEFORE REQUEST ===');
      final accessToken = await TokenStorageService.getAccessToken();
      final refreshToken = await TokenStorageService.getRefreshToken();
      final userRole = await TokenStorageService.getUserRole();
      final userEmail = await TokenStorageService.getUserEmail();
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'NULL'}');
      print('🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'NULL'}');
      print('👤 User Role: $userRole');
      print('📧 User Email: $userEmail');
      print('🔐 === END AUTH STATUS CHECK ===');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('🔍 === INFLUENCERS SERVICE DEBUG ===');
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body Length: ${response.body.length}');
      print(
          '🔍 Response Body Preview: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');
      print('🔍 === END INFLUENCERS SERVICE DEBUG ===');

      // Check if we got 401 and need to refresh token
      if (response.statusCode == 401) {
        print('🔐 === 401 UNAUTHORIZED DETECTED ===');
        print('🔐 This should trigger token refresh in HTTP interceptor');
        print('🔐 === END 401 DETECTED ===');
      }

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Influencers fetched successfully');
        print('📊 Total Influencers: ${responseData['data']?.length ?? 0}');
        print('📄 Current Page: ${responseData['currentPage']}');
        print('📄 Total Pages: ${responseData['totalPages']}');

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Influencers fetched successfully',
          'data': responseData['data'] ?? [],
          'currentPage': responseData['currentPage'] ?? 1,
          'totalPages': responseData['totalPages'] ?? 1,
          'total': responseData['total'] ?? 0,
          'statusCode': response.statusCode,
        };
      } else {
        print(
            '❌ Failed to fetch influencers with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to fetch influencers: ${response.statusCode}';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
            'errorDetails': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to fetch influencers: ${response.statusCode}',
            'statusCode': response.statusCode,
            'rawResponse': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Exception in getInfluencers: $e');
      return {
        'success': false,
        'message': 'Error fetching influencers: $e',
        'statusCode': 0,
      };
    }
  }

  /// Fetch influencer details by ID
  static Future<Map<String, dynamic>> getInfluencerDetails(
      String influencerId) async {
    try {
      print('👤 === FETCHING INFLUENCER DETAILS ===');
      print('🆔 Influencer ID: $influencerId');

      // Check authentication status before making request
      print('🔐 === CHECKING AUTH STATUS BEFORE REQUEST ===');
      final accessToken = await TokenStorageService.getAccessToken();
      final refreshToken = await TokenStorageService.getRefreshToken();
      final userRole = await TokenStorageService.getUserRole();
      final userEmail = await TokenStorageService.getUserEmail();
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'NULL'}');
      print('🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'NULL'}');
      print('👤 User Role: $userRole');
      print('📧 User Email: $userEmail');
      print('🔐 === END AUTH STATUS CHECK ===');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer/details/$influencerId',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 === INFLUENCER DETAILS SERVICE DEBUG ===');
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body Length: ${response.body.length}');
      print('🔍 Response Body: ${response.body}');
      print('🔍 === END INFLUENCER DETAILS SERVICE DEBUG ===');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Influencer details fetched successfully');
        print('📊 Data: ${responseData['data']}');

        return {
          'success': true,
          'message': responseData['message'] ??
              'Influencer details fetched successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        print(
            '❌ Failed to fetch influencer details with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to fetch influencer details: ${response.statusCode}';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
            'errorDetails': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Failed to fetch influencer details: ${response.statusCode}',
            'statusCode': response.statusCode,
            'rawResponse': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Exception in getInfluencerDetails: $e');
      return {
        'success': false,
        'message': 'Error fetching influencer details: $e',
        'statusCode': 0,
      };
    }
  }

  /// Invite influencer for campaign
  static Future<Map<String, dynamic>> inviteInfluencer({
    required String receiverId,
    required int promotion,
    required String promotionType,
    required String invitationMessage,
  }) async {
    try {
      print('📧 === INVITING INFLUENCER FOR CAMPAIGN ===');
      print('🆔 Receiver ID: $receiverId');
      print('💰 Promotion: $promotion');
      print('📊 Promotion Type: $promotionType');
      print('💬 Message: $invitationMessage');

      // Validate promotion value based on type
      if (promotionType == 'percentage' && (promotion < 0 || promotion > 100)) {
        return {
          'success': false,
          'message': 'Percentage promotions must be between 0 and 100',
          'statusCode': 400,
        };
      }

      final requestBody = {
        'receiverId': receiverId,
        'promotion': promotion,
        'promotionType': promotionType,
        'invitationMessage': invitationMessage,
      };

      print('📤 Request Body: $requestBody');

      // Check authentication status before making request
      print('🔐 === CHECKING AUTH STATUS BEFORE REQUEST ===');
      final accessToken = await TokenStorageService.getAccessToken();
      final refreshToken = await TokenStorageService.getRefreshToken();
      final userRole = await TokenStorageService.getUserRole();
      final userEmail = await TokenStorageService.getUserEmail();
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'NULL'}');
      print('🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'NULL'}');
      print('👤 User Role: $userRole');
      print('📧 User Email: $userEmail');
      print('🔐 === END AUTH STATUS CHECK ===');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/invite-influencer',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('🔍 === INVITE INFLUENCER SERVICE DEBUG ===');
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body Length: ${response.body.length}');
      print('🔍 Response Body: ${response.body}');
      print('🔍 === END INVITE INFLUENCER SERVICE DEBUG ===');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Influencer invited successfully');
        print('📊 Campaign Data: ${responseData['data']}');

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Influencer invited successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        print(
            '❌ Failed to invite influencer with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ??
              errorData['error'] ??
              'Failed to invite influencer: ${response.statusCode}';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
            'errorDetails': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to invite influencer: ${response.statusCode}',
            'statusCode': response.statusCode,
            'rawResponse': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Exception in inviteInfluencer: $e');
      return {
        'success': false,
        'message': 'Error inviting influencer: $e',
        'statusCode': 0,
      };
    }
  }

  /// Delete campaign invite
  static Future<Map<String, dynamic>> deleteCampaignInvite({
    required String campaignId,
  }) async {
    try {
      print('🗑️ === DELETING CAMPAIGN INVITE ===');
      print('🆔 Campaign ID: $campaignId');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/delete-campaign-invite',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {
          'campaignId': campaignId,
        },
      );

      print('🔍 === DELETE CAMPAIGN INVITE SERVICE DEBUG ===');
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body Length: ${response.body.length}');
      print('🔍 Response Body: ${response.body}');
      print('🔍 === END DELETE CAMPAIGN INVITE SERVICE DEBUG ===');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Campaign invite deleted successfully');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to delete campaign invite';

        if (errorData['message'] != null) {
          if (errorData['message'] is List) {
            errorMessage = (errorData['message'] as List).join(', ');
          } else {
            errorMessage = errorData['message'].toString();
          }
        }

        print('❌ Failed to delete campaign invite: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error deleting campaign invite: $e');
      return {
        'success': false,
        'message': 'Error deleting campaign invite: $e',
      };
    }
  }

  /// Fetch salon campaigns
  static Future<Map<String, dynamic>> getSalonCampaigns({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    try {
      print('📊 === FETCHING SALON CAMPAIGNS ===');
      print('📄 Page: $page');
      print('📏 Limit: $limit');
      print('🔍 Search: "${search ?? 'None'}"');
      print('🔍 Search Type: ${search.runtimeType}');
      print('🔍 Search Length: ${search?.length ?? 0}');
      print('🔍 Search Is Empty: ${search?.isEmpty ?? true}');
      print('📊 Status: ${status ?? 'None'}');

      // Build query parameters with mixed types
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      queryParams['page'] = page; // Keep as int
      queryParams['limit'] = limit; // Keep as int
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        print('🔍 === SEARCH PARAMETER ADDED ===');
        print('🔍 Search Value: "${search}"');
        print('🔍 Search Length: ${search.length}');
        print(
            '🔍 Search Added to QueryParams: ${queryParams.containsKey('search')}');
      } else {
        print('🔍 === NO SEARCH PARAMETER ===');
        print(
            '🔍 Search is null or empty: ${search == null || search.isEmpty}');
      }

      print('🔗 Query Parameters: $queryParams');
      print('🔗 Query Parameters Type: ${queryParams.runtimeType}');
      print(
          '🔗 Page Value: ${queryParams['page']} (${queryParams['page'].runtimeType})');
      print(
          '🔗 Limit Value: ${queryParams['limit']} (${queryParams['limit'].runtimeType})');
      if (queryParams.containsKey('status')) {
        print(
            '🔗 Status Value: ${queryParams['status']} (${queryParams['status'].runtimeType})');
      }
      print('🔗 Using GET with form data in body');

      // Check authentication status before making request
      print('🔐 === CHECKING AUTH STATUS BEFORE REQUEST ===');
      final accessToken = await TokenStorageService.getAccessToken();
      final refreshToken = await TokenStorageService.getRefreshToken();
      final userRole = await TokenStorageService.getUserRole();
      final userEmail = await TokenStorageService.getUserEmail();
      print('🔑 Access Token: ${accessToken != null ? 'Present' : 'NULL'}');
      print('🔄 Refresh Token: ${refreshToken != null ? 'Present' : 'NULL'}');
      print('👤 User Role: $userRole');
      print('📧 User Email: $userEmail');
      print('🔐 === END AUTH STATUS CHECK ===');

      // Use GET with form data in body (API expects this format)
      print('🌐 === MAKING HTTP REQUEST ===');
      print('🌐 Method: GET');
      print('🌐 Endpoint: /campaign/salon-campaigns');
      print('🌐 Query Parameters: $queryParams');
      print(
          '🌐 Search in Query Params: ${queryParams.containsKey('search') ? queryParams['search'] : 'NOT FOUND'}');

      // Build the full URL to see exactly what's being sent
      final uri = Uri.parse('$baseUrl/campaign/salon-campaigns').replace(
        queryParameters:
            queryParams.map((key, value) => MapEntry(key, value.toString())),
      );
      print('🌐 Full URL: $uri');
      print('🌐 URL Query String: ${uri.query}');
      print('🌐 URL Query Parameters: ${uri.queryParameters}');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/campaign/salon-campaigns',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('🌐 === HTTP RESPONSE RECEIVED ===');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Body Length: ${response.body.length}');

      print('🔍 === SALON CAMPAIGNS SERVICE DEBUG ===');
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body Length: ${response.body.length}');
      print('🔍 Response Body: ${response.body}');
      print('🔍 === END SALON CAMPAIGNS SERVICE DEBUG ===');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Salon campaigns fetched successfully');
        print('📊 Total Campaigns: ${responseData['data']?.length ?? 0}');
        print('📄 Current Page: ${responseData['currentPage']}');
        print('📄 Total Pages: ${responseData['totalPages']}');

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Campaigns fetched successfully',
          'data': responseData['data'] ?? [],
          'currentPage': responseData['currentPage'] ?? 1,
          'totalPages': responseData['totalPages'] ?? 1,
          'total': responseData['total'] ?? 0,
          'statusCode': response.statusCode,
        };
      } else {
        print(
            '❌ Failed to fetch salon campaigns with status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');

        // Try to parse error response for more details
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage =
              'Failed to fetch campaigns: ${response.statusCode}';

          if (errorData['message'] != null) {
            if (errorData['message'] is List) {
              errorMessage = (errorData['message'] as List).join(', ');
            } else if (errorData['message'] is String) {
              errorMessage = errorData['message'];
            }
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
            'errorDetails': errorData,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to fetch campaigns: ${response.statusCode}',
            'statusCode': response.statusCode,
            'rawResponse': response.body,
          };
        }
      }
    } catch (e) {
      print('❌ Exception in getSalonCampaigns: $e');
      return {
        'success': false,
        'message': 'Error fetching campaigns: $e',
        'statusCode': 0,
      };
    }
  }
}
