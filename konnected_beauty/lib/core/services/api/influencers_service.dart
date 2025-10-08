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
          // Try different parameter names for search
          if (filter.key == 'search') {
            queryParams['q'] = filter.value; // Try 'q' instead of 'search'
            queryParams['query'] = filter.value; // Try 'query' as well
            queryParams['search'] = filter.value; // Keep original too
            print(
                '🔍 Added multiple search parameters: q=${filter.value}, query=${filter.value}, search=${filter.value}');
          } else {
            queryParams[filter.key] = filter.value;
          }
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
      print('🔗 Search Parameter: ${queryParams['search']}');

      final uri = Uri.parse('$baseUrl/influencer')
          .replace(queryParameters: queryParams);

      print('🔗 Request URL: $uri');
      print('🔗 Full URL with search: $uri');
      print('🔗 Search in URL: ${uri.queryParameters['search']}');
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
      queryParams['sort'] = 'createdAt'; // Sort by creation date
      queryParams['order'] = 'desc'; // Descending order (newest first)
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

  /// Fetch influencer campaigns
  static Future<Map<String, dynamic>> getInfluencerCampaigns({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      print('📊 === FETCHING INFLUENCER CAMPAIGNS ===');
      print('📄 Page: $page');
      print('📏 Limit: $limit');
      print('📊 Status: ${status ?? 'None'}');

      // Build query parameters
      final queryParams = <String, dynamic>{};
      queryParams['page'] = page;
      queryParams['limit'] = limit;
      queryParams['sort'] = 'createdAt'; // Sort by creation date
      queryParams['order'] = 'desc'; // Descending order (newest first)
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      print('🔗 Query Parameters: $queryParams');

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
        endpoint: '/campaign/influencer-campaigns',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        queryParameters: queryParams,
      );

      print('🔍 === INFLUENCER CAMPAIGNS SERVICE DEBUG ===');
      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Headers: ${response.headers}');
      print('🔍 Response Body Length: ${response.body.length}');
      print('🔍 Response Body: ${response.body}');
      print('🔍 === END INFLUENCER CAMPAIGNS SERVICE DEBUG ===');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Influencer campaigns fetched successfully');
        print('📊 Total Campaigns: ${responseData['data']?.length ?? 0}');
        print('📄 Current Page: ${responseData['currentPage']}');
        print('📄 Total Pages: ${responseData['totalPages']}');

        // Process the campaigns data to match the expected format
        final List<dynamic> rawCampaigns = responseData['data'] ?? [];
        final List<Map<String, dynamic>> processedCampaigns =
            rawCampaigns.map((campaign) {
          final salon = campaign['salon'] as Map<String, dynamic>? ?? {};
          final salonInfo = salon['salonInfo'] as Map<String, dynamic>? ?? {};

          return {
            'id': campaign['id'],
            'createdAt': campaign['createdAt'],
            'updatedAt': campaign['updatedAt'],
            'status': campaign['status'],
            'promotion': campaign['promotion'],
            'promotionType': campaign['promotionType'],
            'invitationMessage': campaign['invitationMessage'],
            'initiator': campaign['initiator'],
            'clicks': campaign['clicks'],
            'salonName': salonInfo['name'] ?? 'Unknown Salon',
            'salonDomain': salonInfo['domain'] ?? 'Unknown Domain',
            'salonAddress': salonInfo['address'] ?? 'Unknown Address',
            'salon': salon,
          };
        }).toList();

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Campaigns fetched successfully',
          'data': processedCampaigns,
          'currentPage': responseData['currentPage'] ?? 1,
          'totalPages': responseData['totalPages'] ?? 1,
          'total': responseData['total'] ?? 0,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 403) {
        print('❌ Account not active - 403 Forbidden');
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Account not active',
          'statusCode': response.statusCode,
          'errorDetails': responseData,
        };
      } else {
        print(
            '❌ Failed to fetch influencer campaigns with status: ${response.statusCode}');
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
      print('❌ Exception in getInfluencerCampaigns: $e');
      return {
        'success': false,
        'message': 'Error fetching campaigns: $e',
        'statusCode': 0,
      };
    }
  }

  /// Accept campaign (for salon when influencer initiated)
  static Future<Map<String, dynamic>> acceptCampaign({
    required String campaignId,
  }) async {
    try {
      print('✅ === ACCEPTING CAMPAIGN ===');
      print('🆔 Campaign ID: $campaignId');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/accept-campaign',
        body: jsonEncode({'campaignId': campaignId}),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Campaign accepted successfully',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Bad request',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Forbidden - Account not active',
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to accept campaign',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in acceptCampaign: $e');
      return {
        'success': false,
        'message': 'Error accepting campaign: $e',
        'statusCode': 500,
      };
    }
  }

  /// Accept influencer invite (for salon when influencer initiated)
  static Future<Map<String, dynamic>> acceptInfluencerInvite({
    required String campaignId,
  }) async {
    try {
      print('✅ === ACCEPTING INFLUENCER INVITE ===');
      print('🆔 Campaign ID: $campaignId');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/accept-influencer-invite',
        body: jsonEncode({'campaignId': campaignId}),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Campaign accepted successfully',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Bad request',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Forbidden - Account not active',
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to accept campaign',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in acceptInfluencerInvite: $e');
      return {
        'success': false,
        'message': 'Error accepting campaign: $e',
        'statusCode': 500,
      };
    }
  }

  /// Refuse campaign (for salon when influencer initiated)
  static Future<Map<String, dynamic>> refuseCampaign({
    required String campaignId,
  }) async {
    try {
      print('❌ === REFUSING CAMPAIGN ===');
      print('🆔 Campaign ID: $campaignId');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/reject-influencer-invite',
        body: jsonEncode({'campaignId': campaignId}),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Campaign refused successfully',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Bad request',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Forbidden - Account not active',
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to refuse campaign',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in refuseCampaign: $e');
      return {
        'success': false,
        'message': 'Error refusing campaign: $e',
        'statusCode': 500,
      };
    }
  }

  /// Delete influencer campaign invitation
  static Future<Map<String, dynamic>> deleteInfluencerCampaignInvite({
    required String campaignId,
  }) async {
    try {
      print('🗑️ === DELETE CAMPAIGN INVITATION ===');
      print('🗑️ Campaign ID: $campaignId');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/delete-influencer-campaign-invite',
        body: jsonEncode({
          'campaignId': campaignId,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🗑️ Response Status: ${response.statusCode}');
      print('🗑️ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ??
              'Campaign invitation deleted successfully',
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to delete campaign invitation',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in deleteInfluencerCampaignInvite: $e');
      return {
        'success': false,
        'message': 'Error deleting campaign invitation: $e',
        'statusCode': 500,
      };
    }
  }

  /// Fetch payment information
  static Future<Map<String, dynamic>> getPaymentInformation() async {
    try {
      print('💳 === FETCHING PAYMENT INFORMATION ===');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer/payment-information',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('💳 Response Status: ${response.statusCode}');
      print('💳 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ??
              'Payment information fetched successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch payment information',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in getPaymentInformation: $e');
      return {
        'success': false,
        'message': 'Error fetching payment information: $e',
        'statusCode': 500,
      };
    }
  }

  /// Update payment information
  static Future<Map<String, dynamic>> updatePaymentInformation({
    required String businessName,
    required String registryNumber,
    required String iban,
  }) async {
    try {
      print('💳 === UPDATING PAYMENT INFORMATION ===');
      print('💳 Business Name: $businessName');
      print('💳 Registry Number: $registryNumber');
      print('💳 IBAN: $iban');

      final body = {
        'businessName': businessName,
        'registryNumber': registryNumber,
        'IBAN': iban,
      };

      print('💳 Request Body: ${jsonEncode(body)}');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'PATCH',
        endpoint: '/influencer/payment-information',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('💳 Response Status: ${response.statusCode}');
      print('💳 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ??
              'Payment information updated successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to update payment information',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in updatePaymentInformation: $e');
      return {
        'success': false,
        'message': 'Error updating payment information: $e',
        'statusCode': 500,
      };
    }
  }

  /// Get campaign details with link for influencer campaigns
  static Future<Map<String, dynamic>> getInfluencerCampaignDetails({
    required String campaignId,
  }) async {
    try {
      print('📋 === FETCHING INFLUENCER CAMPAIGN DETAILS ===');
      print('📋 Campaign ID: $campaignId');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/campaign/influencer-campaign/$campaignId',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📋 Response Status: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ??
              'Campaign details fetched successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch campaign details',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in getInfluencerCampaignDetails: $e');
      return {
        'success': false,
        'message': 'Error fetching campaign details: $e',
        'statusCode': 500,
      };
    }
  }

  /// Accept salon invite for influencer campaigns
  static Future<Map<String, dynamic>> acceptSalonInvite({
    required String campaignId,
  }) async {
    try {
      print('✅ === ACCEPTING SALON INVITE ===');
      print('✅ Campaign ID: $campaignId');

      final body = {
        'campaignId': campaignId,
      };

      print('✅ Request Body: ${jsonEncode(body)}');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/accept-salon-invite',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('✅ Response Status: ${response.statusCode}');
      print('✅ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Campaign accepted successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to accept campaign',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in acceptSalonInvite: $e');
      return {
        'success': false,
        'message': 'Error accepting campaign: $e',
        'statusCode': 500,
      };
    }
  }

  /// Reject salon invite for influencer campaigns
  static Future<Map<String, dynamic>> rejectSalonInvite({
    required String campaignId,
  }) async {
    try {
      print('❌ === REJECTING SALON INVITE ===');
      print('❌ Campaign ID: $campaignId');

      final body = {
        'campaignId': campaignId,
      };

      print('❌ Request Body: ${jsonEncode(body)}');

      // Use the HTTP interceptor for automatic token management
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/reject-salon-invite',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('❌ Response Status: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Campaign rejected successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reject campaign',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in rejectSalonInvite: $e');
      return {
        'success': false,
        'message': 'Error rejecting campaign: $e',
        'statusCode': 500,
      };
    }
  }

  /// Finish campaign
  static Future<Map<String, dynamic>> finishCampaign({
    required String campaignId,
  }) async {
    try {
      print('🏁 === FINISHING CAMPAIGN ===');
      print('🏁 Campaign ID: $campaignId');

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
        'campaignId': campaignId,
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/finish-campaign',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('🏁 Response Status: ${response.statusCode}');
      print('🏁 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Campaign finished successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to finish campaign',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in finishCampaign: $e');
      return {
        'success': false,
        'message': 'Error finishing campaign: $e',
        'statusCode': 500,
      };
    }
  }

  /// Rate influencer
  static Future<Map<String, dynamic>> rateInfluencer({
    required String campaignId,
    required int stars,
    required String comment,
  }) async {
    try {
      print('⭐ === RATING INFLUENCER ===');
      print('⭐ Campaign ID: $campaignId');
      print('⭐ Stars: $stars');
      print('⭐ Comment: $comment');

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
        'campaignId': campaignId,
        'stars': stars,
        'comment': comment,
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/campaign/rate-influencer',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Rating submitted successfully',
          'data': responseData['data'],
          'statusCode': response.statusCode,
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit rating',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in rateInfluencer: $e');
      return {
        'success': false,
        'message': 'Error submitting rating: $e',
        'statusCode': 500,
      };
    }
  }
}
