import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_event.dart';
import '../../../../core/bloc/campaigns/campaigns_state.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import 'campaign_details_screen.dart';
import 'salon_settings_screen.dart';

/// Campaigns tab — layout radius tokens (colors via [SalonUiTheme]).
abstract final class _SalonCampaignsUi {
  static const double searchRadius = 16;
  static const double buttonRadius = 14;
  static const double cardRadius = 24;
  static const double imageWidth = 96;
}

class CampaignsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToInfluencers;

  const CampaignsScreen({super.key, this.onNavigateToInfluencers});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  String? _currentStatus;
  String _currentSearch = '';
  String _profileInitial = 'K';
  final PageController _carouselController = PageController();
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadProfileInitial();

    print('🎬 === CAMPAIGNS SCREEN INIT ===');
    print('🎬 Screen initialized, loading campaigns...');
    print('🎬 Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    // Add search listener with debounce (same as influencers)
    searchController.addListener(() => _onSearchChanged(searchController.text));

    // Load initial campaigns with all statuses
    _currentStatus = 'all';
    print('🚀 === INITIAL CAMPAIGNS LOAD ===');
    context.read<CampaignsBloc>().add(LoadCampaigns(
          status: null, // Load all campaigns
          limit: 10, // Use normal page size like influencers
        ));
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
    _carouselController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Set new timer for debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentSearch = value;
        });
        print('🔍 === SEARCH CHANGED ===');
        print('🔍 Search Value: "$value"');
        print('🔍 Search Length: ${value.length}');
        print('🔍 Current Status: $_currentStatus');
        print('🔍 Current Search: "$_currentSearch"');
      }
    });
  }

  void _showFilterScreen() {
    print('🔍 === SHOWING FILTER SCREEN ===');
    print('🔍 Current Status: "$_currentStatus"');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => _buildFilterModal(),
    );
  }

  Widget _buildFilterModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        final ui = SalonUiTheme.of(context);
        final options = <({String key, String label})>[
          (
            key: 'all',
            label: AppTranslations.getString(context, 'all'),
          ),
          (
            key: 'pending',
            label: AppTranslations.getString(context, 'pending'),
          ),
          (
            key: 'in progress',
            label: AppTranslations.getString(context, 'on_going'),
          ),
          (
            key: 'finished',
            label: AppTranslations.getString(context, 'finished'),
          ),
          (
            key: 'rejected',
            label: AppTranslations.getString(context, 'rejected'),
          ),
        ];

        final active = (_currentStatus ?? 'all');

        return Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 170,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppTranslations.getString(
                                context,
                                'filter_campaigns',
                              ),
                              style: TextStyle(
                                color: ui.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ui.sheetOverlayButton,
                                borderRadius: BorderRadius.circular(
                                  _SalonCampaignsUi.buttonRadius,
                                ),
                                border: Border.all(
                                  color: ui.cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.x,
                                color: ui.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppTranslations.getString(context, 'campaign_status'),
                        style: TextStyle(
                          color: ui.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...options.map((o) {
                        final isSelected = active == o.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => setModalState(
                              () => _currentStatus = o.key,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: ui.card,
                                borderRadius: BorderRadius.circular(
                                  _SalonCampaignsUi.cardRadius,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? ui.textPrimary
                                      : ui.cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      o.label,
                                      style: TextStyle(
                                        color: ui.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      LucideIcons.check,
                                      color: ui.textPrimary,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() => _currentStatus = 'all');
                                Navigator.of(context).pop();
                                _applyFilters();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ui.textPrimary,
                                side: BorderSide(
                                  color: ui.outlinedButtonBorder,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _SalonCampaignsUi.cardRadius,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                AppTranslations.getString(context, 'clear'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _applyFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ui.primaryButtonBg,
                                foregroundColor: ui.primaryButtonFg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _SalonCampaignsUi.cardRadius,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                AppTranslations.getString(context, 'apply'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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

  void _clearFilters() {
    setState(() {
      _currentStatus = 'all';
    });
    _applyFilters();
  }

  void _applyFilters() {
    print('🔍 === APPLYING FILTERS ===');
    print('🔍 Status: $_currentStatus');

    setState(() {
      // This will trigger a rebuild to update the filter icon color
    });

    context.read<CampaignsBloc>().add(LoadCampaigns(
          status: _currentStatus == 'all' ? null : _currentStatus,
          limit: 10,
        ));
  }

  void _goToInfluencers() {
    print('Navigate to influencers screen');

    if (widget.onNavigateToInfluencers != null) {
      // Use the callback to navigate to influencers
      widget.onNavigateToInfluencers!();
    } else {
      print('No callback provided, showing fallback message');
      // Fallback: Show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppTranslations.getString(context, 'go_to_influencers_message')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterCampaigns(
      List<Map<String, dynamic>> campaigns) {
    // First, filter out deleted campaigns (case-insensitive, trim whitespace)
    final nonDeletedCampaigns = campaigns.where((campaign) {
      final status = campaign['status']?.toString().toLowerCase().trim() ?? '';
      return status != 'deleted' && status.isNotEmpty;
    }).toList();

    if (_currentSearch.isEmpty) {
      return nonDeletedCampaigns;
    }

    final searchLower = _currentSearch.toLowerCase();
    return nonDeletedCampaigns.where((campaign) {
      // Search in influencer pseudo
      final influencer = campaign['influencer']?['profile'] ?? {};
      final pseudo = influencer['pseudo'] ?? '';
      final pseudoMatch = pseudo.toLowerCase().contains(searchLower);

      // Search in salon name (if available)
      final salon = campaign['salon']?['salonInfo'] ?? {};
      final salonName = salon['name'] ?? '';
      final salonMatch = salonName.toLowerCase().contains(searchLower);

      // Search in status
      final status = campaign['status'] ?? '';
      final statusMatch = status.toLowerCase().contains(searchLower);

      return pseudoMatch || salonMatch || statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 === BUILD METHOD ===');
    print('🔍 Current Status: "$_currentStatus"');
    print(
        '🔍 Icon Color: ${(_currentStatus != null && _currentStatus != 'all') ? "WHITE" : "DEFAULT"}');

    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final ui = SalonUiTheme.of(context);
        final topInset = MediaQuery.paddingOf(context).top;

        return ColoredBox(
          color: ui.bg,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: BlocListener<CampaignsBloc, CampaignsState>(
                  listener: (context, state) {
                    if (state is CampaignsLoaded ||
                        state is CampaignsError ||
                        state is CampaignsLoadingMore) {
                      setState(() => _isLoadingMore = false);
                    }
                  },
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<CampaignsBloc>().add(
                            RefreshCampaigns(
                              status: _currentStatus == 'all'
                                  ? null
                                  : _currentStatus,
                              limit: 10,
                            ),
                          );
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
                          SliverToBoxAdapter(child: _buildHeader(topInset)),
                          BlocBuilder<CampaignsBloc, CampaignsState>(
                            builder: (context, state) {
                              if (state is CampaignsLoading) {
                                return _buildShimmerSliver();
                              }
                              if (state is CampaignsError) {
                                return SliverToBoxAdapter(
                                  child: _buildErrorState(state),
                                );
                              }

                              if (state is CampaignsLoaded) {
                                final campaigns = state.campaigns
                                    .cast<Map<String, dynamic>>();
                                final filteredCampaigns =
                                    _filterCampaigns(campaigns);

                                final total = state.total;
                                final totalClicks = campaigns.fold<int>(
                                  0,
                                  (sum, c) =>
                                      sum + (c['clicks'] as int? ?? 0),
                                );

                                if (filteredCampaigns.isEmpty) {
                                  return SliverToBoxAdapter(
                                    child: _buildNoCampaignsState(),
                                  );
                                }

                                return _buildCampaignsListSliver(
                                  filteredCampaigns: filteredCampaigns,
                                  totalCampaigns: total,
                                  totalClicks: totalClicks,
                                  isLoadingMore: false,
                                );
                              }

                              if (state is CampaignsLoadingMore) {
                                final campaigns = state.campaigns
                                    .cast<Map<String, dynamic>>();
                                final filteredCampaigns =
                                    _filterCampaigns(campaigns);

                                final total = state.total;
                                final totalClicks = campaigns.fold<int>(
                                  0,
                                  (sum, c) =>
                                      sum + (c['clicks'] as int? ?? 0),
                                );

                                if (filteredCampaigns.isEmpty) {
                                  return SliverToBoxAdapter(
                                    child: _buildNoCampaignsState(),
                                  );
                                }

                                return _buildCampaignsListSliver(
                                  filteredCampaigns: filteredCampaigns,
                                  totalCampaigns: total,
                                  totalClicks: totalClicks,
                                  isLoadingMore: true,
                                );
                              }

                              return SliverToBoxAdapter(
                                child: _buildInitialState(),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _onScrollNotification(ScrollNotification scrollInfo) {
    final isNearBottom =
        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200;
    final isAtBottom =
        scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent;
    final isNotScrollable = scrollInfo.metrics.maxScrollExtent <= 0;

    if (isNearBottom || isAtBottom || isNotScrollable) {
      final currentState = context.read<CampaignsBloc>().state;
      if (currentState is CampaignsLoaded &&
          currentState.hasMore &&
          !_isLoadingMore) {
        _isLoadingMore = true;
        context.read<CampaignsBloc>().add(
              LoadMoreCampaigns(
                page: currentState.currentPage + 1,
                search: currentState.currentSearch,
                status: currentState.currentStatus ??
                    (_currentStatus == 'all' ? null : _currentStatus),
              ),
            );
      }
    }
    return false;
  }

  Widget _buildHeader(double topInset) {
    final ui = SalonUiTheme.of(context);

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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        _SalonCampaignsUi.searchRadius,
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
                          'search_campaigns',
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
                  isActive: _currentStatus != null && _currentStatus != 'all',
                  onTap: _showFilterScreen,
                ),
                if (_currentStatus != null && _currentStatus != 'all') ...[
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
          borderRadius: BorderRadius.circular(_SalonCampaignsUi.buttonRadius),
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

  Widget _buildErrorState(CampaignsError state) {
    // Check if it's a 403 status code
    final isAccountNotActive = state.statusCode == 403;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAccountNotActive
                  ? Icons.account_circle_outlined
                  : Icons.wifi_off,
              size: 64,
              color: isAccountNotActive ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              isAccountNotActive
                  ? AppTranslations.getString(context, 'account_not_active')
                  : 'Connection Problem',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isAccountNotActive
                  ? AppTranslations.getString(context, 'account_not_active')
                  : 'Please check your internet connection and try again.',
              style: TextStyle(
                color: isAccountNotActive ? Colors.green : Colors.orange,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            // Only show retry button if it's not a 403 error
            if (!isAccountNotActive) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<CampaignsBloc>().add(RefreshCampaigns(
                        status: _currentStatus == 'all' ? null : _currentStatus,
                        limit: 10,
                      ));
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
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Text(
        'Initializing...',
        style: TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCampaignsListSliver({
    required List<Map<String, dynamic>> filteredCampaigns,
    required int totalCampaigns,
    required int totalClicks,
    required bool isLoadingMore,
  }) {
    final ui = SalonUiTheme.of(context);

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildCarousel(
            totalCampaigns: totalCampaigns,
            totalClicks: totalClicks,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppTranslations.getString(context, 'campaigns'),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...filteredCampaigns.asMap().entries.map((entry) {
          final index = entry.key;
          final campaign = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: index < filteredCampaigns.length - 1 ? 12 : 0,
            ),
            child: _buildCampaignCard(campaign),
          );
        }),
        if (isLoadingMore) ...[
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: ui.textPrimary),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildCarousel({
    required int totalCampaigns,
    required int totalClicks,
  }) {
    final ui = SalonUiTheme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 98,
          child: PageView(
            controller: _carouselController,
            onPageChanged: (value) => setState(() => _carouselIndex = value),
            children: [
              _buildQrTipCard(),
              _buildStatsCards(
                totalCampaigns: totalCampaigns,
                totalClicks: totalClicks,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = _carouselIndex == index;
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? ui.textPrimary : ui.textMuted,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQrTipCard() {
    final ui = SalonUiTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.bannerFill,
        borderRadius: BorderRadius.circular(_SalonCampaignsUi.cardRadius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ui.sheetOverlayButton,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.scanLine,
              color: ui.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppTranslations.getString(
                      context, 'scan_reservations_qr_title'),
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  AppTranslations.getString(
                      context, 'scan_reservations_qr_subtitle'),
                  style: TextStyle(
                    color: ui.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards({
    required int totalCampaigns,
    required int totalClicks,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: totalCampaigns.toString(),
            title: AppTranslations.getString(context, 'total_campaigns'),
            icon: LucideIcons.ticket,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: _formatInt(totalClicks),
            title: AppTranslations.getString(context, 'total_clicks'),
            icon: LucideIcons.mousePointerClick,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String title,
    required IconData icon,
  }) {
    final ui = SalonUiTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.bannerFill,
        borderRadius: BorderRadius.circular(_SalonCampaignsUi.cardRadius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(icon, color: ui.textPrimary, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final ui = SalonUiTheme.of(context);
    final influencer = campaign['influencer']?['profile'] ?? {};
    final pseudo = influencer['pseudo'] ?? 'Unknown';
    final status = campaign['status'] ?? 'Unknown';
    final initiator = campaign['initiator'] ?? 'salon';
    final clicks = campaign['clicks'];
    final promotion = campaign['promotion'] ?? 0;
    final promotionType = campaign['promotionType'] ?? 'percentage';
    final profilePicture = influencer['profilePicture'];

    final String promotionText = promotionType == 'percentage'
        ? '$promotion%'
        : '$promotion€';

    final clicksValue = clicks is int
        ? clicks
        : int.tryParse(clicks?.toString() ?? '');
    final clicksLabel = clicksValue == null || clicksValue <= 0
        ? '--- Clicks'
        : '${_formatInt(clicksValue)} Clicks';

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider<CampaignsBloc>(
              create: (context) => CampaignsBloc(),
              child: CampaignDetailsScreen(campaign: campaign),
            ),
          ),
        );
        if (mounted) {
          context.read<CampaignsBloc>().add(
                RefreshCampaigns(
                  page: 1,
                  limit: 10,
                  status: _currentStatus == 'all' ? null : _currentStatus,
                ),
              );
        }
      },
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: ui.cardAlt,
          borderRadius: BorderRadius.circular(_SalonCampaignsUi.cardRadius),
          border: Border.all(
            color: ui.cardBorder,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: _SalonCampaignsUi.imageWidth,
              height: double.infinity,
              child: profilePicture != null &&
                      profilePicture.toString().isNotEmpty
                  ? Image.network(
                      profilePicture.toString(),
                      fit: BoxFit.cover,
                      width: _SalonCampaignsUi.imageWidth,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _campaignAvatarPlaceholder();
                      },
                    )
                  : _campaignAvatarPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _getStatusTranslation(
                              status,
                              initiator: initiator,
                            ),
                            style: TextStyle(
                              color: ui.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _statusIcon(status),
                          size: 14,
                          color: ui.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$pseudo',
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _pill(label: promotionText, ui: ui),
                        const SizedBox(width: 8),
                        Flexible(child: _pill(label: clicksLabel, ui: ui)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase().trim()) {
      case 'in progress':
      case 'on_going':
        return LucideIcons.circleDotDashed;
      case 'finished':
        return LucideIcons.checkCircle;
      case 'rejected':
        return LucideIcons.xCircle;
      case 'pending':
        return LucideIcons.userSquare;
      default:
        return LucideIcons.circleDotDashed;
    }
  }

  Widget _campaignAvatarPlaceholder() {
    return const ColoredBox(
      color: Color(0xFF2C2C2E),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }

  Widget _pill({required String label, required SalonUiTheme ui}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ui.bannerFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ui.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.1,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatInt(dynamic value) {
    final intValue = value is int ? value : int.tryParse(value.toString()) ?? 0;
    final raw = intValue.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buf.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _getStatusTranslation(String status, {String? initiator}) {
    switch (status.toLowerCase()) {
      case 'pending':
        // Check initiator to show appropriate waiting message
        if (initiator != null) {
          if (initiator.toLowerCase() == 'salon') {
            return AppTranslations.getString(context, 'waiting_for_influencer');
          } else if (initiator.toLowerCase() == 'influencer') {
            return AppTranslations.getString(context, 'waiting_for_you');
          }
        }
        return AppTranslations.getString(context, 'pending');
      case 'in progress':
      case 'on_going':
        return AppTranslations.getString(context, 'on_going');
      case 'finished':
        return AppTranslations.getString(context, 'finished');
      case 'rejected':
        return AppTranslations.getString(context, 'rejected');
      default:
        return status;
    }
  }

  Widget _buildNoCampaignsState() {
    final ui = SalonUiTheme.of(context);
    final hasActiveFilter =
        (_currentStatus != null && _currentStatus != 'all') ||
            _currentSearch.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ui.bannerFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ui.cardBorder,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              hasActiveFilter ? LucideIcons.searchX : LucideIcons.ticket,
              color: ui.textPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.getString(
              context,
              hasActiveFilter ? 'no_campaigns_found' : 'no_campaigns_yet',
            ),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            AppTranslations.getString(
              context,
              hasActiveFilter
                  ? 'no_campaigns_for_filters'
                  : 'go_to_influencers_message',
            ),
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (hasActiveFilter)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ui.primaryButtonBg,
                  foregroundColor: ui.primaryButtonFg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  AppTranslations.getString(context, 'clear_filters'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _goToInfluencers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ui.primaryButtonBg,
                  foregroundColor: ui.primaryButtonFg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppTranslations.getString(context, 'go_to_influencers'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.users, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerSliver() {
    final ui = SalonUiTheme.of(context);

    return SliverList(
      delegate: SliverChildListDelegate([
        // Shimmer summary cards
        Shimmer.fromColors(
          baseColor: ui.isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: ui.isDark ? Colors.grey[600]! : Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildShimmerSummaryCard(ui),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShimmerSummaryCard(ui),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Shimmer campaign cards
        ...List.generate(5, (index) {
          return Shimmer.fromColors(
            baseColor: ui.isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: ui.isDark ? Colors.grey[600]! : Colors.grey[100]!,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: index < 4 ? 12 : 16,
              ),
              child: _buildShimmerCard(ui),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildShimmerSummaryCard(SalonUiTheme ui) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.bannerFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 20,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 14,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(SalonUiTheme ui) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.transparentBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ui.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 16,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Influencer row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Promotion and Clicks row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 20,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
