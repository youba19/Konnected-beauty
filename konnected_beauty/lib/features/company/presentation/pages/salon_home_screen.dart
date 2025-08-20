import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/salon_services_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';

import '../../../auth/presentation/pages/welcome_screen.dart';
import 'create_service_screen.dart';
import 'service_details_screen.dart';
import 'edit_service_screen.dart';
import 'service_filter_screen.dart';
import 'influencers_screen.dart';

class SalonHomeScreen extends StatefulWidget {
  final bool showDeleteSuccess;

  const SalonHomeScreen({super.key, this.showDeleteSuccess = false});

  @override
  State<SalonHomeScreen> createState() => _SalonHomeScreenState();
}

class _SalonHomeScreenState extends State<SalonHomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _listController = ScrollController();
  int selectedIndex = 0; // Services tab is selected by default
  bool _showDeleteSuccess = false;
  int? _currentMinPrice;
  int? _currentMaxPrice;
  bool _isLoadingMore = false; // Flag to prevent duplicate load more requests
  Timer? _refreshTimer; // Timer for checking data after refresh

  @override
  void initState() {
    super.initState();
    _showDeleteSuccess = widget.showDeleteSuccess;

    // Auto-hide the success message after 3 seconds
    if (_showDeleteSuccess) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showDeleteSuccess = false;
          });
        }
      });
    }

    // Print stored tokens to console
    TokenStorageService.printStoredTokens();

    // Load salon services on app start
    print('🔄 === LOADING SERVICES ON APP START ===');
    context.read<SalonServicesBloc>().add(LoadSalonServices());

    // Add search listener
    searchController.addListener(_onSearchChanged);

    // Add scroll listener for better detection after refresh
    _listController.addListener(_onScrollChanged);

    // Post-frame check for initial load - if list isn't scrollable but has more data, load next page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadMoreData();
    });

    // Start a timer to periodically check for more data after refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkAndLoadMoreData();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Always refresh services when returning to this screen to ensure fresh data
    print('🔄 === REFRESHING SERVICES ON SCREEN RETURN ===');
    context.read<SalonServicesBloc>().add(LoadSalonServices());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _listController.removeListener(_onScrollChanged);
    _listController.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _checkAndLoadMoreData() {
    final bloc = context.read<SalonServicesBloc>();
    final currentState = bloc.state;
    if (currentState is SalonServicesLoaded) {
      if (currentState.hasMoreData && !_isLoadingMore) {
        if (_listController.hasClients) {
          final position = _listController.position;
          final maxExtent = position.maxScrollExtent;
          final notScrollable = maxExtent <= 0;
          print(
              '📜 CHECK AND LOAD → maxExtent=$maxExtent, notScrollable=$notScrollable');

          if (notScrollable) {
            print('📄 AUTO-LOAD NEXT PAGE: ${currentState.currentPage + 1}');
            _isLoadingMore = true;
            bloc.add(LoadMoreSalonServices(
              page: currentState.currentPage + 1,
              searchQuery: currentState.currentSearch,
              minPrice: currentState.currentMinPrice,
              maxPrice: currentState.currentMaxPrice,
            ));
          }
        }
      }
    }
  }

  void _onScrollChanged() {
    // Check if we can load more data on any scroll movement
    if (_listController.hasClients) {
      final position = _listController.position;
      final currentState = context.read<SalonServicesBloc>().state;

      if (currentState is SalonServicesLoaded &&
          currentState.hasMoreData &&
          !_isLoadingMore) {
        // If we're near bottom or list is not scrollable, load more
        final isNearBottom = position.pixels >= position.maxScrollExtent - 100;
        final isNotScrollable = position.maxScrollExtent <= 0;

        if (isNearBottom || isNotScrollable) {
          print('📜 SCROLL LISTENER → Loading more data');
          _isLoadingMore = true;
          context.read<SalonServicesBloc>().add(LoadMoreSalonServices(
                page: currentState.currentPage + 1,
                searchQuery: currentState.currentSearch,
                minPrice: currentState.currentMinPrice,
                maxPrice: currentState.currentMaxPrice,
              ));
        }
      }
    }
  }

  void _resetScrollAndLoadingState() {
    // Reset loading flag
    _isLoadingMore = false;

    // Reset scroll position to top
    if (_listController.hasClients) {
      _listController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      print('📜 Reset scroll position and loading state');
    }
  }

  void _onSearchChanged() {
    final searchQuery = searchController.text.trim();
    print('🔍 === SEARCH CHANGED ===');
    print('📝 Search Query: "$searchQuery"');
    print('📝 Search Query Length: ${searchQuery.length}');

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && searchController.text.trim() == searchQuery) {
        print('🔍 === EXECUTING SEARCH ===');
        print('📝 Final Search Query: "$searchQuery"');

        if (searchQuery.isEmpty) {
          print('🔄 Loading all services (empty search)');
          // If search is empty, load all services but preserve price filters
          final currentState = context.read<SalonServicesBloc>().state;
          if (currentState is SalonServicesLoaded) {
            // Preserve price filters when clearing search
            context.read<SalonServicesBloc>().add(FilterSalonServices(
                  minPrice: currentState.currentMinPrice,
                  maxPrice: currentState.currentMaxPrice,
                ));
          } else {
            // No current state, load without filters
            context.read<SalonServicesBloc>().add(LoadSalonServices());
          }
        } else {
          print('🔍 Performing search with query: "$searchQuery"');
          // Perform search
          context.read<SalonServicesBloc>().add(SearchSalonServices(
                searchQuery: searchQuery,
              ));
        }
      } else {
        print('❌ Search cancelled - query changed or widget unmounted');
      }
    });
  }

  void _showFilterScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => BlocProvider.value(
        value: context.read<SalonServicesBloc>(),
        child: ServiceFilterScreen(
          currentMinPrice: _currentMinPrice,
          currentMaxPrice: _currentMaxPrice,
          onFilterApplied: (minPrice, maxPrice) {
            setState(() {
              _currentMinPrice = minPrice;
              _currentMaxPrice = maxPrice;
            });
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentMinPrice = null;
      _currentMaxPrice = null;
    });
    // Clear search
    searchController.clear();
    // Reload services without any filters
    context.read<SalonServicesBloc>().add(LoadSalonServices());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Content based on selected tab
              Expanded(
                child: selectedIndex == 3
                    ? const InfluencersScreen()
                    : _buildServicesContent(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildServicesContent() {
    return BlocListener<SalonServicesBloc, SalonServicesState>(
        listener: (context, state) {
      if (state is SalonServicesLoaded) {
        // Reset loading flag when load more completes
        _isLoadingMore = false;
        print('📄 === LOAD/LOAD MORE COMPLETED ===');
        print('📄 Total Services: ${state.services.length}');
        print('📄 Current Page: ${state.currentPage}');
        print('📄 Has More Data: ${state.hasMoreData}');

        // Reset scroll position to top after refresh
        if (state.currentPage == 1 && _listController.hasClients) {
          _listController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          print('📜 Reset scroll position to top after refresh');

          // Force a check for more data after refresh completes
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _checkAndLoadMoreData();
            }
          });
        }

        // Smart auto-prefetch: only if list isn't scrollable and has more data
        if (state.hasMoreData && !_isLoadingMore) {
          if (_listController.hasClients) {
            final position = _listController.position;
            final maxExtent = position.maxScrollExtent;
            final pixels = position.pixels;
            final notScrollable = maxExtent <= 0;
            print(
                '📜 SMART CHECK → maxExtent=$maxExtent, pixels=$pixels, notScrollable=$notScrollable');

            // Only auto-load if the list isn't scrollable (meaning all items fit on screen)
            if (notScrollable) {
              print(
                  '📄 AUTO-LOAD NEXT PAGE (not scrollable): ${state.currentPage + 1}');
              _isLoadingMore = true;
              context.read<SalonServicesBloc>().add(LoadMoreSalonServices(
                    page: state.currentPage + 1,
                    searchQuery: state.currentSearch,
                    minPrice: state.currentMinPrice,
                    maxPrice: state.currentMaxPrice,
                  ));
            }
          }
        }
      } else if (state is SalonServicesError) {
        // Reset loading flag on error
        _isLoadingMore = false;

        // Auto-retry for token refresh errors
        if (state.error == 'TokenRefreshFailed' ||
            state.error == 'NoRefreshToken') {
          print('🔄 Auto-retrying after token refresh error...');
          // Wait a moment then retry
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.read<SalonServicesBloc>().add(LoadSalonServices());
            }
          });
        }
      } else if (state is SalonServiceCreated) {
        // Service was created successfully, refresh the list
        print('✅ Service created successfully, refreshing list...');
        context.read<SalonServicesBloc>().add(LoadSalonServices());

        // No need to show success message here - create service screen already shows it
      } else if (state is SalonServiceUpdated) {
        // Service was updated successfully, refresh the list
        print('✅ Service updated successfully, refreshing list...');
        context.read<SalonServicesBloc>().add(LoadSalonServices());

        // No need to show success message here - edit service screen already shows it
      } else if (state is SalonServiceDeleted) {
        // Service was deleted successfully, refresh the list
        print('✅ Service deleted successfully, refreshing list...');
        context.read<SalonServicesBloc>().add(LoadSalonServices());

        // Show success message using the new notification service
        TopNotificationService.showSuccess(
          context: context,
          message: state.message,
        );
      }
    }, child: BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        return Column(
          children: [
            // Success Banner (if needed)
            if (_showDeleteSuccess) _buildDeleteSuccessBanner(),

            // Header Section
            _buildHeader(),

            // Main Content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        );
      },
    ));
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Logout Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppTranslations.getString(context, 'services'),
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Logout Button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: _showLogoutDialog,
                ),
              ),
              const SizedBox(width: 8),
              // Test Create Service Button (for debugging)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: Colors.blue,
                    size: 20,
                  ),
                  onPressed: _createTestService,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar and Filter
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.transparentBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textPrimaryColor,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: AppTranslations.getString(context, 'search'),
                      hintStyle: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textPrimaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (_currentMinPrice != null || _currentMaxPrice != null)
                      ? AppTheme.textPrimaryColor
                      : AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textPrimaryColor,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color:
                        (_currentMinPrice != null || _currentMaxPrice != null)
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                  ),
                  onPressed: () {
                    _showFilterScreen();
                  },
                ),
              ),
              if (_currentMinPrice != null || _currentMaxPrice != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.red,
                    ),
                    onPressed: _clearFilters,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSuccessBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppTranslations.getString(context, 'service_deleted'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Fixed Create Service Button - outside RefreshIndicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildCreateServiceButton(),
        ),
        const SizedBox(height: 16),
        // Debug info - fixed outside refreshable area

        const SizedBox(height: 8),
        // Refreshable List Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Reset scroll position and loading state before refresh
              _resetScrollAndLoadingState();
              context.read<SalonServicesBloc>().add(RefreshSalonServices());
            },
            color: AppTheme.textPrimaryColor,
            backgroundColor: AppTheme.transparentBackground,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Debug scroll information
                print('📜 === SCROLL INFO ===');
                print('📜 Pixels: ${scrollInfo.metrics.pixels}');
                print(
                    '📜 Max Scroll Extent: ${scrollInfo.metrics.maxScrollExtent}');
                print(
                    '📜 At Bottom: ${scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent}');
                print(
                    '📜 Difference: ${scrollInfo.metrics.maxScrollExtent - scrollInfo.metrics.pixels}');

                // Check if user has scrolled to the bottom (with more tolerance)
                final isNearBottom = scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent -
                        200; // Reduced tolerance for better detection
                print('📜 Is Near Bottom: $isNearBottom');
                print('📜 Tolerance: 200 pixels from bottom');

                // Also check if we're at the very bottom
                final isAtBottom = scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent;
                print('📜 Is At Bottom: $isAtBottom');

                // Check if list is not scrollable (all items fit on screen)
                final isNotScrollable = scrollInfo.metrics.maxScrollExtent <= 0;
                print('📜 Is Not Scrollable: $isNotScrollable');

                if (isNearBottom || isAtBottom || isNotScrollable) {
                  // Add some tolerance
                  // Get current state to check if we can load more
                  final currentState = context.read<SalonServicesBloc>().state;
                  print('📜 Current State Type: ${currentState.runtimeType}');

                  if (currentState is SalonServicesLoaded) {
                    print('📜 Has More Data: ${currentState.hasMoreData}');
                    print('📜 Current Page: ${currentState.currentPage}');
                    print('📜 Services Count: ${currentState.services.length}');

                    // Check if we can load more and not already loading
                    if (currentState.hasMoreData && !_isLoadingMore) {
                      print('📄 === LOADING MORE SERVICES ===');
                      print('📄 Current Page: ${currentState.currentPage}');
                      print('📄 Has More Data: ${currentState.hasMoreData}');

                      // Set loading flag to prevent duplicate requests
                      _isLoadingMore = true;

                      // Load next page with current filters from state
                      context.read<SalonServicesBloc>().add(
                            LoadMoreSalonServices(
                              page: currentState.currentPage + 1,
                              searchQuery: currentState.currentSearch,
                              minPrice: currentState.currentMinPrice,
                              maxPrice: currentState.currentMaxPrice,
                            ),
                          );
                    } else {
                      print(
                          '📜 Cannot load more - hasMoreData: ${currentState.hasMoreData}, currentPage: ${currentState.currentPage}, isLoadingMore: $_isLoadingMore');
                    }
                  } else {
                    print(
                        '📜 State is not SalonServicesLoaded: ${currentState.runtimeType}');
                  }
                }
                return false;
              },
              child: _buildServiceCards(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateServiceButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateServiceScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textPrimaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.getString(context, 'create_new_service'),
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.textPrimaryColor,
                shape: BoxShape.circle, // Makes it perfectly circular
                border: Border.all(
                  color: AppTheme
                      .secondaryColor, // Change to your desired border color
                  width: 2, // Border thickness
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCards() {
    return BlocBuilder<SalonServicesBloc, SalonServicesState>(
      builder: (context, state) {
        if (state is SalonServicesLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          );
        } else if (state is SalonServicesLoaded) {
          if (state.services.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.getString(context, 'no_services_found'),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Debug info - show current page and services count
          print('📊 === UI DEBUG INFO ===');
          print('📊 Current Page: ${state.currentPage}');
          print('📊 Services Count: ${state.services.length}');
          print('📊 Has More Data: ${state.hasMoreData}');

          return ListView.builder(
            controller: _listController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // Only services + bottom loader/end message (create button is now outside)
            itemCount: state.services.length +
                1, // Services + bottom loader/end message
            itemBuilder: (context, index) {
              // Debug: Print index information
              print('📋 === LISTVIEW BUILDER ===');
              print('📋 Index: $index');
              print('📋 Services Length: ${state.services.length}');
              print('📋 Has More Data: ${state.hasMoreData}');
              print('📋 Item Count: ${state.services.length + 1}');

              // Services start from index 0 now (no create button in ListView)
              final serviceIndex = index;
              if (serviceIndex >= state.services.length) {
                return const SizedBox.shrink(); // Safety check
              }

              // Show loading indicator or end message at the bottom
              if (index == state.services.length) {
                if (state.hasMoreData && _isLoadingMore) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.textPrimaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading page ${state.currentPage + 1}...',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.services.length} services loaded so far',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // End-of-data message (or just spacer if still more data but not currently loading)
                if (!state.hasMoreData) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.textSecondaryColor,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All services loaded',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.services.length} total services',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              }

              final service =
                  state.services[serviceIndex] as Map<String, dynamic>;

              // Debug: Print service details
              print('🆔 === SERVICE ${serviceIndex + 1} ===');
              print('🆔 Service ID: ${service['id']}');
              print('📝 Service Name: ${service['name']}');
              print('💰 Service Price: ${service['price']}');
              print('📄 Service Description: ${service['description']}');

              return Padding(
                padding: EdgeInsets.only(
                  bottom: serviceIndex < state.services.length - 1 ? 16.0 : 0.0,
                ),
                child: _buildServiceCard(
                  title: service['name'] ?? 'Service',
                  price: '${service['price'] ?? 0} €',
                  description:
                      service['description'] ?? 'No description available',
                  serviceId: service['id'],
                ),
              );
            },
          );
        } else if (state is SalonServicesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.error == 'TokenRefreshFailed' ||
                            state.error == 'NoRefreshToken'
                        ? 'Refreshing authentication...'
                        : state.message,
                    style: TextStyle(
                      color: state.error == 'TokenRefreshFailed' ||
                              state.error == 'NoRefreshToken'
                          ? AppTheme.textSecondaryColor
                          : Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<SalonServicesBloc>()
                          .add(LoadSalonServices());
                    },
                    child: Text(AppTranslations.getString(context, 'retry')),
                  ),
                ],
              ),
            ),
          );
        }

        // Default state - show loading
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String price,
    required String description,
    String? serviceId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.transparentBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textPrimaryColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.getTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          Text(
            price,
            style: AppTheme.getTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 5),

          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final textStyle = AppTheme.getTextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppTheme.textPrimaryColor,
              );

              final seeMoreText =
                  '... ${AppTranslations.getString(context, 'see_more')}';

              // Function to measure how many characters fit in 2 lines
              String truncateToTwoLines(String text) {
                final textPainter = TextPainter(
                  text: TextSpan(text: '$text$seeMoreText', style: textStyle),
                  textDirection: TextDirection.ltr,
                  maxLines: 2,
                );

                String temp = text;
                textPainter.layout(maxWidth: maxWidth);

                while (textPainter.didExceedMaxLines && temp.isNotEmpty) {
                  temp = temp.substring(0, temp.length - 1);
                  textPainter.text =
                      TextSpan(text: '$temp$seeMoreText', style: textStyle);
                  textPainter.layout(maxWidth: maxWidth);
                }
                return temp;
              }

              final truncatedDescription = truncateToTwoLines(description);

              return RichText(
                maxLines: 2,
                overflow: TextOverflow.clip,
                text: TextSpan(
                  children: [
                    TextSpan(text: truncatedDescription, style: textStyle),
                    TextSpan(
                      text: seeMoreText,
                      style: AppTheme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentColor,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: context.read<SalonServicesBloc>(),
                                child: ServiceDetailsScreen(
                                  serviceId: serviceId ?? '',
                                  serviceName: title,
                                  servicePrice: price,
                                  serviceDescription: description,
                                ),
                              ),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              );
            },
          ),
          // Description

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<SalonServicesBloc>(),
                            child: ServiceDetailsScreen(
                              serviceId: serviceId ?? '',
                              serviceName: title,
                              servicePrice: price,
                              serviceDescription: description,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.textPrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppTheme.textPrimaryColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      AppTranslations.getString(context, 'view_details'),
                      style: AppTheme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      print('🆔 === NAVIGATING TO EDIT SERVICE ===');
                      print('🆔 Service ID: $serviceId');
                      print('📝 Service Name: $title');
                      print('💰 Service Price: $price');
                      print('📄 Service Description: $description');

                      // SECURITY: Check if user owns this service before allowing edit
                      if (serviceId != null) {
                        print('🔒 === UI OWNERSHIP CHECK ===');
                        print('🔒 Service ID: $serviceId');
                        print('🔒 About to check ownership...');

                        // Use the current state data instead of making a separate API call
                        final currentState =
                            context.read<SalonServicesBloc>().state;
                        bool isOwned = false;

                        if (currentState is SalonServicesLoaded) {
                          // Check if the service exists in the current loaded services
                          final serviceExists = currentState.services.any(
                              (service) =>
                                  service['id']?.toString() ==
                                      serviceId.toString() ||
                                  service['_id']?.toString() ==
                                      serviceId.toString());

                          if (serviceExists) {
                            print(
                                '✅ Service found in current state - ownership verified');
                            isOwned = true;
                          } else {
                            print(
                                '❌ Service not found in current state - ownership check failed');
                            isOwned = false;
                          }
                        } else {
                          print(
                              '⚠️ Current state is not SalonServicesLoaded, falling back to API check');
                          // Fallback to API check if state is not loaded
                          isOwned = await SalonServicesService
                              .isServiceOwnedByCurrentUser(serviceId);
                        }

                        print('🔒 Ownership check result: $isOwned');

                        if (!isOwned) {
                          print('❌ UI: Ownership check failed, blocking edit');
                          TopNotificationService.showError(
                            context: context,
                            message: 'You can only edit your own services',
                          );
                          return;
                        } else {
                          print('✅ UI: Ownership check passed, allowing edit');
                        }
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<SalonServicesBloc>(),
                            child: EditServiceScreen(
                              serviceId: serviceId ?? '',
                              serviceName: title,
                              servicePrice: price,
                              serviceDescription: description,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.textPrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppTheme.textPrimaryColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      AppTranslations.getString(context, 'edit'),
                      style: AppTheme.getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navBarColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.textPrimaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                  child: _buildNavItem(0, Icons.list_alt,
                      AppTranslations.getString(context, 'services'))),
              Expanded(
                  child: _buildNavItem(1, Icons.campaign,
                      AppTranslations.getString(context, 'campaigns'))),
              Expanded(
                  child: _buildNavItem(2, Icons.account_balance_wallet,
                      AppTranslations.getString(context, 'wallet'))),
              Expanded(
                  child: _buildNavItem(3, Icons.people,
                      AppTranslations.getString(context, 'influencers'))),
              Expanded(
                  child: _buildNavItem(4, Icons.settings,
                      AppTranslations.getString(context, 'settings'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        // TODO: Navigate to different screens based on index
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppTheme.textPrimaryColor
                : AppTheme.navBartextColor,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.textPrimaryColor
                  : AppTheme.navBartextColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(
          bottom: 0), // Position exactly at top of nav bar
      child: FloatingActionButton(
        onPressed: () {
          _scanQRCode();
        },
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        shape: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.textPrimaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.textPrimaryColor.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.qr_code_scanner,
            size: 32,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    // Clear services bloc state to prevent data mixing
    context.read<SalonServicesBloc>().add(ResetSalonServices());

    // Trigger logout in auth bloc
    context.read<AuthBloc>().add(Logout());

    // Show logout success message
    TopNotificationService.showSuccess(
      context: context,
      message: 'Logged out successfully',
    );

    // Navigate to welcome screen and clear navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  void _createTestService() {
    print('🧪 === CREATING TEST SERVICE ===');

    // Create a test service
    context.read<SalonServicesBloc>().add(CreateSalonService(
          name: 'Test Service ${DateTime.now().millisecondsSinceEpoch}',
          price: 100,
          description: 'This is a test service created for debugging',
        ));

    TopNotificationService.showInfo(
      context: context,
      message: 'Creating test service...',
    );
  }

  void _scanQRCode() {
    // TODO: Implement QR code scanning functionality
    TopNotificationService.showInfo(
      context: context,
      message: AppTranslations.getString(context, 'qr_scanning_coming_soon'),
    );
  }
}
