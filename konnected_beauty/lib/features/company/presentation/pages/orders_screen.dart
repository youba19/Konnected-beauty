import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/orders_service.dart';
import '../../../../core/services/api/salon_services_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'order_detail_screen.dart';
import 'qr_scanner_screen.dart';

abstract final class _OrdersUi {
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
  static const double horizontalPadding = 16;
}

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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final topInset = MediaQuery.paddingOf(context).top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ui.systemOverlay,
          child: ColoredBox(
            color: ui.bg,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: _buildQrFab(ui),
              body: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topInset + 180,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: ui.headerGradient,
                          stops: ui.headerStops,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: RefreshIndicator(
                        onRefresh: () => _loadOrders(refresh: true),
                        color: Colors.white,
                        backgroundColor: SalonUiTheme.blueUpper,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: topInset + 8),
                                  _buildHeader(ui),
                                  _buildSearchAndFilter(ui),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      _OrdersUi.horizontalPadding,
                                      20,
                                      _OrdersUi.horizontalPadding,
                                      8,
                                    ),
                                    child: Text(
                                      AppTranslations.getString(
                                          context, 'orders'),
                                      style: TextStyle(
                                        color: ui.isDark ? Colors.white : Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _isLoading
                                ? SliverToBoxAdapter(
                                    child: _buildLoadingContent(ui))
                                : _buildOrdersSliver(ui),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 96)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQrFab(SalonUiTheme ui) {
    return FloatingActionButton(
      onPressed: _openQrScanner,
      backgroundColor: ui.fabBg,
      elevation: 4,
      shape: CircleBorder(
        side: BorderSide(color: ui.fabBorder, width: 1),
      ),
      child: Icon(
        LucideIcons.scanLine,
        color: ui.isDark ? Colors.white : Colors.black,
        size: 24,
      ),
    );
  }

  Future<void> _openQrScanner() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QRScannerScreen()),
      );
      return;
    }

    final result = await Permission.camera.request();
    if (!mounted) return;
    if (result.isGranted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QRScannerScreen()),
      );
    } else {
      TopNotificationService.showError(
        context: context,
        message: 'Camera permission is required to scan QR codes',
      );
    }
  }

  Widget _buildHeader(SalonUiTheme ui) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _OrdersUi.horizontalPadding,
        0,
        _OrdersUi.horizontalPadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: _OrdersUi.buttonSize,
              height: _OrdersUi.buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ui.buttonFillTop, ui.buttonFillBottom],
                ),
                borderRadius: BorderRadius.circular(_OrdersUi.buttonRadius),
                border: ui.isDark
                    ? null
                    : Border.all(color: ui.cardBorder, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(
          LucideIcons.arrowLeft,
          color: ui.buttonIcon,
          size: 22,
        ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppTranslations.getString(context, 'orders'),
            style: TextStyle(
              color: ui.isDark ? Colors.white : Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                AppTranslations.getString(context, 'campaign_with'),
                style: TextStyle(
                  color: ui.isDark ? Colors.white70 : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              _buildInfluencerAvatar(ui),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '@${widget.campaign['influencer']?['profile']?['pseudo'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfluencerAvatar(SalonUiTheme ui) {
    final profilePicture =
        widget.campaign['influencer']?['profile']?['profilePicture'];

    return ClipOval(
      child: SizedBox(
        width: 22,
        height: 22,
        child: profilePicture != null && profilePicture.toString().isNotEmpty
            ? Image.network(
                profilePicture.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(ui);
                },
              )
            : _buildDefaultAvatar(ui),
      ),
    );
  }

  Widget _buildDefaultAvatar(SalonUiTheme ui) {
    return ColoredBox(
      color: ui.bannerFill,
      child: Center(
        child: Icon(Icons.person, color: ui.isDark ? Colors.white54 : Colors.black, size: 14),
      ),
    );
  }

  Widget _buildSearchAndFilter(SalonUiTheme ui) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _OrdersUi.horizontalPadding,
        16,
        _OrdersUi.horizontalPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_OrdersUi.radius),
                border: Border.all(color: ui.borderSubtle, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: ui.isDark ? Colors.white : Colors.black, fontSize: 15),
                cursorColor: ui.isDark ? Colors.white : Colors.black,
                onChanged: (value) {
                  _searchQuery = value;
                  _filterOrders();
                },
                decoration: InputDecoration(
                  hintText:
                      AppTranslations.getString(context, 'search_orders'),
                  hintStyle: TextStyle(
                    color: ui.isDark ? Colors.white54 : Colors.black,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: ui.isDark ? Colors.white70 : Colors.black,
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showFilterBottomSheet(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(_OrdersUi.radius),
                border: Border.all(color: ui.borderSubtle, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.slidersHorizontal,
                color: ui.isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(SalonUiTheme ui) {
    return Shimmer.fromColors(
      baseColor: ui.isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: ui.isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...List.generate(9, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 100,
                decoration: BoxDecoration(
                  color: ui.card,
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSliver(SalonUiTheme ui) {
    if (_hasError) {
      return SliverToBoxAdapter(child: _buildErrorState(ui));
    }

    if (_filteredOrders.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(ui));
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < _filteredOrders.length) {
              return _buildOrderCard(ui, _filteredOrders[index]);
            } else if (index == _filteredOrders.length) {
              if (_isLoadingMore) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ui.isDark
                          ? Colors.white
                          : SalonUiTheme.blueUpper,
                    ),
                  ),
                );
              } else if (_hasMoreData) {
                return _buildLoadMoreButton(ui);
              } else {
                return const SizedBox(height: 40);
              }
            }
            return null;
          },
          childCount: _filteredOrders.length +
              (_hasMoreData || _isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildOrdersList(SalonUiTheme ui) {
    if (_hasError) {
      return _buildErrorState(ui);
    }

    if (_filteredOrders.isEmpty) {
      return _buildEmptyState(ui);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._orders.map((order) => _buildOrderCard(ui, order)),
          if (_hasMoreData && !_isLoading) _buildLoadMoreButton(ui),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorState(SalonUiTheme ui) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: ui.isDark ? Colors.white70 : Colors.black,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: ui.isDark ? Colors.white70 : Colors.black,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadOrders(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ui.primaryButtonBg,
              foregroundColor: ui.primaryButtonFg,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SalonUiTheme ui) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: ui.isDark ? Colors.white70 : Colors.black,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.getString(context, 'no_orders_found'),
            style: TextStyle(
              color: ui.isDark ? Colors.white70 : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'orders_will_appear_here'),
            style: TextStyle(
              color: ui.isDark ? Colors.white70 : Colors.black,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(SalonUiTheme ui) {
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
              backgroundColor: Colors.transparent,
              foregroundColor: ui.isDark ? Colors.white : Colors.black,
              side: BorderSide(color: ui.outlinedButtonBorder),
            ),
            child: _isLoadingMore
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: ui.isDark
                          ? Colors.white
                          : SalonUiTheme.blueUpper,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '${AppTranslations.getString(context, 'load_more')} (${_filteredOrders.length}/$_total)'),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppTranslations.getString(context, 'page')} $_currentPage/$_totalPages | ${AppTranslations.getString(context, 'orders')} ${_filteredOrders.length}/$_total',
            style: TextStyle(
              color: ui.isDark ? Colors.white70 : Colors.black,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(SalonUiTheme ui, Map<String, dynamic> order) {
    try {
      final fullOrderId = order['id']?.toString() ?? 'N/A';
      final orderId =
          fullOrderId.length > 9 ? fullOrderId.substring(0, 9) : fullOrderId;
      final clientName =
          order['clientInfo']?['name']?.toString() ?? 'Unknown Client';
      final discountedAmount = order['discountedAmount']?.toString() ?? '0';

      String services = '0 services';
      try {
        final servicesData = order['services'];
        if (servicesData != null) {
          if (servicesData is List) {
            final count = servicesData.length;
            services = count == 1 ? '1 service' : '$count services';
          } else {
            services = '1 service';
          }
        }
      } catch (_) {
        services = '0 services';
      }

      final amount = int.tryParse(discountedAmount) ?? 0;

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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: ui.cardAlt,
            borderRadius: BorderRadius.circular(_OrdersUi.radius),
            border: Border.all(color: ui.cardBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderId,
                      style: TextStyle(
                        color: ui.isDark ? Colors.white54 : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      clientName,
                      style: TextStyle(
                        color: ui.isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'EUR $amount',
                      style: TextStyle(
                        color: ui.isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                services,
                style: TextStyle(
                  color: ui.isDark ? Colors.white70 : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ui.cardAlt,
          borderRadius: BorderRadius.circular(_OrdersUi.radius),
          border: Border.all(color: ui.cardBorder, width: 1),
        ),
        child: Text(
          'Error loading order: $e',
          style: const TextStyle(color: Colors.red, fontSize: 14),
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
            availableServices: _availableServices,
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
  final List<Map<String, dynamic>> availableServices;
  final Function(String?, String?, List<String>) onApplyFilter;

  const _FilterBottomSheet({
    required this.minAmountController,
    required this.maxAmountController,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedServiceIds,
    required this.availableServices,
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
    if (widget.availableServices.isNotEmpty) {
      _availableServices = List.from(widget.availableServices);
    } else {
      _loadServices();
    }
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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final bottomSafe = MediaQuery.paddingOf(context).bottom;
        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    16 + bottomSafe + keyboardInset,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.getString(context, 'filter'),
                        style: TextStyle(
                          color: ui.isDark ? Colors.white : Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppTranslations.getString(
                          context,
                          'orders_total_date_services',
                        ),
                        style: TextStyle(
                          color: ui.isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLabeledField(
                                      ui: ui,
                                      label: AppTranslations.getString(
                                          context, 'min'),
                                      child: _buildOutlineField(
                                        ui: ui,
                                        controller: _minAmountController,
                                        hint: AppTranslations.getString(
                                            context, 'min'),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildLabeledField(
                                      ui: ui,
                                      label: AppTranslations.getString(
                                          context, 'max'),
                                      child: _buildOutlineField(
                                        ui: ui,
                                        controller: _maxAmountController,
                                        hint: AppTranslations.getString(
                                            context, 'max'),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _buildLabeledField(
                                ui: ui,
                                label: AppTranslations.getString(
                                    context, 'date'),
                                child: GestureDetector(
                                  onTap: () => _selectDateRange(ui),
                                  child: _buildSelectableBox(
                                    ui: ui,
                                    text: _dateFrom != null && _dateTo != null
                                        ? '${_formatDate(_dateFrom!)} - ${_formatDate(_dateTo!)}'
                                        : AppTranslations.getString(
                                            context,
                                            'select_date_range',
                                          ),
                                    isPlaceholder: !(_dateFrom != null &&
                                        _dateTo != null),
                                    trailing: LucideIcons.calendar,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildLabeledField(
                                ui: ui,
                                label: AppTranslations.getString(
                                    context, 'services'),
                                child: _buildServicesDropdown(ui),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ui.isDark ? Colors.white : Colors.black,
                                  side: BorderSide(
                                    color: ui.outlinedButtonBorder,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        _OrdersUi.radius),
                                  ),
                                ),
                                child: Text(
                                  AppTranslations.getString(
                                      context, 'cancel'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onApplyFilter(
                                    _dateFrom,
                                    _dateTo,
                                    _selectedServiceIds,
                                  );
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ui.primaryButtonBg,
                                  foregroundColor: ui.primaryButtonFg,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        _OrdersUi.radius),
                                  ),
                                ),
                                child: Text(
                                  AppTranslations.getString(
                                      context, 'apply_filter'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabeledField({
    required SalonUiTheme ui,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ui.isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildOutlineField({
    required SalonUiTheme ui,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_OrdersUi.radius),
        border: Border.all(color: ui.borderSubtle, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: ui.isDark ? Colors.white : Colors.black, fontSize: 15),
        cursorColor: ui.isDark ? Colors.white : Colors.black,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: ui.isDark ? Colors.white54 : Colors.black,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableBox({
    required SalonUiTheme ui,
    required String text,
    required bool isPlaceholder,
    required IconData trailing,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_OrdersUi.radius),
        border: Border.all(color: ui.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isPlaceholder
                    ? (ui.isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.black)
                    : (ui.isDark ? Colors.white : Colors.black),
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            trailing,
            color: ui.isDark ? Colors.white : Colors.black,
            size: 18,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(SalonUiTheme ui) async {
    final now = DateTime.now();
    final initialStart = _dateFrom != null
        ? DateTime.tryParse(_dateFrom!) ?? now
        : now.subtract(const Duration(days: 30));
    final initialEnd =
        _dateTo != null ? DateTime.tryParse(_dateTo!) ?? now : now;

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        final pickerUi = SalonUiTheme.of(context);
        return Theme(
          data: pickerUi.isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: SalonUiTheme.accentBlue,
                    onPrimary: Colors.white,
                    surface: pickerUi.card,
                    onSurface: pickerUi.textPrimary,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: SalonUiTheme.accentBlue,
                    onPrimary: Colors.white,
                    surface: pickerUi.card,
                    onSurface: pickerUi.textPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _dateFrom = range.start.toIso8601String().split('T').first;
        _dateTo = range.end.toIso8601String().split('T').first;
      });
    }
  }

  Widget _buildServicesDropdown(SalonUiTheme ui) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_OrdersUi.radius),
        border: Border.all(color: ui.borderSubtle, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: () {
              if (_selectedServiceIds.isEmpty) return null;
              if (_selectedServiceIds.length == _availableServices.length &&
                  _availableServices.isNotEmpty) {
                return 'all';
              }
              if (_selectedServiceIds.length == 1) {
                final selectedId = _selectedServiceIds.first;
                final exists = _availableServices
                    .any((service) => service['id'] == selectedId);
                return exists ? selectedId : null;
              }
              return null;
            }(),
            hint: Text(
              AppTranslations.getString(context, 'select_multiple_services'),
              style: TextStyle(
                color: ui.isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.black,
                fontSize: 15,
              ),
            ),
            style: TextStyle(
              color: ui.isDark ? Colors.white : Colors.black,
              fontSize: 15,
            ),
            dropdownColor: ui.card,
            icon: Icon(
              LucideIcons.chevronDown,
              color: ui.isDark ? Colors.white : Colors.black,
              size: 18,
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem<String>(
                value: 'all',
                child: Text(
                  AppTranslations.getString(context, 'all_services'),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                ),
              ),
              ..._availableServices.map((service) {
                return DropdownMenuItem<String>(
                  value: service['id'] as String,
                  child: Text(
                    service['name']?.toString() ?? '',
                    style: TextStyle(
                      color: ui.isDark ? Colors.white : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                );
              }),
            ],
            onChanged: (String? value) {
              setState(() {
                if (value == 'all') {
                  _selectedServiceIds = _availableServices
                      .map((service) => service['id'] as String)
                      .toList();
                } else if (value != null) {
                  _selectedServiceIds = [value];
                } else {
                  _selectedServiceIds = [];
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
