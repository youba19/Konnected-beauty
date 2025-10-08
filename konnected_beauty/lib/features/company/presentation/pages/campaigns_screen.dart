import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_event.dart';
import '../../../../core/bloc/campaigns/campaigns_state.dart';
import 'campaign_details_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

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

  @override
  void initState() {
    super.initState();

    print('🎬 === CAMPAIGNS SCREEN INIT ===');
    print('🎬 Screen initialized, loading campaigns...');
    print('🎬 Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    // Add search listener with debounce (same as influencers)
    searchController.addListener(() => _onSearchChanged(searchController.text));

    // Add scroll listener for pagination (same as influencers)
    _scrollController.addListener(_onScroll);

    // Load initial campaigns with all statuses
    _currentStatus = 'all';
    print('🚀 === INITIAL CAMPAIGNS LOAD ===');
    context.read<CampaignsBloc>().add(LoadCampaigns(
          status: null, // Load all campaigns
          limit: 10, // Use normal page size like influencers
        ));
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

  void _onScroll() {
    // Check if we can load more data on any scroll movement (same logic as services)
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final currentState = context.read<CampaignsBloc>().state;

      if (currentState is CampaignsLoaded &&
          currentState.hasMore &&
          !_isLoadingMore) {
        // If we're near bottom or list is not scrollable, load more
        final isNearBottom = position.pixels >= position.maxScrollExtent - 100;
        final isNotScrollable = position.maxScrollExtent <= 0;

        if (isNearBottom || isNotScrollable) {
          _isLoadingMore = true;
          context.read<CampaignsBloc>().add(LoadMoreCampaigns(
                page: currentState.currentPage + 1,
                search: currentState.currentSearch,
                status: currentState.currentStatus ??
                    (_currentStatus == 'all' ? null : _currentStatus),
              ));
        }
      }
    }
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
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Campaigns',
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status Filter
                Text(
                  'Campaign Status',
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Status Dropdown
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.transparentBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textPrimaryColor,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currentStatus ?? 'all',
                      isExpanded: true,
                      hint: Text(
                        AppTranslations.getString(context, 'all'),
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 16,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.textPrimaryColor,
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child:
                              Text(AppTranslations.getString(context, 'all')),
                        ),
                        DropdownMenuItem<String>(
                          value: 'pending',
                          child: Text(
                              AppTranslations.getString(context, 'pending')),
                        ),
                        DropdownMenuItem<String>(
                          value: 'in progress',
                          child: Text(
                              AppTranslations.getString(context, 'on_going')),
                        ),
                        DropdownMenuItem<String>(
                          value: 'finished',
                          child: Text(
                              AppTranslations.getString(context, 'finished')),
                        ),
                        DropdownMenuItem<String>(
                          value: 'rejected',
                          child: Text(
                              AppTranslations.getString(context, 'rejected')),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        print('🔍 === DROPDOWN CHANGED ===');
                        print('🔍 New Value: "$newValue"');
                        print('🔍 Current Status Before: "$_currentStatus"');
                        if (newValue != null) {
                          setModalState(() {
                            _currentStatus = newValue;
                          });
                          print('🔍 Current Status After: "$_currentStatus"');
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setModalState(() {
                            _currentStatus = 'all';
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppTheme.textSecondaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: AppTheme.textSecondaryColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.textPrimaryColor,
                          foregroundColor: AppTheme.secondaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _currentStatus = 'all';
    });
    Navigator.pop(context);
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
  }

  List<Map<String, dynamic>> _filterCampaigns(
      List<Map<String, dynamic>> campaigns) {
    if (_currentSearch.isEmpty) {
      return campaigns;
    }

    final searchLower = _currentSearch.toLowerCase();
    return campaigns.where((campaign) {
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
        return Scaffold(
          backgroundColor: const Color(0xFF1F1E1E),
          body: Container(
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
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: BlocListener<CampaignsBloc, CampaignsState>(
                      listener: (context, state) {
                        if (state is CampaignsLoaded) {
                          // Reset loading flag when load more completes
                          _isLoadingMore = false;
                        } else if (state is CampaignsError) {
                          // Reset loading flag on error
                          _isLoadingMore = false;
                        }
                      },
                      child: BlocBuilder<CampaignsBloc, CampaignsState>(
                        builder: (context, state) {
                          if (state is CampaignsLoading) {
                            // Show shimmer loading for initial load
                            return _buildShimmerList();
                          } else if (state is CampaignsError) {
                            return _buildErrorState(state);
                          } else if (state is CampaignsLoaded) {
                            final filteredCampaigns = _filterCampaigns(
                                state.campaigns.cast<Map<String, dynamic>>());
                            if (filteredCampaigns.isEmpty) {
                              return _buildNoCampaignsState();
                            } else {
                              return _buildCampaignsList(
                                  state, filteredCampaigns);
                            }
                          } else if (state is CampaignsLoadingMore) {
                            final filteredCampaigns = _filterCampaigns(
                                state.campaigns.cast<Map<String, dynamic>>());
                            if (filteredCampaigns.isEmpty) {
                              return _buildNoCampaignsState();
                            } else {
                              return _buildCampaignsListWithLoading(
                                  state, filteredCampaigns);
                            }
                          } else {
                            return _buildInitialState();
                          }
                        },
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getString(context, 'campaigns'),
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
                  color: (_currentStatus != null && _currentStatus != 'all')
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
                    color: (_currentStatus != null && _currentStatus != 'all')
                        ? AppTheme.secondaryColor
                        : AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  onPressed: _showFilterScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test Button (temporary for debugging)
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return _buildShimmerList();
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
              color: isAccountNotActive ? Colors.red : Colors.orange,
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
                color: isAccountNotActive ? Colors.red : Colors.orange,
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

  Widget _buildCampaignsList(
      CampaignsLoaded state, List<Map<String, dynamic>> filteredCampaigns) {
    int totalClicks = state.campaigns.fold<int>(
        0, (sum, campaign) => sum + (campaign['clicks'] as int? ?? 0));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: LucideIcons.ticket,
                  value: '${state.total}',
                  title: AppTranslations.getString(context, 'total_campaigns'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  icon: LucideIcons.mousePointerClick,
                  value: totalClicks.toString(),
                  title: AppTranslations.getString(context, 'total_clicks'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<CampaignsBloc>().add(RefreshCampaigns(
                    status: _currentStatus == 'all' ? null : _currentStatus,
                    limit: 10, // Normal page size like influencers
                  ));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredCampaigns.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredCampaigns.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (state.hasMore) ...[
                          // Loading indicator removed for better UX
                        ] else ...[
                          Text(
                            'No more campaigns available',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Pagination disabled - all campaigns loaded at once
                        Text(
                          'All campaigns loaded (${filteredCampaigns.length}/${state.total})',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCampaignCard(filteredCampaigns[index]),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCampaignsListWithLoading(CampaignsLoadingMore state,
      List<Map<String, dynamic>> filteredCampaigns) {
    int totalClicks = state.campaigns.fold<int>(
        0, (sum, campaign) => sum + (campaign['clicks'] as int? ?? 0));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.confirmation_num,
                  value: '${state.total}',
                  title: AppTranslations.getString(context, 'total_campaigns'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  icon: Icons.trending_up,
                  value: totalClicks.toString(),
                  title: AppTranslations.getString(context, 'total_clicks'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<CampaignsBloc>().add(RefreshCampaigns(
                    status: _currentStatus == 'all' ? null : _currentStatus,
                    limit: 10, // Normal page size like influencers
                  ));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  filteredCampaigns.length + 1, // +1 for loading indicator
              itemBuilder: (context, index) {
                if (index == filteredCampaigns.length) {
                  // Show loading indicator at the bottom
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  );
                }
                final campaign = filteredCampaigns[index];
                return _buildCampaignCard(campaign);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text left
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: AppTheme.secondaryColor, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final influencer = campaign['influencer']?['profile'] ?? {};
    final pseudo = influencer['pseudo'] ?? 'Unknown';
    final status = campaign['status'] ?? 'Unknown';
    final initiator = campaign['initiator'] ?? 'salon'; // Get initiator
    final clicks = campaign['clicks'] ?? 0;
    final promotion = campaign['promotion'] ?? 0;
    final promotionType = campaign['promotionType'] ?? 'percentage';
    final createdAt = campaign['createdAt'] ?? '';
    final profilePicture = influencer['profilePicture'];

    // Format date
    String formattedDate = 'Unknown';
    try {
      final date = DateTime.parse(createdAt);
      formattedDate = '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('Error parsing date: $e');
    }

    // Format promotion value
    String promotionText = '';
    if (promotionType == 'percentage') {
      promotionText = '$promotion%';
    } else {
      promotionText = '$promotion€ ';
    }

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
        // Refresh campaigns when returning from details screen
        if (mounted) {
          context.read<CampaignsBloc>().add(
                RefreshCampaigns(
                  page: 1,
                  limit: 10, // Normal page size like influencers
                  status: _currentStatus == 'all' ? null : _currentStatus,
                ),
              );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.transparentBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                        color: AppTheme.textPrimaryColor, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getStatusTranslation(status, initiator: initiator)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Influencer row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  backgroundImage: profilePicture != null
                      ? NetworkImage(profilePicture)
                      : null,
                  child: profilePicture == null
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '@$pseudo',
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Promotion and Clicks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$clicks Clicks',
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$promotionText Promotion',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
      case 'on':
        return Colors.green;
      case 'finished':
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNoCampaignsState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.campaign, color: Colors.white, size: 60),
          const SizedBox(height: 20),
          const Text("There are no campaign yet!",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Go to Influencer and invite them for campaigns",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _goToInfluencers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text("Go to Influencer",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(width: 8),
                Icon(Icons.people, size: 20)
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Column(
        children: [
          // Shimmer summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildShimmerSummaryCard(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShimmerSummaryCard(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Shimmer campaign cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5, // Show 5 shimmer items
              itemBuilder: (context, index) {
                return _buildShimmerCard();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.transparentBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
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
