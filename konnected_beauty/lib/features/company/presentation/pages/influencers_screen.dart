import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../core/bloc/influencer_details/influencer_details_bloc.dart';
import '../../../../core/models/filter_model.dart';
import 'influencer_details_screen.dart';
import 'influencers_filter_screen.dart';

class InfluencersScreen extends StatefulWidget {
  const InfluencersScreen({super.key});

  @override
  State<InfluencersScreen> createState() => _InfluencersScreenState();
}

class _InfluencersScreenState extends State<InfluencersScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();

    print('🎬 === INFLUENCERS SCREEN INIT ===');
    print('🎬 Screen initialized, loading influencers...');
    print('🎬 Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    // Load influencers on screen initialization using filter system
    final defaultFilters = [
      FilterModel(
        key: 'page',
        value: '1',
        description: 'Page number',
        enabled: true,
        equals: true,
        uuid: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      FilterModel(
        key: 'limit',
        value: '10',
        description: 'Items per page',
        enabled: true,
        equals: true,
        uuid: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      ),
      FilterModel(
        key: 'sortOrder',
        value: 'DESC',
        description: 'Sort order',
        enabled: true,
        equals: true,
        uuid: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
      ),
    ];
    context
        .read<InfluencersBloc>()
        .add(FilterInfluencers(filters: defaultFilters));

    // Add search listener with debounce
    searchController.addListener(() => _onSearchChanged(searchController.text));

    // Add scroll listener for pagination
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Set new timer for debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('🔍 === SEARCH CHANGED ===');
        print('🔍 Search Value: "$value"');

        // Get current filters from state
        final currentState = context.read<InfluencersBloc>().state;
        List<FilterModel> filters = [];

        if (currentState is InfluencersLoaded) {
          filters = List.from(currentState.currentFilters);
        }

        // Create or update search filter
        if (value.isEmpty) {
          // Remove search filter if search is empty and reset to page 1
          filters.removeWhere((filter) => filter.key == 'search');

          // Reset page to 1 when clearing search
          final pageFilterIndex =
              filters.indexWhere((filter) => filter.key == 'page');
          if (pageFilterIndex != -1) {
            filters[pageFilterIndex] = filters[pageFilterIndex].copyWith(
              value: '1',
              enabled: true,
            );
          } else {
            filters.add(FilterModel(
              key: 'page',
              value: '1',
              description: 'Page number',
              enabled: true,
              equals: true,
              uuid: DateTime.now().millisecondsSinceEpoch.toString(),
            ));
          }

          print('🔍 Cleared search, reset to page 1');
        } else {
          // Add or update search filter
          final searchFilterIndex =
              filters.indexWhere((filter) => filter.key == 'search');
          if (searchFilterIndex != -1) {
            filters[searchFilterIndex] = filters[searchFilterIndex].copyWith(
              value: value,
              enabled: true,
            );
          } else {
            filters.add(FilterModel(
              key: 'search',
              value: value,
              description: 'Search by name or bio',
              enabled: true,
              equals: true,
              uuid: DateTime.now().millisecondsSinceEpoch.toString(),
            ));
          }

          // Reset page to 1 when searching
          final pageFilterIndex =
              filters.indexWhere((filter) => filter.key == 'page');
          if (pageFilterIndex != -1) {
            filters[pageFilterIndex] = filters[pageFilterIndex].copyWith(
              value: '1',
              enabled: true,
            );
          } else {
            filters.add(FilterModel(
              key: 'page',
              value: '1',
              description: 'Page number',
              enabled: true,
              equals: true,
              uuid: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            ));
          }

          print('🔍 Added search filter: "$value", reset to page 1');
        }

        // Ensure we have default filters
        if (!filters.any((f) => f.key == 'limit' && f.enabled)) {
          filters.add(FilterModel(
            key: 'limit',
            value: '10',
            description: 'Items per page',
            enabled: true,
            equals: true,
            uuid: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          ));
        }

        if (!filters.any((f) => f.key == 'sortOrder' && f.enabled)) {
          filters.add(FilterModel(
            key: 'sortOrder',
            value: 'DESC',
            description: 'Sort order',
            enabled: true,
            equals: true,
            uuid: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
          ));
        }

        print('🔍 Final filters count: ${filters.length}');
        for (final filter in filters.where((f) => f.enabled)) {
          print('🔍   - ${filter.key}: ${filter.value}');
        }

        // Apply filters using the new filter system
        context
            .read<InfluencersBloc>()
            .add(FilterInfluencers(filters: filters));
      }
    });
  }

  void _onScrollChanged() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more influencers when near the bottom
      final currentState = context.read<InfluencersBloc>().state;
      if (currentState is InfluencersLoaded && currentState.hasMoreData) {
        print('📄 === LOADING MORE INFLUENCERS ===');
        print('📄 Current Page: ${currentState.currentPage}');
        print('📄 Total Pages: ${currentState.totalPages}');
        print('📄 Has More Data: ${currentState.hasMoreData}');

        // Create filters for pagination
        List<FilterModel> filters = List.from(currentState.currentFilters);

        // Update page filter
        final pageFilterIndex =
            filters.indexWhere((filter) => filter.key == 'page');
        if (pageFilterIndex != -1) {
          filters[pageFilterIndex] = filters[pageFilterIndex].copyWith(
            value: (currentState.currentPage + 1).toString(),
            enabled: true,
          );
        } else {
          filters.add(FilterModel(
            key: 'page',
            value: (currentState.currentPage + 1).toString(),
            description: 'Page number',
            enabled: true,
            equals: true,
            uuid: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
        }

        print('📄 Loading page: ${currentState.currentPage + 1}');
        context
            .read<InfluencersBloc>()
            .add(FilterInfluencers(filters: filters));
      }
    }
  }

  void _showFilterScreen() {
    final currentState = context.read<InfluencersBloc>().state;
    String? currentZone;

    if (currentState is InfluencersLoaded) {
      // Extract current zone filter from the current filters
      final zoneFilter = currentState.currentFilters.firstWhere(
        (f) => f.key == 'zone' && f.enabled,
        orElse: () => FilterModel(
          key: 'zone',
          value: '',
          description: 'Location zone',
          enabled: false,
          equals: true,
          uuid: '',
        ),
      );

      currentZone = zoneFilter.enabled ? zoneFilter.value : null;
    } else {
      // Default values
      currentZone = null;
    }

    print('🔍 === SHOWING FILTER SCREEN ===');
    print('🔍 Current Zone: $currentZone');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InfluencersFilterScreen(
        currentZone: currentZone,
        onFilterApplied: (zone) {
          print('🔍 Filter applied: Zone=$zone');
          // This callback is called when filters are applied
          // The actual filtering is handled by the InfluencersFilterScreen
        },
      ),
    );
  }

  void _clearFilters() {
    print('🔍 === CLEARING ALL FILTERS ===');

    // Create default filters (no zone filter)
    List<FilterModel> filters = [
      FilterModel(
        key: 'page',
        value: '1',
        description: 'Page number',
        enabled: true,
        equals: true,
        uuid: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      FilterModel(
        key: 'limit',
        value: '10',
        description: 'Items per page',
        enabled: true,
        equals: true,
        uuid: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      ),
      FilterModel(
        key: 'sortOrder',
        value: 'DESC',
        description: 'Sort order',
        enabled: true,
        equals: true,
        uuid: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
      ),
    ];

    // Clear search
    searchController.clear();

    // Apply filters to reload without any zone filter
    context.read<InfluencersBloc>().add(FilterInfluencers(filters: filters));

    print('🔍 All filters cleared');
  }

  bool _hasActiveZoneFilter(InfluencersState state) {
    if (state is InfluencersLoaded) {
      // Check if there's an active zone filter only
      final zoneFilter = state.currentFilters.firstWhere(
        (f) => f.key == 'zone' && f.enabled,
        orElse: () => FilterModel(
          key: 'zone',
          value: '',
          description: 'Location zone',
          enabled: false,
          equals: true,
          uuid: '',
        ),
      );

      // Only show reset button when zone filter is active
      return zoneFilter.enabled;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 === INFLUENCERS SCREEN BUILD ===');
    print('🎨 Screen is being built...');
    print('🎨 Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
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
                  // Header Section with BLoC state management
                  BlocBuilder<InfluencersBloc, InfluencersState>(
                    builder: (context, state) {
                      return _buildHeader(state);
                    },
                  ),

                  // Main Content
                  Expanded(
                    child: BlocBuilder<InfluencersBloc, InfluencersState>(
                      builder: (context, state) {
                        if (state is InfluencersLoading) {
                          return _buildShimmerList();
                        } else if (state is InfluencersError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                if (state.error
                                        .contains('Account not active') ||
                                    state.error.contains('Forbidden') ||
                                    state.error.contains('403'))
                                  Column(
                                    children: [
                                      Text(
                                        'Your salon account is not yet active. Please contact support to activate your account.',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () {
                                      final currentState =
                                          context.read<InfluencersBloc>().state;
                                      if (currentState is InfluencersLoaded) {
                                        context
                                            .read<InfluencersBloc>()
                                            .add(LoadInfluencers(
                                              zone: currentState.currentZone,
                                              sortOrder:
                                                  currentState.currentSortOrder,
                                            ));
                                      } else {
                                        context
                                            .read<InfluencersBloc>()
                                            .add(LoadInfluencers());
                                      }
                                    },
                                    child: Text(
                                      AppTranslations.getString(
                                          context, 'retry'),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        } else if (state is InfluencersLoaded) {
                          if (state.influencers.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    color: AppTheme.textSecondaryColor,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.currentSearch != null
                                        ? 'No influencers found for "${state.currentSearch}"'
                                        : 'No influencers available',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }
                          return _buildMainContent(state.influencers);
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentColor,
                            ),
                          );
                        }
                      },
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

  Widget _buildHeader(InfluencersState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppTranslations.getString(context, 'influencers'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
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
                    onChanged: _onSearchChanged,
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
                  color: _hasActiveZoneFilter(state)
                      ? AppTheme.textPrimaryColor
                      : AppTheme.transparentBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textPrimaryColor,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: _hasActiveZoneFilter(state)
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  onPressed: _showFilterScreen,
                ),
              ),
              if (_hasActiveZoneFilter(state)) ...[
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

  Widget _buildMainContent(List<Map<String, dynamic>> influencers) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: influencers.length,
      itemBuilder: (context, index) {
        final influencer = influencers[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < influencers.length - 1 ? 16.0 : 0.0,
          ),
          child: _buildInfluencerCard(influencer),
        );
      },
    );
  }

  Widget _buildInfluencerCard(Map<String, dynamic> influencer) {
    return GestureDetector(
      onTap: () {
        final influencerId = influencer['id'];
        if (influencerId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => InfluencerDetailsBloc(),
                child: InfluencerDetailsScreen(
                  influencerId: influencerId,
                ),
              ),
            ),
          );
        } else {
          print('❌ Influencer ID is null, cannot navigate to detail screen');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Image + Username + Zone
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                ClipOval(
                  child: influencer['profile']?['profilePicture'] != null
                      ? Image.network(
                          influencer['profile']['profilePicture'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color:
                                  AppTheme.textSecondaryColor.withOpacity(0.3),
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.textSecondaryColor,
                                size: 20,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          color: AppTheme.textSecondaryColor.withOpacity(0.3),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.textPrimaryColor,
                            size: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 10),

                // Username + Rating + Zone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '@${influencer['profile']?['pseudo'] ?? 'unknown'}',
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Rating + Zone Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating (left side)
                          Row(
                            children: [
                              Text(
                                '${influencer['averageRating']?.toStringAsFixed(1) ?? '0.0'}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                color: AppTheme.textSecondaryColor,
                                size: 16,
                              ),
                            ],
                          ),
                          // Zone (right side)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppTheme.textSecondaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                influencer['profile']?['zone'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description with "See more"
            LayoutBuilder(
              builder: (context, constraints) {
                final text = influencer['profile']?['bio'] ?? '';
                final seeMore =
                    "...${AppTranslations.getString(context, 'see_more')}     "; // 5 spaces

                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: text,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      TextSpan(
                        text: seeMore,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: const Text(
            'To activate your salon account, please contact our support team:\n\n'
            '📧 Email: support@konnectedbeauty.com\n'
            '📱 Phone: +1 (555) 123-4567\n\n'
            'We\'ll help you get your account activated quickly!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Show 5 shimmer items
        itemBuilder: (context, index) {
          return _buildShimmerInfluencerCard();
        },
      ),
    );
  }

  Widget _buildShimmerInfluencerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Shimmer avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          // Shimmer content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Container(
                  height: 18,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                // Bio
                Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                // Zone and rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
