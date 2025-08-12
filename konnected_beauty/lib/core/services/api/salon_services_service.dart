import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage_service.dart';

class SalonServicesService {
  static const String baseUrl = 'http://srv950342.hstgr.cloud:3000';

  // Salon services endpoint
  static const String servicesEndpoint = '/salon-service';

  // Headers for API requests
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  /// Get salon services with optional filtering
  static Future<Map<String, dynamic>> getServices({
    double? minPrice,
    double? maxPrice,
    String? search,
    String? category,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    try {
      // Get access token for authentication
      final accessToken = await TokenStorageService.getAccessToken();

      // Build headers with authentication
      final Map<String, String> requestHeaders = Map.from(headers);
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }

      // Build query parameters
      final Map<String, String> queryParams = {};

      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }

      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sortOrder'] = sortOrder;
      }

      if (page != null) {
        queryParams['page'] = page.toString();
      }

      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      // Build URL with query parameters
      final Uri uri = Uri.parse('$baseUrl$servicesEndpoint')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: requestHeaders,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
          'statusCode': responseData['statusCode'],
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch services',
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

  /// Get service categories
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      // Get access token for authentication
      final accessToken = await TokenStorageService.getAccessToken();

      // Build headers with authentication
      final Map<String, String> requestHeaders = Map.from(headers);
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/salon-service/categories'),
        headers: requestHeaders,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch categories',
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

  /// Get service by ID
  static Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    try {
      // Get access token for authentication
      final accessToken = await TokenStorageService.getAccessToken();

      // Build headers with authentication
      final Map<String, String> requestHeaders = Map.from(headers);
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl$servicesEndpoint/$serviceId'),
        headers: requestHeaders,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch service',
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

  /// Search services with text
  static Future<Map<String, dynamic>> searchServices(String searchText) async {
    return getServices(search: searchText);
  }

  /// Filter services by price range
  static Future<Map<String, dynamic>> filterByPrice({
    required double minPrice,
    required double maxPrice,
  }) async {
    return getServices(minPrice: minPrice, maxPrice: maxPrice);
  }

  /// Filter services by category
  static Future<Map<String, dynamic>> filterByCategory(String category) async {
    return getServices(category: category);
  }

  /// Sort services
  static Future<Map<String, dynamic>> sortServices({
    required String sortBy,
    String sortOrder = 'asc',
  }) async {
    return getServices(sortBy: sortBy, sortOrder: sortOrder);
  }

  /// Create a new salon service
  static Future<Map<String, dynamic>> createSalonService({
    required String name,
    required int price,
    required String description,
  }) async {
    try {
      // Get access token for authentication
      final accessToken = await TokenStorageService.getAccessToken();

      // Build headers with authentication
      final Map<String, String> requestHeaders = Map.from(headers);
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.post(
        Uri.parse('$baseUrl$servicesEndpoint'),
        headers: requestHeaders,
        body: jsonEncode({
          'name': name,
          'price': price,
          'description': description,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create service',
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

  /// Update an existing salon service
  static Future<Map<String, dynamic>> updateSalonService({
    required String serviceId,
    String? name,
    int? price,
    String? description,
  }) async {
    try {
      // Get access token for authentication
      final accessToken = await TokenStorageService.getAccessToken();

      // Build headers with authentication
      final Map<String, String> requestHeaders = Map.from(headers);
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }

      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (price != null) updateData['price'] = price;
      if (description != null) updateData['description'] = description;

      final response = await http.patch(
        Uri.parse('$baseUrl$servicesEndpoint/$serviceId'),
        headers: requestHeaders,
        body: jsonEncode(updateData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update service',
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

  /// Delete a salon service
  static Future<Map<String, dynamic>> deleteSalonService({
    required String serviceId,
  }) async {
    try {
      // Get access token for authentication
      final accessToken = await TokenStorageService.getAccessToken();

      // Build headers with authentication
      final Map<String, String> requestHeaders = Map.from(headers);
      if (accessToken != null) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl$servicesEndpoint/$serviceId'),
        headers: requestHeaders,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete service',
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

  /// Refresh authentication token
  static Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/salon-auth/refresh-token'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $refreshToken',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
          'statusCode': responseData['statusCode'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to refresh token',
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
