import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    // Load initial campaigns with pending status filter
    _currentStatus = 'pending';
    print('🚀 === INITIAL CAMPAIGNS LOAD ===');
    context.read<CampaignsBloc>().add(LoadCampaigns(
          status: _currentStatus,
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

    // Set new timer for debounced search (same as influencers)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('🔍 === SEARCH CHANGED ===');
        print('🔍 Search Value: "$value"');

        if (value.isEmpty) {
          // Reset to initial load when search is cleared (same as influencers)
          context.read<CampaignsBloc>().add(LoadCampaigns(
                page: 1,
                limit: 10,
                search: null,
                status: _currentStatus,
              ));
        } else {
          // Use LoadCampaigns with search parameter (same as influencers)
          context.read<CampaignsBloc>().add(LoadCampaigns(
                page: 1,
                limit: 10,
                search: value,
                status: _currentStatus,
              ));
        }
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
                status: currentState.currentStatus ?? _currentStatus,
              ));
        }
      }
    }
  }

  void _showFilterScreen() {
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

            // Status Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip('pending', 'Pending'),
                _buildStatusChip('in progress', 'In Progress'),
                _buildStatusChip('rejected', 'Rejected'),
                _buildStatusChip('canceled', 'Canceled'),
                _buildStatusChip('finished', 'Finished'),
                _buildStatusChip('all', 'All'),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearFilters,
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
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _currentStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.textPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.textPrimaryColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.secondaryColor
                : AppTheme.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentStatus = 'pending';
    });
    Navigator.pop(context);
    _applyFilters();
  }

  void _applyFilters() {
    print('🔍 === APPLYING FILTERS ===');
    print('🔍 Status: $_currentStatus');

    context.read<CampaignsBloc>().add(LoadCampaigns(
          status: _currentStatus == 'all' ? null : _currentStatus,
          limit: 10,
        ));
  }

  void _goToInfluencers() {
    print('Navigate to influencers screen');
  }

  @override
  Widget build(BuildContext context) {
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
                            // Don't show loading state for better UX during search
                            return _buildInitialState();
                          } else if (state is CampaignsError) {
                            return _buildErrorState(state);
                          } else if (state is CampaignsLoaded) {
                            if (state.campaigns.isEmpty) {
                              return _buildNoCampaignsState();
                            } else {
                              return _buildCampaignsList(state);
                            }
                          } else if (state is CampaignsLoadingMore) {
                            if (state.campaigns.isEmpty) {
                              return _buildNoCampaignsState();
                            } else {
                              return _buildCampaignsListWithLoading(state);
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
                  color: (_currentStatus != null && _currentStatus != 'pending')
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
                    color:
                        (_currentStatus != null && _currentStatus != 'pending')
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading campaigns',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CampaignsBloc>().add(RefreshCampaigns(
                      status: _currentStatus,
                      limit: 10, // Normal page size like influencers
                    ));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
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

  Widget _buildCampaignsList(CampaignsLoaded state) {
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
                    status: _currentStatus,
                    limit: 10, // Normal page size like influencers
                  ));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.campaigns.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.campaigns.length) {
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
                          'All campaigns loaded (${state.campaigns.length}/${state.total})',
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
                  child: _buildCampaignCard(state.campaigns[index]),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCampaignsListWithLoading(CampaignsLoadingMore state) {
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
                    status: _currentStatus,
                    limit: 10, // Normal page size like influencers
                  ));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.campaigns.length + 1, // +1 for loading indicator
              itemBuilder: (context, index) {
                if (index == state.campaigns.length) {
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
                final campaign = state.campaigns[index];
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
      promotionText = '$promotion EUR';
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
                  status: _currentStatus,
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
                Text(
                  formattedDate,
                  style: const TextStyle(
                      color: AppTheme.textPrimaryColor, fontSize: 16),
                ),
                Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Show 5 shimmer items
        itemBuilder: (context, index) {
          return _buildShimmerCard();
        },
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with avatar and text
          Row(
            children: [
              // Shimmer avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Shimmer text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
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
              ),
              // Shimmer status badge
              Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Shimmer content rows
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          // Shimmer stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 12,
                width: 60,
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
    );
  }
}
