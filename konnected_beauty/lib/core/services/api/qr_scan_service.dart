import 'dart:convert';
import 'http_interceptor.dart';

class QRScanService {
  /// Get detailed order information by order ID
  ///
  /// [orderId] - The order ID to fetch details for
  ///
  /// Returns a Map containing the complete order details or error information
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      print('🔍 === FETCHING ORDER DETAILS ===');
      print('🆔 Order ID: $orderId');

      // Validate order ID
      if (orderId.isEmpty) {
        return {
          'success': false,
          'message': 'Order ID cannot be empty',
          'error': 'INVALID_ORDER_ID'
        };
      }

      // Use the existing HTTP interceptor for authenticated requests
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/orders/$orderId',
        queryParameters: null,
      );

      print('🌐 === ORDER DETAILS API RESPONSE ===');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Order details fetched successfully');
        print('📦 Order Data: $responseData');

        return {
          'success': true,
          'message': 'Order details fetched successfully',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Order not found',
          'error': 'ORDER_NOT_FOUND'
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Invalid order ID format',
          'error': 'INVALID_ORDER_ID_FORMAT'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch order details. Please try again.',
          'error': 'FETCH_FAILED'
        };
      }
    } catch (e) {
      print('❌ Order Details Error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'error': 'NETWORK_ERROR'
      };
    }
  }

  /// Scan a QR code voucher and get order details
  ///
  /// [voucher] - The voucher code from the QR code (e.g., "VOU-OiRwVu12")
  ///
  /// Returns a Map containing the order details or error information
  static Future<Map<String, dynamic>> scanVoucher(String voucher) async {
    try {
      print('🔍 === SCANNING QR VOUCHER ===');
      print('🎫 Voucher Code: $voucher');

      // Validate voucher format
      if (voucher.isEmpty) {
        return {
          'success': false,
          'message': 'Voucher code cannot be empty',
          'error': 'INVALID_VOUCHER'
        };
      }

      // Use the existing HTTP interceptor for authenticated requests
      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/orders/scan/$voucher',
        queryParameters: null,
      );

      print('🌐 === QR SCAN API RESPONSE ===');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Body: ${response.body}');

      // Success: 200 (isSettled) or 201 (order completed, transfers scheduled)
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ QR Scan successful (${response.statusCode})');
        print('📦 Response Data: $responseData');

        // Check if the response contains orderId in the data
        if (responseData['data'] != null &&
            responseData['data']['orderId'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          print('📦 Order ID found: ${data['orderId']}');
          if (data['availableDate'] != null) {
            print('📦 Available date: ${data['availableDate']}');
          }
          return {
            'success': true,
            'message':
                responseData['message'] ?? 'Voucher scanned successfully',
            'statusCode': response.statusCode,
            'data': data,
          };
        } else {
          print('❌ No orderId found in response data');
          return {
            'success': false,
            'message': 'Invalid response format - orderId not found',
            'error': 'INVALID_RESPONSE_FORMAT'
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Voucher not found or invalid',
          'error': 'VOUCHER_NOT_FOUND'
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': 'Invalid voucher format',
          'error': 'INVALID_VOUCHER_FORMAT'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to scan voucher. Please try again.',
          'error': 'SCAN_FAILED'
        };
      }
    } catch (e) {
      print('❌ QR Scan Error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'error': 'NETWORK_ERROR'
      };
    }
  }
}
