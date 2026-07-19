import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../auth/presentation/pages/welcome_screen.dart';
import 'create_service_screen.dart';
import 'service_details_screen.dart';
import 'service_filter_screen.dart';
import 'influencers_screen.dart';
import 'qr_scanner_screen.dart';
import '../../../../widgets/common/motivational_banner.dart';
import 'salon_settings_screen.dart';

/// Salon services tab — layout radius tokens (colors via [SalonUiTheme]).
abstract final class _SalonServicesUi {
  static const double radius = 16;
  static const double searchRadius = 16;
  static const double buttonRadius = 14;
  static const double serviceCardRadius = 16;
}

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
  String _profileInitial = 'K';

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
    _loadProfileInitial();

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

  Future<void> _loadProfileInitial() async {
    try {
      final result = await SalonProfileService().getSalonProfile();
      if (!mounted || result['success'] != true) return;
      final data = result['data'] as Map<String, dynamic>?;
      final salonName = data?['salonInfo']?['name']?.toString() ?? '';
      final personalName = data?['name']?.toString() ?? '';
      final source = salonName.isNotEmpty ? salonName : personalName;
      if (source.isNotEmpty) {
        setState(() => _profileInitial = source[0].toUpperCase());
      }
    } catch (_) {
      // Keep default initial.
    }
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
    final ui = SalonUiTheme.of(context);
    return ColoredBox(
      color: ui.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
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
        final ui = SalonUiTheme.of(context);
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            overscroll: false,
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              _resetScrollAndLoadingState();
              context.read<SalonServicesBloc>().add(RefreshSalonServices());
            },
            color: Colors.white,
            backgroundColor: SalonUiTheme.blueUpper,
            displacement: MediaQuery.paddingOf(context).top + 52,
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
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: MotivationalBanner(
                      text: AppTranslations.getString(
                          context, 'offers_attractive_message'),
                      icon: LucideIcons.lamp,
                      backgroundColor: ui.bannerFill,
                      textColor: ui.textPrimary,
                      fontWeight: FontWeight.w400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),

                // Section title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppTranslations.getString(context, 'services'),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Services List
                _buildServiceCardsSliver(),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 96),
                ),
              ],
            ),
          ),
          ),
        );
      },
    ));
  }

  Widget _buildHeader() {
    final ui = SalonUiTheme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ui.headerGradient,
              stops: ui.headerStops,
            ),
          ),
          padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/Konected beauty - Logo white.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SalonSettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: SalonUiTheme.profileBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _profileInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
        ColoredBox(
          color: ui.bg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        _SalonServicesUi.searchRadius,
                      ),
                      border: Border.all(
                        color: ui.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: AppTranslations.getString(
                          context,
                          'search_services',
                        ),
                        hintStyle: TextStyle(
                          color: ui.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: ui.textSecondary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildHeaderIconButton(
                  icon: LucideIcons.listFilter,
                  isActive:
                      _currentMinPrice != null || _currentMaxPrice != null,
                  onTap: _showFilterScreen,
                ),
                const SizedBox(width: 10),
                _buildHeaderIconButton(
                  icon: LucideIcons.plusCircle,
                  filled: true,
                  iconColor: const Color(0xFF1F1F1F),
                  iconSize: 26,
                  fillColor: const Color(0xFFE9E9EB),
                  borderColor: Colors.transparent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateServiceScreen(),
                      ),
                    );
                  },
                ),
                if (_currentMinPrice != null || _currentMaxPrice != null) ...[
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(
                    icon: LucideIcons.x,
                    onTap: _clearFilters,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    bool isActive = false,
    double iconSize = 22,
    Color? fillColor,
    Color? iconColor,
    Color? borderColor,
  }) {
    final ui = SalonUiTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: filled
              ? (fillColor ?? ui.iconButtonBg)
              : (isActive ? ui.card : Colors.transparent),
          borderRadius: BorderRadius.circular(_SalonServicesUi.buttonRadius),
          border: Border.all(
            color: borderColor ?? ui.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor ?? ui.textPrimary,
          size: iconSize,
        ),
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
          final ui = SalonUiTheme.of(context);
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < 4 ? 16.0 : 0.0,
                  ),
                  child: Shimmer.fromColors(
                    baseColor: ui.isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    highlightColor:
                        ui.isDark ? Colors.grey[600]! : Colors.grey[100]!,
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

                    // End-of-data message intentionally hidden (per design).
                    if (!state.hasMoreData) return const SizedBox.shrink();
                    return const SizedBox.shrink();
                  }

                  // Service card
                  if (index < state.services.length) {
                    final service =
                        state.services[index] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
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

  Widget _buildShimmerServiceCard() {
    final ui = SalonUiTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: ui.cardAlt,
        borderRadius: BorderRadius.circular(_SalonServicesUi.serviceCardRadius),
        border: Border.all(
          color: ui.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String price,
    required String description,
    String? serviceId,
  }) {
    final ui = SalonUiTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_SalonServicesUi.serviceCardRadius),
        onTap: () {
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: ui.cardAlt,
            borderRadius:
                BorderRadius.circular(_SalonServicesUi.serviceCardRadius),
            border: Border.all(
              color: ui.cardBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ui.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: ui.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
                maxLines: 2,
              ),
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
}
