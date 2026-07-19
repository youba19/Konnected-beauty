import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../core/bloc/influencer_details/influencer_details_bloc.dart';
import '../../../../core/models/filter_model.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import '../../../../widgets/common/motivational_banner.dart';
import 'influencer_details_screen.dart';
import 'influencers_filter_screen.dart';
import 'salon_settings_screen.dart';

/// Influencers tab — layout radius tokens (colors via [SalonUiTheme]).
abstract final class _SalonInfluencersUi {
  static const double searchRadius = 16;
  static const double buttonRadius = 14;
  static const double cardRadius = 16;
}

class InfluencersScreen extends StatefulWidget {
  const InfluencersScreen({super.key});

  @override
  State<InfluencersScreen> createState() => _InfluencersScreenState();
}

class _InfluencersScreenState extends State<InfluencersScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  String _profileInitial = 'K';

  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadProfileInitial();

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
        value: '50',
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
        print('🔍 Search Length: ${value.length}');
        print('🔍 Using backend API filtering for search');

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
            value: '50',
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
        print('🔍 Enabled filters:');
        for (final filter in filters.where((f) => f.enabled)) {
          print(
              '🔍   - ${filter.key}: "${filter.value}" (enabled: ${filter.enabled})');
        }
        print(
            '🔍 Search filter present: ${filters.any((f) => f.key == 'search' && f.enabled)}');

        // Apply filters using backend API filtering
        print('🔍 Dispatching FilterInfluencers event...');
        context
            .read<InfluencersBloc>()
            .add(FilterInfluencers(filters: filters));
      }
    });
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
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
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
    print('🔍 Using backend API filtering to clear all filters');

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
        value: '50',
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

    // Apply filters using backend API filtering
    context.read<InfluencersBloc>().add(FilterInfluencers(filters: filters));

    print('🔍 All filters cleared using backend API');
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

  List<FilterModel> _defaultFilters() {
    return [
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
        value: '50',
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
            child: BlocListener<InfluencersBloc, InfluencersState>(
              listener: (context, state) {
                if (state is InfluencersLoaded || state is InfluencersError) {
                  setState(() => _isLoadingMore = false);
                }
              },
              child: BlocBuilder<LanguageBloc, LanguageState>(
                builder: (context, languageState) {
                  final topInset = MediaQuery.paddingOf(context).top;

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      overscroll: false,
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        final currentState =
                            context.read<InfluencersBloc>().state;
                        if (currentState is InfluencersLoaded) {
                          final filters = List<FilterModel>.from(
                              currentState.currentFilters);
                          final pageFilterIndex =
                              filters.indexWhere((f) => f.key == 'page');
                          if (pageFilterIndex != -1) {
                            filters[pageFilterIndex] =
                                filters[pageFilterIndex].copyWith(
                              value: '1',
                              enabled: true,
                            );
                          }
                          context
                              .read<InfluencersBloc>()
                              .add(FilterInfluencers(filters: filters));
                        } else {
                          context.read<InfluencersBloc>().add(
                                FilterInfluencers(filters: _defaultFilters()),
                              );
                        }
                      },
                      color: Colors.white,
                      backgroundColor: SalonUiTheme.blueUpper,
                      displacement: topInset + 52,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          slivers: [
                            BlocBuilder<InfluencersBloc, InfluencersState>(
                              builder: (context, state) {
                                return SliverToBoxAdapter(
                                  child: _buildHeader(state),
                                );
                              },
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: MotivationalBanner(
                                  text: AppTranslations.getString(
                                    context,
                                    'select_ambassadors_message',
                                  ),
                                  icon: LucideIcons.lightbulb,
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
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  AppTranslations.getString(
                                      context, 'influencers'),
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
                            BlocBuilder<InfluencersBloc, InfluencersState>(
                              builder: (context, state) {
                                if (state is InfluencersLoading) {
                                  return _buildShimmerSliver();
                                }
                                if (state is InfluencersError) {
                                  return _buildErrorSliver(state);
                                }
                                if (state is InfluencersLoaded) {
                                  if (state.influencers.isEmpty) {
                                    return _buildEmptySliver(state);
                                  }
                                  return _buildInfluencersListSliver(
                                      state.influencers);
                                }
                                return SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: ui.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 96),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _onScrollNotification(ScrollNotification scrollInfo) {
    final isNearBottom =
        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200;
    final isAtBottom =
        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent;
    final isNotScrollable = scrollInfo.metrics.maxScrollExtent <= 0;

    if (isNearBottom || isAtBottom || isNotScrollable) {
      final currentState = context.read<InfluencersBloc>().state;
      if (currentState is InfluencersLoaded &&
          currentState.influencers.length < currentState.total &&
          !_isLoadingMore) {
        setState(() => _isLoadingMore = true);
        final filters = List<FilterModel>.from(currentState.currentFilters);
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
        context
            .read<InfluencersBloc>()
            .add(FilterInfluencers(filters: filters));
      }
    }
    return false;
  }

  Widget _buildErrorSliver(InfluencersError state) {
    final ui = SalonUiTheme.of(context);
    final isAccountNotActive =
        state.error.toLowerCase().contains('forbidden') ||
            state.error.toLowerCase().contains('403') ||
            (state.details != null &&
                state.details.toString().toLowerCase().contains('forbidden'));

    if (isAccountNotActive) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 80,
                    color: AppTheme.greenColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppTranslations.getString(context, 'account_not_active'),
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                AppTranslations.getString(context, 'connection_problem'),
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<InfluencersBloc>().add(LoadInfluencers());
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppTranslations.getString(context, 'retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySliver(InfluencersLoaded state) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.people_outline,
                color: AppTheme.textSecondaryColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                state.currentSearch != null
                    ? '${AppTranslations.getString(context, 'no_influencers_found_for')} "${state.currentSearch}"'
                    : AppTranslations.getString(
                        context, 'no_influencers_available'),
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

  Widget _buildHeader(InfluencersState state) {
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
                        _SalonInfluencersUi.searchRadius,
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
                          'search_influencers',
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
                  isActive: _hasActiveZoneFilter(state),
                  onTap: _showFilterScreen,
                ),
                if (_hasActiveZoneFilter(state)) ...[
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
    bool isActive = false,
  }) {
    final ui = SalonUiTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? ui.card : Colors.transparent,
          borderRadius: BorderRadius.circular(_SalonInfluencersUi.buttonRadius),
          border: Border.all(
            color: ui.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: ui.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildInfluencersListSliver(List<Map<String, dynamic>> influencers) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final influencer = influencers[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < influencers.length - 1 ? 12.0 : 0.0,
              ),
              child: _buildInfluencerCard(influencer),
            );
          },
          childCount: influencers.length,
        ),
      ),
    );
  }

  Widget _buildInfluencerCard(Map<String, dynamic> influencer) {
    final ui = SalonUiTheme.of(context);
    final pseudo = influencer['profile']?['pseudo'] ?? 'unknown';
    final zone = influencer['profile']?['zone'] ?? 'Unknown';
    final rating = influencer['averageRating']?.toStringAsFixed(1) ?? '0.0';
    final pictureUrl = influencer['profile']?['profilePicture']?.toString();

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
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ui.cardAlt,
          borderRadius: BorderRadius.circular(_SalonInfluencersUi.cardRadius),
          border: Border.all(
            color: ui.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    child: ClipOval(
                      child: pictureUrl != null && pictureUrl.isNotEmpty
                          ? Image.network(
                              pictureUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _avatarPlaceholder();
                              },
                            )
                          : _avatarPlaceholder(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ui.isDark
                              ? Colors.black.withValues(alpha: 0.78)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ui.isDark
                                ? Colors.white.withValues(alpha: 0.2)
                                : ui.cardBorder,
                            width: 1,
                          ),
                          boxShadow: ui.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rating,
                              style: TextStyle(
                                color: ui.isDark
                                    ? Colors.white
                                    : ui.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFC107),
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@$pseudo',
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    zone,
                    style: TextStyle(
                      color: ui.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFF2C2C2E),
      child: const Icon(
        Icons.person,
        color: Colors.white54,
        size: 28,
      ),
    );
  }

  Widget _buildShimmerSliver() {
    final ui = SalonUiTheme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < 4 ? 12.0 : 0.0,
              ),
              child: Shimmer.fromColors(
                baseColor: ui.isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: ui.isDark ? Colors.grey[600]! : Colors.grey[100]!,
                child: _buildShimmerInfluencerCard(ui),
              ),
            );
          },
          childCount: 5,
        ),
      ),
    );
  }

  Widget _buildShimmerInfluencerCard(SalonUiTheme ui) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.cardAlt,
        borderRadius: BorderRadius.circular(_SalonInfluencersUi.cardRadius),
        border: Border.all(
          color: ui.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 72,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2E),
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 12,
                        width: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 17,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 15,
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
