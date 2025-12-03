import 'dart:convert';
import 'http_interceptor.dart';

class SalonWalletService {
  static const String baseUrl = 'https://server.konectedbeauty.com';

  /// Get salon wallet balance
  static Future<Map<String, dynamic>> getBalance() async {
    try {
      print('💰 === FETCHING SALON WALLET BALANCE ===');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon-wallet/balance',
      );

      print('💰 Balance API Response Status: ${response.statusCode}');
      print('💰 Balance API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('💰 Parsed Response: $responseData');

        if (responseData['statusCode'] == 200 &&
            responseData['message'] == 'success') {
          final balance = responseData['data']?['balance'] ?? 0.0;
          print('💰 Extracted Balance: $balance');

          return {
            'success': true,
            'balance': balance,
            'message': 'Balance fetched successfully',
          };
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch balance',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error fetching salon wallet balance: $e');
      return {
        'success': false,
        'message': 'Error fetching balance: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// Get salon statistics
  static Future<Map<String, dynamic>> getStats() async {
    try {
      print('📊 === FETCHING SALON STATS ===');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon-stats',
      );

      print('📊 Stats API Response Status: ${response.statusCode}');
      print('📊 Stats API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('📊 Parsed Response: $responseData');

        if (responseData['statusCode'] == 200 &&
            responseData['message'] == 'success') {
          final data = responseData['data'] ?? {};

          final stats = {
            'averageOrderValue':
                (data['averageOrderValue']?['current'] ?? 0.0).toDouble(),
            'averageOrderValueChange':
                (data['averageOrderValue']?['changePercentage'] ?? 0.0)
                    .toDouble(),
            'totalOrderCount':
                (data['totalOrderCount']?['current'] ?? 0).toInt(),
            'totalOrderCountChange':
                (data['totalOrderCount']?['changePercentage'] ?? 0.0)
                    .toDouble(),
            'completedOrderCount':
                (data['completedOrderCount']?['current'] ?? 0).toInt(),
            'completedOrderCountChange':
                (data['completedOrderCount']?['changePercentage'] ?? 0.0)
                    .toDouble(),
            'totalRevenue':
                (data['totalRevenue']?['current'] ?? 0.0).toDouble(),
            'totalRevenueChange':
                (data['totalRevenue']?['changePercentage'] ?? 0.0).toDouble(),
          };

          print('📊 Extracted Stats: $stats');

          return {
            'success': true,
            'stats': stats,
            'message': 'Stats fetched successfully',
          };
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch stats',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error fetching salon stats: $e');
      return {
        'success': false,
        'message': 'Error fetching stats: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// Get salon three-months statistics for charts
  static Future<Map<String, dynamic>> getThreeMonthsStats() async {
    try {
      print('📈 === FETCHING SALON THREE-MONTHS STATS ===');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon-stats/three-months',
      );

      print(
          '📈 Three-Months Stats API Response Status: ${response.statusCode}');
      print('📈 Three-Months Stats API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('📈 Parsed Response: $responseData');

        if (responseData['statusCode'] == 200 &&
            responseData['message'] == 'success') {
          final data = responseData['data'] ?? {};

          final threeMonthsStats = {
            'orderTrend': {
              'trends': data['orderTrend']?['trends'] ?? [],
              'currentValue':
                  (data['orderTrend']?['currentValue'] ?? 0).toInt(),
              'changePercentage':
                  (data['orderTrend']?['changePercentage'] ?? 0.0).toDouble(),
            },
            'revenueTrend': {
              'trends': data['revenueTrend']?['trends'] ?? [],
              'currentValue':
                  (data['revenueTrend']?['currentValue'] ?? 0.0).toDouble(),
              'changePercentage':
                  (data['revenueTrend']?['changePercentage'] ?? 0.0).toDouble(),
            },
          };

          print('📈 Extracted Three-Months Stats: $threeMonthsStats');

          return {
            'success': true,
            'threeMonthsStats': threeMonthsStats,
            'message': 'Three-months stats fetched successfully',
          };
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Failed to fetch three-months stats',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error fetching salon three-months stats: $e');
      return {
        'success': false,
        'message': 'Error fetching three-months stats: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// Submit a withdrawal request
  static Future<Map<String, dynamic>> submitWithdrawalRequest(
      double amount) async {
    try {
      print('💸 === SUBMITTING WITHDRAWAL REQUEST ===');
      print('💸 Amount: $amount');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/salon-withdrawals',
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'amount': amount,
        },
      );

      print('💸 Withdrawal API Response Status: ${response.statusCode}');
      print('💸 Withdrawal API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('💸 Parsed Response: $responseData');

        if (responseData['statusCode'] == 200 ||
            responseData['statusCode'] == 201) {
          print('💸 Withdrawal request submitted successfully');

          return {
            'success': true,
            'message': responseData['message'] ??
                'Withdrawal request submitted successfully',
            'data': responseData['data'],
          };
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ??
                'Failed to submit withdrawal request',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response Body: ${response.body}');

        // Try to parse error message from response body for 401 errors
        String errorMessage = 'HTTP Error: ${response.statusCode}';
        if (response.statusCode == 401) {
          try {
            final responseData =
                jsonDecode(response.body) as Map<String, dynamic>;
            if (responseData['message'] != null) {
              errorMessage = responseData['message'];
            }
          } catch (e) {
            print('❌ Could not parse error message: $e');
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error submitting withdrawal request: $e');
      return {
        'success': false,
        'message': 'Error submitting withdrawal request: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// Get withdrawal history for salon
  static Future<Map<String, dynamic>> getWithdrawalHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('💸 === FETCHING WITHDRAWAL HISTORY ===');
      print('💸 Page: $page, Limit: $limit');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/salon-withdrawals',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      print(
          '💸 Withdrawal History API Response Status: ${response.statusCode}');
      print('💸 Withdrawal History API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        print('💸 Parsed Response: $responseData');
        print('💸 Response Data Type: ${responseData.runtimeType}');
        print('💸 Response Keys: ${responseData.keys.toList()}');

        if (responseData['data'] != null) {
          print('💸 Data Type: ${responseData['data'].runtimeType}');
          if (responseData['data'] is Map) {
            print(
                '💸 Data Keys: ${(responseData['data'] as Map).keys.toList()}');
          }
        }

        if (responseData['statusCode'] == 200 ||
            responseData['statusCode'] == 201) {
          print('💸 Withdrawal history fetched successfully');

          return {
            'success': true,
            'message': responseData['message'] ??
                'Withdrawal history fetched successfully',
            'data': responseData['data'],
            'totalPages': responseData['totalPages'],
            'currentPage': responseData['currentPage'],
            'total': responseData['total'],
          };
        } else {
          print('❌ API returned error: ${responseData['message']}');
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Failed to fetch withdrawal history',
            'error': 'API_ERROR',
          };
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response Body: ${response.body}');

        // Try to parse error message from response body for 401 errors
        String errorMessage = 'HTTP Error: ${response.statusCode}';
        if (response.statusCode == 401) {
          try {
            final responseData =
                jsonDecode(response.body) as Map<String, dynamic>;
            if (responseData['message'] != null) {
              errorMessage = responseData['message'];
            }
          } catch (e) {
            print('❌ Could not parse error message: $e');
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'error': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      print('❌ Error fetching withdrawal history: $e');
      return {
        'success': false,
        'message': 'Error fetching withdrawal history: ${e.toString()}',
        'error': 'NETWORK_ERROR',
      };
    }
  }
}
