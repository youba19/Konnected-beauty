import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api/orders_service.dart';
import '../../../../core/services/api/salon_services_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;

  const OrdersScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _orders = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  // Filter state
  String? _dateFrom;
  String? _dateTo;
  List<String> _selectedServiceIds = [];
  List<Map<String, dynamic>> _availableServices = [];

  // Frontend search state
  List<Map<String, dynamic>> _filteredOrders = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadOrders();
    _scrollController.addListener(_onScroll);
  }

  void _filterOrders() {
    if (_searchQuery.isEmpty) {
      _filteredOrders = List.from(_orders);
    } else {
      _filteredOrders = _orders.where((order) {
        // Search in order ID
        final orderId = order['id']?.toString().toLowerCase() ?? '';
        if (orderId.contains(_searchQuery.toLowerCase())) return true;

        // Search in customer name
        final customerName =
            order['customerName']?.toString().toLowerCase() ?? '';
        if (customerName.contains(_searchQuery.toLowerCase())) return true;

        // Search in customer email
        final customerEmail =
            order['customerEmail']?.toString().toLowerCase() ?? '';
        if (customerEmail.contains(_searchQuery.toLowerCase())) return true;

        // Search in services
        final services = order['services'] as List<dynamic>? ?? [];
        for (final service in services) {
          if (service is Map<String, dynamic>) {
            final serviceName = service['name']?.toString().toLowerCase() ?? '';
            if (serviceName.contains(_searchQuery.toLowerCase())) return true;
          }
        }

        // Search in status
        final status = order['status']?.toString().toLowerCase() ?? '';
        if (status.contains(_searchQuery.toLowerCase())) return true;

        // Search in amount
        final amount = order['amount']?.toString() ?? '';
        if (amount.contains(_searchQuery)) return true;

        return false;
      }).toList();
    }
    setState(() {});
  }

  String _getSelectedServiceName() {
    if (_selectedServiceIds.isNotEmpty && _selectedServiceIds.length == 1) {
      final selectedId = _selectedServiceIds.first;
      final service = _availableServices.firstWhere(
        (service) => service['id'] == selectedId,
        orElse: () => {'name': 'Unknown Service'},
      );
      return service['name'] as String;
    }
    return AppTranslations.getString(context, 'select_multiple_services');
  }

  Future<void> _loadServices() async {
    try {
      print('🔍 === LOADING SALON SERVICES ===');

      final result = await SalonServicesService.getServicesWithInterceptor();

      print('🔍 Services API Result: $result');

      if (result['success'] == true && result['data'] != null) {
        final servicesData = result['data'] as List<dynamic>;
        final services = servicesData.map<Map<String, dynamic>>((service) {
          return {
            'id': service['id']?.toString() ?? '',
            'name': service['name']?.toString() ?? 'Unknown Service',
          };
        }).toList();

        print('🔍 Loaded ${services.length} services');
        for (int i = 0; i < services.length; i++) {
          print('🔍 Service $i: ${services[i]['name']} (${services[i]['id']})');
        }

        setState(() {
          _availableServices = services;
        });
      } else {
        print('❌ Failed to load services: ${result['message']}');
        // Fallback to mock data if API fails
        setState(() {
          _availableServices = [
            {'id': '20bf3405-e259-4beb-8b9b-89a0d0003a0d', 'name': 'Hair Cut'},
            {
              'id': '30cf4506-f360-5fcc-9c9c-99b1e1114b1e',
              'name': 'Hair Color'
            },
            {
              'id': '40df5607-g471-6gdd-adad-00c2f2225c2f',
              'name': 'Facial Treatment'
            },
          ];
        });
      }
    } catch (e) {
      print('❌ Error loading services: $e');
      // Fallback to mock data on error
      setState(() {
        _availableServices = [
          {'id': '20bf3405-e259-4beb-8b9b-89a0d0003a0d', 'name': 'Hair Cut'},
          {'id': '30cf4506-f360-5fcc-9c9c-99b1e1114b1e', 'name': 'Hair Color'},
          {
            'id': '40df5607-g471-6gdd-adad-00c2f2225c2f',
            'name': 'Facial Treatment'
          },
        ];
      });
    }
  }

  void _onScroll() {
    print('🔍 === SCROLL EVENT ===');
    print('🔍 Scroll Position: ${_scrollController.position.pixels}');
    print('🔍 Max Scroll: ${_scrollController.position.maxScrollExtent}');
    print(
        '🔍 Scroll Percentage: ${(_scrollController.position.pixels / _scrollController.position.maxScrollExtent * 100).toStringAsFixed(1)}%');
    print('🔍 Orders: ${_orders.length}/$_total');
    print('🔍 Page: $_currentPage/$_totalPages');
    print('🔍 Loading more: $_isLoadingMore');
    print('🔍 Has more data: $_hasMoreData');

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more orders when near the bottom
      final hasMorePages = _currentPage < _totalPages;
      final hasMoreByTotal = _orders.length < _total;
      final shouldLoadMore = hasMorePages && hasMoreByTotal && !_isLoadingMore;

      print('📄 === SCROLL TRIGGER ===');
      print('📄 Current Page: $_currentPage');
      print('📄 Total Pages: $_totalPages (from API)');
      print('📄 Has More Pages: $hasMorePages ($_currentPage < $_totalPages)');
      print('📄 Current Orders: ${_orders.length}');
      print('📄 Total Items: $_total (from API)');
      print(
          '📄 Has More By Total: $hasMoreByTotal (${_orders.length} < $_total)');
      print('📄 Should Load More: $shouldLoadMore');

      if (shouldLoadMore) {
        print('📄 === LOADING MORE ORDERS ===');
        print('📄 Current Page: $_currentPage');
        print('📄 Total Pages: $_totalPages');
        print('📄 Current Orders: ${_orders.length}');
        print('📄 Total Available: $_total');

        print('📄 Loading page: ${_currentPage + 1}');
        _loadMoreOrders();
      }
    }
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    print('🔍 === LOAD ORDERS CALLED ===');
    print('🔍 Available services at start: ${_availableServices.length}');
    print('🔍 Selected service IDs: $_selectedServiceIds');
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _totalPages = 1;
        _total = 0;
        _orders.clear();
        _hasMoreData = true;
        _hasError = false;
        _errorMessage = '';
        _isLoadingMore = false;
      });
    }

    if (!_hasMoreData && !refresh) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final campaignId = widget.campaign['id']?.toString() ?? '';
      if (campaignId.isEmpty) {
        throw Exception('Campaign ID is required');
      }

      print('📅 Orders Screen Date Filter Debug:');
      print('📅 _dateFrom: $_dateFrom');
      print('📅 _dateTo: $_dateTo');

      final result = await OrdersService.getOrders(
        campaignId: campaignId,
        search: null, // Remove search from API - now using frontend search
        minAmount: _minAmountController.text.isNotEmpty
            ? double.tryParse(_minAmountController.text)
            : null,
        maxAmount: _maxAmountController.text.isNotEmpty
            ? double.tryParse(_maxAmountController.text)
            : null,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        serviceIds: _selectedServiceIds.isNotEmpty ? _selectedServiceIds : null,
        page: _currentPage,
        limit: 10,
      );

      if (mounted) {
        if (result['success'] == true) {
          try {
            // Debug: Print the complete API response
            print('🔍 === COMPLETE API RESPONSE ===');
            print('🔍 Full Response: $result');
            print('🔍 Response Type: ${result.runtimeType}');
            print('🔍 Response Keys: ${result.keys.toList()}');

            // Show each key-value pair
            result.forEach((key, value) {
              print('🔍 $key: $value (${value.runtimeType})');
            });

            print('🔍 === DATA ANALYSIS ===');
            print('🔍 Data Type: ${result['data'].runtimeType}');
            print('🔍 Data Content: ${result['data']}');

            if (result['data'] is List) {
              print('🔍 Data List Length: ${(result['data'] as List).length}');
              final dataList = result['data'] as List;
              for (int i = 0; i < dataList.length; i++) {
                print('🔍 Data[$i]: ${dataList[i]}');
              }
            }

            if (result['data'] is Map) {
              print(
                  '🔍 Data Map Keys: ${(result['data'] as Map).keys.toList()}');
              final dataMap = result['data'] as Map;
              dataMap.forEach((key, value) {
                print('🔍 Data[$key]: $value (${value.runtimeType})');
              });
            }

            print('🔍 === PAGINATION METADATA ===');
            print(
                '🔍 result[currentPage]: ${result['currentPage']} (${result['currentPage'].runtimeType})');
            print(
                '🔍 result[totalPages]: ${result['totalPages']} (${result['totalPages'].runtimeType})');
            print(
                '🔍 result[total]: ${result['total']} (${result['total'].runtimeType})');
            print('🔍 result[message]: ${result['message']}');
            print('🔍 result[statusCode]: ${result['statusCode']}');

            List<Map<String, dynamic>> newOrders = [];

            if (result['data'] != null) {
              if (result['data'] is List) {
                // Data is already a list - convert each item to Map
                final dataList = result['data'] as List;
                newOrders = dataList.map<Map<String, dynamic>>((item) {
                  if (item is Map<String, dynamic>) {
                    return item;
                  } else {
                    return Map<String, dynamic>.from(item);
                  }
                }).toList();
              } else if (result['data'] is Map) {
                // Data is a Map - check if it has a 'data' key with the orders array
                final dataMap = result['data'] as Map<String, dynamic>;
                if (dataMap['data'] is List) {
                  // The orders are in data.data
                  final ordersList = dataMap['data'] as List;
                  newOrders = ordersList.map<Map<String, dynamic>>((item) {
                    if (item is Map<String, dynamic>) {
                      return item;
                    } else {
                      return Map<String, dynamic>.from(item);
                    }
                  }).toList();
                } else {
                  // Data is a single object, wrap it in a list
                  newOrders = [Map<String, dynamic>.from(result['data'])];
                }
              }
            } else {
              // If data is null, this is unexpected
              print('❌ Unexpected: result data is null');
            }

            print('🔍 Processed Orders Count: ${newOrders.length}');
            for (int i = 0; i < newOrders.length; i++) {
              print(
                  '🔍 Order $i: ${newOrders[i]['id']} - ${newOrders[i]['clientInfo']?['name']}');
              print('🔍 Order $i full data: ${newOrders[i]}');
            }

            // Apply client-side service filtering since API doesn't support it
            if (_selectedServiceIds.isNotEmpty) {
              print('🔍 === APPLYING CLIENT-SIDE SERVICE FILTER ===');
              print('🔍 Filtering by service IDs: $_selectedServiceIds');
              print('🔍 Orders before filtering: ${newOrders.length}');

              // Get the service names for the selected service IDs
              print('🔍 === SERVICE FILTER DEBUG ===');
              print(
                  '🔍 Available services count: ${_availableServices.length}');
              print('🔍 Available services: $_availableServices');
              print('🔍 Selected service IDs: $_selectedServiceIds');

              // Debug each available service
              for (int i = 0; i < _availableServices.length; i++) {
                final service = _availableServices[i];
                print(
                    '🔍 Service $i: ID=${service['id']}, Name=${service['name']}');
                print(
                    '🔍 Is selected: ${_selectedServiceIds.contains(service['id'])}');
              }

              final selectedServiceNames = _availableServices
                  .where(
                      (service) => _selectedServiceIds.contains(service['id']))
                  .map((service) => service['name'] as String)
                  .toList();
              print('🔍 Filtering by service names: $selectedServiceNames');
              print(
                  '🔍 Selected service names count: ${selectedServiceNames.length}');

              final filteredOrders = newOrders.where((order) {
                try {
                  print('🔍 === FILTERING ORDER ${order['id']} ===');
                  final services = order['services'];
                  print('🔍 Order services: $services');

                  if (services is List) {
                    final serviceList = services as List<dynamic>;
                    print('🔍 Service list length: ${serviceList.length}');

                    for (int i = 0; i < serviceList.length; i++) {
                      final service = serviceList[i];
                      print('🔍 Service $i: $service');

                      if (service is Map<String, dynamic>) {
                        final serviceName = service['serviceName']?.toString();
                        final serviceId = service['id']?.toString();
                        print(
                            '🔍 Service name: $serviceName, Service ID: $serviceId');
                        print(
                            '🔍 Looking for service names: $selectedServiceNames');
                        print(
                            '🔍 Contains service name: ${selectedServiceNames.contains(serviceName)}');

                        if (serviceName != null &&
                            selectedServiceNames.contains(serviceName)) {
                          print(
                              '🔍 ✅ Order ${order['id']} matches service filter by name: $serviceName');
                          return true;
                        }
                      }
                    }
                  }
                  // Debug: Show the actual service IDs and names in this order
                  final orderServices = order['services'];
                  if (orderServices is List) {
                    final serviceIds = orderServices
                        .map((s) => s['id']?.toString())
                        .where((id) => id != null)
                        .toList();
                    final serviceNames = orderServices
                        .map((s) => s['serviceName']?.toString())
                        .where((name) => name != null)
                        .toList();
                    print(
                        '🔍 Order ${order['id']} has service IDs: $serviceIds');
                    print(
                        '🔍 Order ${order['id']} has service names: $serviceNames');
                  }
                  print(
                      '🔍 Order ${order['id']} does not match service filter');
                  return false;
                } catch (e) {
                  print('🔍 Error filtering order ${order['id']}: $e');
                  return false;
                }
              }).toList();

              print('🔍 Orders after filtering: ${filteredOrders.length}');
              newOrders = filteredOrders;
            }

            // Extract pagination metadata from API response (from data object)
            final dataMap = result['data'] as Map<String, dynamic>;
            final currentPage =
                int.tryParse(dataMap['currentPage']?.toString() ?? '1') ?? 1;
            final totalPages =
                int.tryParse(dataMap['totalPages']?.toString() ?? '1') ?? 1;
            final total =
                int.tryParse(dataMap['total']?.toString() ?? '0') ?? 0;

            print('🔍 === PAGINATION METADATA ===');
            print('🔍 API Response Keys: ${result.keys.toList()}');
            print('🔍 Current Page: $currentPage (from API)');
            print('🔍 Total Pages: $totalPages (from API)');
            print('🔍 Total Items: $total (from API)');
            print('🔍 New Orders Count: ${newOrders.length}');
            print(
                '🔍 Has More Pages: $currentPage < $totalPages = ${currentPage < totalPages}');
            print(
                '🔍 Has More By Count: ${newOrders.length} < $total = ${newOrders.length < total}');
            print(
                '🔍 Should Load More: ${currentPage < totalPages && newOrders.length < total}');

            setState(() {
              if (refresh) {
                _orders = newOrders;
                _currentPage = currentPage;
              } else {
                _orders.addAll(newOrders);
                _currentPage = currentPage;
              }
              _totalPages = totalPages;
              _total = total;
              _hasMoreData =
                  _currentPage < _totalPages && _orders.length < _total;
              _isLoading = false;
              _hasError = false;

              // Update filtered orders after loading
              _filterOrders();
            });
          } catch (e) {
            print('❌ Error processing orders data: $e');
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Error processing orders: $e';
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = result['message'] ?? 'Failed to load orders';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error loading orders: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    print('🔍 === LOAD MORE ORDERS ===');
    print('🔍 Current page: $_currentPage');
    print('🔍 Is loading more: $_isLoadingMore');
    print('🔍 Has more data: $_hasMoreData');

    if (_isLoadingMore || !_hasMoreData) {
      print('🔍 Skipping load more - already loading or no more data');
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final campaignId = widget.campaign['id']?.toString() ?? '';
      if (campaignId.isEmpty) {
        throw Exception('Campaign ID is required');
      }

      final nextPage = _currentPage + 1;
      print('🔍 === LOAD MORE ORDERS ===');
      print('🔍 Current Page: $_currentPage');
      print('🔍 Requesting Page: $nextPage');
      print('🔍 Total Pages Available: $_totalPages');
      print('🔍 Current Orders Count: ${_orders.length}');
      print('🔍 Total Orders Available: $_total');

      final result = await OrdersService.getOrders(
        campaignId: campaignId,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        minAmount: _minAmountController.text.isNotEmpty
            ? double.tryParse(_minAmountController.text)
            : null,
        maxAmount: _maxAmountController.text.isNotEmpty
            ? double.tryParse(_maxAmountController.text)
            : null,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        serviceIds: _selectedServiceIds.isNotEmpty ? _selectedServiceIds : null,
        page: nextPage,
        limit: 10,
      );

      print('🔍 === LOAD MORE API RESPONSE ===');
      print('🔍 Full Response: $result');
      print('🔍 Response Type: ${result.runtimeType}');
      print('🔍 Response Keys: ${result.keys.toList()}');

      // Show each key-value pair
      result.forEach((key, value) {
        print('🔍 Load More $key: $value (${value.runtimeType})');
      });

      print('🔍 === LOAD MORE DATA ANALYSIS ===');
      print('🔍 Data Type: ${result['data'].runtimeType}');
      print('🔍 Data Content: ${result['data']}');

      if (result['data'] is List) {
        print(
            '🔍 Load More Data List Length: ${(result['data'] as List).length}');
        final dataList = result['data'] as List;
        for (int i = 0; i < dataList.length; i++) {
          print('🔍 Load More Data[$i]: ${dataList[i]}');
        }
      }

      if (result['data'] is Map) {
        print(
            '🔍 Load More Data Map Keys: ${(result['data'] as Map).keys.toList()}');
        final dataMap = result['data'] as Map;
        dataMap.forEach((key, value) {
          print('🔍 Load More Data[$key]: $value (${value.runtimeType})');
        });
      }

      print('🔍 === LOAD MORE PAGINATION METADATA ===');
      print(
          '🔍 Load More result[currentPage]: ${result['currentPage']} (${result['currentPage'].runtimeType})');
      print(
          '🔍 Load More result[totalPages]: ${result['totalPages']} (${result['totalPages'].runtimeType})');
      print(
          '🔍 Load More result[total]: ${result['total']} (${result['total'].runtimeType})');
      print('🔍 Load More result[message]: ${result['message']}');
      print('🔍 Load More result[statusCode]: ${result['statusCode']}');

      if (mounted && result['success'] == true) {
        try {
          List<Map<String, dynamic>> newOrders = [];

          if (result['data'] != null) {
            if (result['data'] is List) {
              final dataList = result['data'] as List;
              newOrders = dataList.map<Map<String, dynamic>>((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else {
                  return Map<String, dynamic>.from(item);
                }
              }).toList();
            } else if (result['data'] is Map) {
              final dataMap = result['data'] as Map<String, dynamic>;
              if (dataMap['data'] is List) {
                final ordersList = dataMap['data'] as List;
                newOrders = ordersList.map<Map<String, dynamic>>((item) {
                  if (item is Map<String, dynamic>) {
                    return item;
                  } else {
                    return Map<String, dynamic>.from(item);
                  }
                }).toList();
              }
            }
          }

          // Extract pagination metadata from API response (from data object)
          final dataMap = result['data'] as Map<String, dynamic>;
          final resultCurrentPage =
              int.tryParse(dataMap['currentPage']?.toString() ?? '1') ?? 1;
          final totalPages =
              int.tryParse(dataMap['totalPages']?.toString() ?? '1') ?? 1;
          final total = int.tryParse(dataMap['total']?.toString() ?? '0') ?? 0;

          print('🔍 === LOAD MORE PAGINATION ===');
          print('🔍 New orders count: ${newOrders.length}');
          print('🔍 Total orders before: ${_orders.length}');
          print('🔍 Current Page: $resultCurrentPage (from API)');
          print('🔍 Total Pages: $totalPages (from API)');
          print('🔍 Total Items: $total (from API)');
          print(
              '🔍 Has More Pages: $resultCurrentPage < $totalPages = ${resultCurrentPage < totalPages}');
          print(
              '🔍 Has More By Total: ${_orders.length + newOrders.length} < $total = ${(_orders.length + newOrders.length) < total}');

          // Check both conditions: more pages available AND haven't reached total count
          final hasMorePages = resultCurrentPage < totalPages;
          final hasMoreByTotal = (_orders.length + newOrders.length) < total;
          final hasMoreData = hasMorePages && hasMoreByTotal;

          setState(() {
            _orders.addAll(newOrders);
            _currentPage = resultCurrentPage;
            _totalPages = totalPages;
            _total = total;
            _hasMoreData = hasMoreData;
            _isLoadingMore = false;

            // Update filtered orders after loading more
            _filterOrders();
          });

          print('🔍 Total orders after: ${_orders.length}');
          print('🔍 Current page: $_currentPage');
          print('🔍 Has more pages: $hasMorePages');
          print('🔍 Has more by total: $hasMoreByTotal');
          print('🔍 Final has more data: $_hasMoreData');
        } catch (e) {
          print('❌ Error processing more orders data: $e');
          setState(() {
            _isLoadingMore = false;
          });
        }
      } else {
        print('🔍 API call failed or no more data');
        setState(() {
          _isLoadingMore = false;
          _hasMoreData = false;
        });
      }
    } catch (e) {
      print('❌ Error loading more orders: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF1F1E1E), // Bottom color (darker)
                  Color(0xFF3B3B3B), // Top color (lighter)
                ],
              ),
            ),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  // Close keyboard when tapping outside text fields
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadOrders(refresh: true),
                        color: AppTheme.primaryColor,
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  // Header
                                  _buildHeader(),

                                  // Search and Filter
                                  _buildSearchAndFilter(),
                                ],
                              ),
                            ),
                            // Orders List
                            _isLoading
                                ? SliverToBoxAdapter(
                                    child: _buildLoadingContent())
                                : _buildOrdersSliver(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Orders title
          Text(
            AppTranslations.getString(context, 'orders'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          // Campaign with section
          Row(
            children: [
              Text(
                AppTranslations.getString(context, 'campaign_with'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              _buildInfluencerAvatar(),
              const SizedBox(width: 8),
              Text(
                '@${widget.campaign['influencer']?['profile']?['pseudo'] ?? 'Unknown'}',
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfluencerAvatar() {
    final profilePicture =
        widget.campaign['influencer']?['profile']?['profilePicture'];

    if (profilePicture != null && profilePicture.toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profilePicture.toString(),
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.transparentBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimaryColor),
                onChanged: (value) {
                  // Frontend search - filter locally
                  _searchQuery = value;
                  _filterOrders();
                },
                decoration: InputDecoration(
                  hintText: AppTranslations.getString(context, 'search'),
                  hintStyle:
                      const TextStyle(color: AppTheme.textSecondaryColor),
                  suffixIcon: const Icon(
                    LucideIcons.search,
                    color: AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Filter button
          GestureDetector(
            onTap: () => _showFilterBottomSheet(context),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.transparentBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.filter_list,
                color: AppTheme.textPrimaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...List.generate(9, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
            const SizedBox(height: 40), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSliver() {
    if (_hasError) {
      return SliverToBoxAdapter(child: _buildErrorState());
    }

    if (_filteredOrders.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < _filteredOrders.length) {
              return _buildOrderCard(_filteredOrders[index]);
            } else if (index == _filteredOrders.length) {
              // Load more indicator
              if (_isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              } else if (_hasMoreData) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox(height: 40);
              }
            }
            return null;
          },
          childCount:
              _filteredOrders.length + (_hasMoreData || _isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._orders.map((order) => _buildOrderCard(order)),
          if (_hasMoreData && !_isLoading) _buildLoadMoreButton(),
          const SizedBox(height: 40), // Extra padding at bottom
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.textSecondaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadOrders(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: AppTheme.textSecondaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.getString(context, 'no_orders_found'),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'orders_will_appear_here'),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    final hasMorePages = _currentPage < _totalPages;
    final hasMoreByTotal = _orders.length < _total;
    final canLoadMore = hasMorePages && hasMoreByTotal;

    print('🔍 === BUILD LOAD MORE BUTTON ===');
    print('🔍 Has More Pages: $hasMorePages ($_currentPage < $_totalPages)');
    print(
        '🔍 Has More By Total: $hasMoreByTotal (${_orders.length} < $_total)');
    print('🔍 Can Load More: $canLoadMore');
    print('🔍 Is Loading More: $_isLoadingMore');

    // Always show button for testing, even if no more data
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _isLoadingMore
                ? null
                : () {
                    print('🔍 === MANUAL LOAD MORE BUTTON PRESSED ===');
                    print('🔍 Current: ${_orders.length}/$_total');
                    print('🔍 Page: $_currentPage/$_totalPages');
                    print('🔍 Has More Pages: $hasMorePages');
                    print('🔍 Has More By Total: $hasMoreByTotal');
                    print('🔍 Can Load More: $canLoadMore');
                    _loadMoreOrders();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.transparentBackground,
              foregroundColor: AppTheme.textPrimaryColor,
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: _isLoadingMore
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '${AppTranslations.getString(context, 'load_more')} (${_filteredOrders.length}/$_total)'),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppTranslations.getString(context, 'page')} $_currentPage/$_totalPages | ${AppTranslations.getString(context, 'orders')} ${_filteredOrders.length}/$_total',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    try {
      // Debug: Print order data
      print('🔍 Building order card for: ${order['id']}');
      print('🔍 Order data: $order');

      // Extract data from real API response format
      print('🔍 Raw order keys: ${order.keys.toList()}');
      print(
          '🔍 Order ID raw: ${order['id']} (type: ${order['id'].runtimeType})');
      print(
          '🔍 ClientInfo raw: ${order['clientInfo']} (type: ${order['clientInfo'].runtimeType})');
      print(
          '🔍 Status raw: ${order['status']} (type: ${order['status'].runtimeType})');
      print(
          '🔍 DiscountedAmount raw: ${order['discountedAmount']} (type: ${order['discountedAmount'].runtimeType})');

      final fullOrderId = order['id']?.toString() ?? 'N/A';
      final orderId =
          fullOrderId.length > 8 ? fullOrderId.substring(0, 8) : fullOrderId;
      final clientName =
          order['clientInfo']?['name']?.toString() ?? 'Unknown Client';
      final status = order['status']?.toString() ?? 'Unknown';
      final discountedAmount = order['discountedAmount']?.toString() ?? '0';

      print(
          '🔍 Extracted - ID: $orderId, Client: $clientName, Status: $status, Amount: $discountedAmount');
      print('🔍 Client Info: ${order['clientInfo']}');
      print('🔍 Status Raw: ${order['status']}');
      print('🔍 Amount Raw: ${order['discountedAmount']}');

      // Format services count from array or object
      String services = '0 services';
      try {
        final servicesData = order['services'];
        if (servicesData != null) {
          if (servicesData is List) {
            // Handle array format
            final servicesList = servicesData as List<dynamic>;
            final count = servicesList.length;
            services = count == 1 ? '1 service' : '$count services';
          } else if (servicesData is Map) {
            // Handle single service object
            services = '1 service';
          } else {
            // Handle other types (string, etc.)
            services = '1 service';
          }
        }
      } catch (e) {
        print('❌ Error parsing services: $e');
        services = '0 services';
      }

      // Format date
      final createdAt = order['createdAt']?.toString() ?? '';
      final date = createdAt.isNotEmpty
          ? DateTime.tryParse(createdAt)?.toString().split(' ')[0] ?? 'Unknown'
          : 'Unknown';

      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.transparentBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Order ID
              Text(
                orderId,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Second row: Client name and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'EUR ${(int.parse(discountedAmount)).toStringAsFixed(0)} ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Third row: Status and Services
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    status,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    services,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Bottom row: Date
              Text(
                date,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Error building order card: $e');
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.transparentBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          'Error loading order: $e',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
      );
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _FilterBottomSheet(
            minAmountController: _minAmountController,
            maxAmountController: _maxAmountController,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            selectedServiceIds: _selectedServiceIds,
            onApplyFilter: (dateFrom, dateTo, serviceIds) {
              setState(() {
                _dateFrom = dateFrom;
                _dateTo = dateTo;
                _selectedServiceIds = serviceIds;
              });
              _loadOrders(refresh: true);
            },
          ),
        );
      },
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final TextEditingController minAmountController;
  final TextEditingController maxAmountController;
  final String? dateFrom;
  final String? dateTo;
  final List<String> selectedServiceIds;
  final Function(String?, String?, List<String>) onApplyFilter;

  const _FilterBottomSheet({
    required this.minAmountController,
    required this.maxAmountController,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedServiceIds,
    required this.onApplyFilter,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  String? _dateFrom;
  String? _dateTo;
  List<String> _selectedServiceIds = [];
  List<Map<String, dynamic>> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _minAmountController = widget.minAmountController;
    _maxAmountController = widget.maxAmountController;
    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
    _selectedServiceIds = List.from(widget.selectedServiceIds);
    _loadServices();
  }

  String _getSelectedServiceName() {
    if (_selectedServiceIds.isNotEmpty && _selectedServiceIds.length == 1) {
      final selectedId = _selectedServiceIds.first;
      final service = _availableServices.firstWhere(
        (service) => service['id'] == selectedId,
        orElse: () => {'name': 'Unknown Service'},
      );
      return service['name'] as String;
    }
    return AppTranslations.getString(context, 'select_multiple_services');
  }

  Future<void> _loadServices() async {
    try {
      print('🔍 === LOADING SALON SERVICES ===');

      final result = await SalonServicesService.getServicesWithInterceptor();

      print('🔍 Services API Result: $result');

      if (result['success'] == true && result['data'] != null) {
        final servicesData = result['data'] as List<dynamic>;
        final services = servicesData.map<Map<String, dynamic>>((service) {
          return {
            'id': service['id']?.toString() ?? '',
            'name': service['name']?.toString() ?? 'Unknown Service',
          };
        }).toList();

        print('🔍 Loaded ${services.length} services');
        for (int i = 0; i < services.length; i++) {
          print('🔍 Service $i: ${services[i]['name']} (${services[i]['id']})');
        }

        setState(() {
          _availableServices = services;
        });
      } else {
        print('❌ Failed to load services: ${result['message']}');
        // Fallback to mock data if API fails
        setState(() {
          _availableServices = [
            {'id': '20bf3405-e259-4beb-8b9b-89a0d0003a0d', 'name': 'Hair Cut'},
            {
              'id': '30cf4506-f360-5fcc-9c9c-99b1e1114b1e',
              'name': 'Hair Color'
            },
            {
              'id': '40df5607-g471-6gdd-adad-00c2f2225c2f',
              'name': 'Facial Treatment'
            },
          ];
        });
      }
    } catch (e) {
      print('❌ Error loading services: $e');
      // Fallback to mock data on error
      setState(() {
        _availableServices = [
          {'id': '20bf3405-e259-4beb-8b9b-89a0d0003a0d', 'name': 'Hair Cut'},
          {'id': '30cf4506-f360-5fcc-9c9c-99b1e1114b1e', 'name': 'Hair Color'},
          {
            'id': '40df5607-g471-6gdd-adad-00c2f2225c2f',
            'name': 'Facial Treatment'
          },
        ];
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateFrom != null ? DateTime.parse(_dateFrom!) : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateFrom =
            picked.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD
        print('📅 Start Date Selected: $_dateFrom');
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateTo != null ? DateTime.parse(_dateTo!) : DateTime.now(),
      firstDate:
          _dateFrom != null ? DateTime.parse(_dateFrom!) : DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateTo =
            picked.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD
        print('📅 End Date Selected: $_dateTo');
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: GestureDetector(
            onTap: () {
              // Close keyboard when tapping outside text fields
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          AppTranslations.getString(context, 'filter'),
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          AppTranslations.getString(
                              context, 'orders_total_date_services'),
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Orders Total Section
                        Text(
                          AppTranslations.getString(context, 'orders_total'),
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Min and Max inputs
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.getString(context, 'min'),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.transparentBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _minAmountController,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimaryColor),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: AppTranslations.getString(
                                            context, 'min'),
                                        hintStyle: const TextStyle(
                                            color: AppTheme.textSecondaryColor),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.getString(context, 'max'),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.transparentBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _maxAmountController,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimaryColor),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: AppTranslations.getString(
                                            context, 'max'),
                                        hintStyle: const TextStyle(
                                            color: AppTheme.textSecondaryColor),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Date Section
                        Text(
                          AppTranslations.getString(context, 'date'),
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Start Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getString(context, 'start_date'),
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectStartDate(),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.transparentBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dateFrom != null
                                              ? _formatDate(_dateFrom!)
                                              : AppTranslations.getString(
                                                  context, 'select_start_date'),
                                          style: TextStyle(
                                            color: _dateFrom != null
                                                ? AppTheme.textPrimaryColor
                                                : AppTheme.textSecondaryColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        color: AppTheme.textPrimaryColor,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // End Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getString(context, 'end_date'),
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectEndDate(),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.transparentBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dateTo != null
                                              ? _formatDate(_dateTo!)
                                              : AppTranslations.getString(
                                                  context, 'select_end_date'),
                                          style: TextStyle(
                                            color: _dateTo != null
                                                ? AppTheme.textPrimaryColor
                                                : AppTheme.textSecondaryColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        color: AppTheme.textPrimaryColor,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Services Section
                        Text(
                          AppTranslations.getString(context, 'services'),
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Services dropdown
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.transparentBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButton<String>(
                                value: () {
                                  if (_selectedServiceIds.isEmpty) return null;

                                  if (_selectedServiceIds.length ==
                                      _availableServices.length) {
                                    return 'all';
                                  }

                                  if (_selectedServiceIds.length == 1) {
                                    final selectedId =
                                        _selectedServiceIds.first;
                                    // Check if this ID exists in available services
                                    final serviceExists =
                                        _availableServices.any((service) =>
                                            service['id'] == selectedId);
                                    return serviceExists ? selectedId : null;
                                  }

                                  return null;
                                }(),
                                hint: Text(
                                  _selectedServiceIds.isNotEmpty &&
                                          _selectedServiceIds.length == 1
                                      ? _getSelectedServiceName()
                                      : AppTranslations.getString(
                                          context, 'select_multiple_services'),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 16,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 16,
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppTheme.textPrimaryColor,
                                ),
                                isExpanded: true,
                                items: () {
                                  print('🔍 === BUILDING DROPDOWN ITEMS ===');
                                  print(
                                      '🔍 Available services count: ${_availableServices.length}');

                                  final items = <DropdownMenuItem<String>>[
                                    // Add "All Services" option
                                    DropdownMenuItem<String>(
                                      value: 'all',
                                      child: Text(
                                        'All Services',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ];

                                  // Add individual services (ensure unique IDs)
                                  final addedIds = <String>{};
                                  for (int i = 0;
                                      i < _availableServices.length;
                                      i++) {
                                    final service = _availableServices[i];
                                    final serviceId = service['id'] as String;

                                    if (!addedIds.contains(serviceId)) {
                                      print(
                                          '🔍 Adding service $i: $serviceId - ${service['name']}');
                                      items.add(DropdownMenuItem<String>(
                                        value: serviceId,
                                        child: Text(
                                          service['name'],
                                          style: const TextStyle(
                                            color: AppTheme.textPrimaryColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ));
                                      addedIds.add(serviceId);
                                    } else {
                                      print(
                                          '🔍 Skipping duplicate service: $serviceId - ${service['name']}');
                                    }
                                  }

                                  print(
                                      '🔍 Total dropdown items: ${items.length}');
                                  print(
                                      '🔍 Dropdown values: ${items.map((item) => item.value).toList()}');

                                  return items;
                                }(),
                                onChanged: (String? value) {
                                  print('🔍 === DROPDOWN CHANGED ===');
                                  print('🔍 Selected value: $value');
                                  print(
                                      '🔍 Available services: $_availableServices');

                                  setState(() {
                                    if (value == 'all') {
                                      // Select all services
                                      _selectedServiceIds = _availableServices
                                          .map((service) =>
                                              service['id'] as String)
                                          .toList();
                                      print(
                                          '🔍 Selected all services: $_selectedServiceIds');
                                    } else if (value != null) {
                                      // Select specific service
                                      _selectedServiceIds = [value];
                                      print(
                                          '🔍 Selected specific service: $_selectedServiceIds');
                                    } else {
                                      // Clear selection
                                      _selectedServiceIds = [];
                                      print('🔍 Cleared selection');
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action Buttons - Fixed at bottom
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.textPrimaryColor,
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              AppTranslations.getString(context, 'cancel'),
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () {
                              // Apply filter logic
                              widget.onApplyFilter(
                                  _dateFrom, _dateTo, _selectedServiceIds);
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              AppTranslations.getString(
                                  context, 'apply_filter'),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
