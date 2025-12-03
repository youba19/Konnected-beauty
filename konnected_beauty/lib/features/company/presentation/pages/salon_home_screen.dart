import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/salon_services_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../auth/presentation/pages/welcome_screen.dart';
import 'create_service_screen.dart';
import 'service_details_screen.dart';
import 'edit_service_screen.dart';
import 'service_filter_screen.dart';
import 'influencers_screen.dart';
import 'qr_scanner_screen.dart';
import '../../../../widgets/common/motivational_banner.dart';

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
          child: GestureDetector(
            onTap: () {
              // Close keyboard when tapping outside text fields
              FocusScope.of(context).unfocus();
            },
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
        ),
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
        return RefreshIndicator(
          onRefresh: () async {
            _resetScrollAndLoadingState();
            context.read<SalonServicesBloc>().add(RefreshSalonServices());
          },
          color: AppTheme.textPrimaryColor,
          backgroundColor: AppTheme.transparentBackground,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // Check if user has scrolled to the bottom
              final isNearBottom = scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200;
              final isAtBottom = scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent;
              final isNotScrollable = scrollInfo.metrics.maxScrollExtent <= 0;

              if (isNearBottom || isAtBottom || isNotScrollable) {
                final currentState = context.read<SalonServicesBloc>().state;
                if (currentState is SalonServicesLoaded) {
                  if (currentState.hasMoreData && !_isLoadingMore) {
                    _isLoadingMore = true;
                    context.read<SalonServicesBloc>().add(
                          LoadMoreSalonServices(
                            page: currentState.currentPage + 1,
                            searchQuery: currentState.currentSearch,
                            minPrice: currentState.currentMinPrice,
                            maxPrice: currentState.currentMaxPrice,
                          ),
                        );
                  }
                }
              }
              return false;
            },
            child: CustomScrollView(
              controller: _listController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Success Banner (if needed)
                if (_showDeleteSuccess)
                  SliverToBoxAdapter(
                    child: _buildDeleteSuccessBanner(),
                  ),

                // Header Section
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                // Motivational Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: MotivationalBanner(
                      text: AppTranslations.getString(
                          context, 'offers_attractive_message'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Create Service Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildCreateServiceButton(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Services List
                _buildServiceCardsSliver(),
              ],
            ),
          ),
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

  Widget _buildServiceCardsSliver() {
    return BlocBuilder<SalonServicesBloc, SalonServicesState>(
      builder: (context, state) {
        if (state is SalonServicesLoading) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < 4 ? 16.0 : 0.0,
                  ),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[600]!,
                    child: _buildShimmerServiceCard(),
                  ),
                ),
                childCount: 5,
              ),
            ),
          );
        } else if (state is SalonServicesLoaded) {
          if (state.services.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
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
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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

                    // End-of-data message
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

                  // Service card
                  if (index < state.services.length) {
                    final service =
                        state.services[index] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildServiceCard(
                        title: service['name'] ?? 'Service',
                        price: '${service['price'] ?? 0} €',
                        description: service['description'] ??
                            'No description available',
                        serviceId: service['id']?.toString(),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
                childCount: state.services.length + 1,
              ),
            ),
          );
        } else if (state is SalonServicesError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error ?? state.message,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const SliverToBoxAdapter(
            child: SizedBox.shrink(),
          );
        }
      },
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
          return _buildShimmerList();
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connection Problem',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your internet connection and try again.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<SalonServicesBloc>()
                          .add(LoadSalonServices());
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(AppTranslations.getString(context, 'retry')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                  child: _buildNavItem(0, LucideIcons.clipboardList,
                      AppTranslations.getString(context, 'services'))),
              Expanded(
                  child: _buildNavItem(1, LucideIcons.ticket,
                      AppTranslations.getString(context, 'campaigns'))),
              Expanded(
                  child: _buildNavItem(2, LucideIcons.wallet,
                      AppTranslations.getString(context, 'wallet'))),
              Expanded(
                  child: _buildNavItem(3, LucideIcons.users,
                      AppTranslations.getString(context, 'influencers'))),
              Expanded(
                  child: _buildNavItem(4, LucideIcons.settings2,
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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimaryColor
                    : AppTheme.navBartextColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(
          bottom: 0), // Position exactly at top of nav bar
      child: _buildLiquidGlassButton(),
    );
  }

  Widget _buildLiquidGlassButton() {
    return GestureDetector(
      onTap: () {
        _scanQRCode();
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.2,
              ),
              boxShadow: [
                // Outer glow for depth
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
                // Drop shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Liquid glass highlight - main
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        radius: 1.0,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Secondary liquid highlight
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content
                const Center(
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 32,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Future<void> _scanQRCode() async {
    // Check camera permission before opening QR scanner
    final status = await Permission.camera.status;

    if (status == PermissionStatus.granted) {
      // Permission granted, open QR scanner
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const QRScannerScreen(),
          ),
        );
      }
    } else if (status == PermissionStatus.denied) {
      // Request permission
      final requestResult = await Permission.camera.request();
      if (requestResult == PermissionStatus.granted && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const QRScannerScreen(),
          ),
        );
      } else if (requestResult == PermissionStatus.permanentlyDenied &&
          mounted) {
        _showPermissionSettingsDialog();
      } else if (mounted) {
        TopNotificationService.showError(
          context: context,
          message: 'Camera permission is required to scan QR codes',
        );
      }
    } else if (status == PermissionStatus.permanentlyDenied) {
      // Show settings dialog
      if (mounted) {
        _showPermissionSettingsDialog();
      }
    }
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.scaffoldBackground,
          title: Text(
            'Camera Permission Required',
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Camera access is required to scan QR codes. Please enable it in your device settings.',
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                'Open Settings',
                style: const TextStyle(
                  color: AppTheme.greenColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 5, // Show 5 shimmer items
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < 4 ? 16.0 : 0.0,
            ),
            child: _buildShimmerServiceCard(),
          );
        },
      ),
    );
  }

  Widget _buildShimmerServiceCard() {
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
          // Title row (matching actual service card layout)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 20,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Price row (separate from title, matching actual layout)
          Container(
            height: 16,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 5),

          // Description shimmer (matching actual description layout)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 14,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons row (matching actual button layout)
          Row(
            children: [
              // View Details button shimmer
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[600]!,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Edit button shimmer
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[600]!,
                      width: 1,
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
}
