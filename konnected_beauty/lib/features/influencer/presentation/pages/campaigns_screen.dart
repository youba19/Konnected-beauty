import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/influencer_campaigns/influencer_campaigns_bloc.dart';
import '../../../../core/bloc/influencer_campaigns/influencer_campaigns_event.dart';
import '../../../../core/bloc/influencer_campaigns/influencer_campaigns_state.dart';
import '../../../../core/bloc/delete_campaign/delete_campaign_bloc.dart';
import 'campaign_details_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  Timer? _searchDebounceTimer;
  String _selectedFilter =
      'waiting_for_you'; // Default to 'waiting_for_you' which maps to 'pending' status

  @override
  void initState() {
    super.initState();
    // Load all campaigns for client-side filtering
    context
        .read<InfluencerCampaignsBloc>()
        .add(LoadInfluencerCampaigns(status: null));
    _scrollController.addListener(_onScroll);
    _searchController
        .addListener(() => _onSearchChanged(_searchController.text));
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final currentState = context.read<InfluencerCampaignsBloc>().state;
      if (currentState is InfluencerCampaignsLoaded &&
          currentState.hasMore &&
          !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        context.read<InfluencerCampaignsBloc>().add(LoadMoreInfluencerCampaigns(
              status: null,
            ));
      }
    }
  }

  void _onSearchChanged(String value) {
    // Trigger immediate UI update for search filtering
    setState(() {});

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchController.text == value) {
        // Load all campaigns for client-side filtering
        context
            .read<InfluencerCampaignsBloc>()
            .add(LoadInfluencerCampaigns(status: null));
      }
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    // For initiator-based filtering, we need to load all campaigns and filter client-side
    // since the API doesn't support initiator filtering
    context
        .read<InfluencerCampaignsBloc>()
        .add(LoadInfluencerCampaigns(status: null)); // Load all campaigns
  }

  List<Map<String, dynamic>> _filterCampaigns(
      List<Map<String, dynamic>> campaigns) {
    return campaigns.where((campaign) {
      final initiator = campaign['initiator'] ?? 'salon';
      final status = campaign['status'] ?? 'pending';
      final searchText = _searchController.text.toLowerCase().trim();

      // Apply search filter first
      bool matchesSearch = true;
      if (searchText.isNotEmpty) {
        final salonName =
            (campaign['salonName'] ?? '').toString().toLowerCase();
        final message =
            (campaign['invitationMessage'] ?? '').toString().toLowerCase();
        final domain = (campaign['salonDomain'] ?? '').toString().toLowerCase();

        matchesSearch = salonName.contains(searchText) ||
            message.contains(searchText) ||
            domain.contains(searchText);
      }

      // Apply status/initiator filter
      bool matchesFilter = true;
      switch (_selectedFilter) {
        case 'waiting_for_you':
          // Show campaigns where salon invited influencer and status is pending
          matchesFilter = initiator == 'salon' && status == 'pending';
          break;
        case 'on_going':
          // Show campaigns with in progress status
          matchesFilter = status == 'in progress';
          break;
        case 'wait':
          // Show campaigns where influencer invited salon and status is pending
          matchesFilter = initiator == 'influencer' && status == 'pending';
          break;
        case 'refused':
          // Show campaigns with refused status
          matchesFilter = status == 'rejected';
          break;
        case 'finished':
          // Show campaigns with finished status
          matchesFilter = status == 'finished';
          break;
        case 'deleted':
          // Show campaigns with deleted status
          matchesFilter = status == 'deleted';
          break;
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep black background as in image
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: BlocListener<InfluencerCampaignsBloc,
                      InfluencerCampaignsState>(
                    listener: (context, state) {
                      if (state is InfluencerCampaignsLoaded) {
                        _isLoadingMore = false;
                      } else if (state is InfluencerCampaignsError) {
                        _isLoadingMore = false;
                      }
                    },
                    child: BlocBuilder<InfluencerCampaignsBloc,
                        InfluencerCampaignsState>(
                      builder: (context, state) {
                        if (state is InfluencerCampaignsLoading) {
                          return _buildLoadingState();
                        } else if (state is InfluencerCampaignsError) {
                          return _buildErrorState(state);
                        } else if (state is InfluencerCampaignsLoaded) {
                          final filteredCampaigns = _filterCampaigns(
                              state.campaigns.cast<Map<String, dynamic>>());
                          if (filteredCampaigns.isEmpty) {
                            return _buildNoCampaignsState();
                          } else {
                            return _buildCampaignsList(
                                state, filteredCampaigns);
                          }
                        } else if (state is InfluencerCampaignsLoadingMore) {
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Search Bar with padding
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                AppTranslations.getString(context, 'campaigns'),
                style: const TextStyle(
                  color: Colors.white, // White text
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme
                      .transparentBackground, // Dark grey background as in image
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.borderColor), // Light grey border
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white), // White text
                  decoration: InputDecoration(
                    hintText: AppTranslations.getString(
                        context, 'search_placeholder'),
                    hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF)), // Light grey hint
                    suffixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF9CA3AF), // Light grey icon
                    ),
                    border: InputBorder.none,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Tabs without left/right padding
        _buildFilterTabs(),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {
        'key': 'waiting_for_you',
        'label': AppTranslations.getString(context, 'waiting_for_you'),
        'icon': LucideIcons.userSquare
      },
      {
        'key': 'on_going',
        'label': AppTranslations.getString(context, 'on_going'),
        'icon': LucideIcons.circleDotDashed
      },
      {
        'key': 'wait',
        'label': AppTranslations.getString(context, 'Waiting_for_Saloon'),
        'icon': LucideIcons.store
      },
      {
        'key': 'refused',
        'label': AppTranslations.getString(context, 'refused'),
        'icon': LucideIcons.xCircle
      },
      {
        'key': 'finished',
        'label': AppTranslations.getString(context, 'finished'),
        'icon': LucideIcons.checkCircle
      },
      {
        'key': 'canceled',
        'label': AppTranslations.getString(context, 'deleted'),
        'icon': LucideIcons.trash2
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 8.0), // Only top and bottom padding
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0), // Add horizontal padding to ListView
          itemCount: filters.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == filter['key'];

            return GestureDetector(
              onTap: () => _onFilterChanged(filter['key'] as String),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.greenColor // Green for selected
                      : const Color(0xFF2A2A2A), // Dark grey for unselected
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF404040)), // Light grey border
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.secondaryColor // Green for selected
                            : AppTheme
                                .textPrimaryColor, // White text for all states
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Show icon only when NOT selected
                    if (!isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        filter['icon'] as IconData, // Each tab has its own icon
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCampaignsList(InfluencerCampaignsLoaded state,
      List<Map<String, dynamic>> filteredCampaigns) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InfluencerCampaignsBloc>().add(RefreshInfluencerCampaigns(
              status: null,
            ));
      },
      child: _buildGroupedCampaignsList(filteredCampaigns),
    );
  }

  Widget _buildGroupedCampaignsList(List<Map<String, dynamic>> campaigns) {
    // Group campaigns by date
    final Map<String, List<Map<String, dynamic>>> groupedCampaigns = {};

    for (final campaign in campaigns) {
      final createdAt = campaign['createdAt'] ?? '';
      final groupKey = _getDateGroupKey(createdAt);

      if (!groupedCampaigns.containsKey(groupKey)) {
        groupedCampaigns[groupKey] = [];
      }
      groupedCampaigns[groupKey]!.add(campaign);
    }

    // Sort groups chronologically (newest first)
    final sortedGroups = groupedCampaigns.keys.toList()
      ..sort((a, b) {
        // Get the actual date for each group key
        final dateA = _getDateFromGroupKey(a);
        final dateB = _getDateFromGroupKey(b);

        // Sort by date in descending order (newest first)
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: sortedGroups.length,
      itemBuilder: (context, index) {
        final groupKey = sortedGroups[index];
        final campaigns = groupedCampaigns[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                groupKey,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            // Campaigns for this date
            ...campaigns.map((campaign) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCampaignCard(campaign),
                )),
          ],
        );
      },
    );
  }

  String _getDateGroupKey(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return AppTranslations.getString(context, 'today');
      } else if (difference.inDays == 1) {
        return AppTranslations.getString(context, 'yesterday');
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown Date';
    }
  }

  DateTime _getDateFromGroupKey(String groupKey) {
    try {
      final now = DateTime.now();

      if (groupKey == AppTranslations.getString(context, 'today')) {
        return now;
      } else if (groupKey == AppTranslations.getString(context, 'yesterday')) {
        return now.subtract(const Duration(days: 1));
      } else if (groupKey == 'Unknown Date') {
        return DateTime(1970); // Very old date for unknown dates
      } else {
        // Parse specific date format (DD/MM/YYYY)
        final parts = groupKey.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
        return DateTime(1970); // Fallback for invalid dates
      }
    } catch (e) {
      return DateTime(1970); // Fallback for any parsing errors
    }
  }

  Widget _buildCampaignsListWithLoading(InfluencerCampaignsLoadingMore state,
      List<Map<String, dynamic>> filteredCampaigns) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InfluencerCampaignsBloc>().add(RefreshInfluencerCampaigns(
              status: null,
            ));
      },
      child: _buildGroupedCampaignsListWithLoading(state, filteredCampaigns),
    );
  }

  Widget _buildGroupedCampaignsListWithLoading(
      InfluencerCampaignsLoadingMore state,
      List<Map<String, dynamic>> campaigns) {
    // Group campaigns by date
    final Map<String, List<Map<String, dynamic>>> groupedCampaigns = {};

    for (final campaign in campaigns) {
      final createdAt = campaign['createdAt'] ?? '';
      final groupKey = _getDateGroupKey(createdAt);

      if (!groupedCampaigns.containsKey(groupKey)) {
        groupedCampaigns[groupKey] = [];
      }
      groupedCampaigns[groupKey]!.add(campaign);
    }

    // Sort groups chronologically (newest first)
    final sortedGroups = groupedCampaigns.keys.toList()
      ..sort((a, b) {
        // Get the actual date for each group key
        final dateA = _getDateFromGroupKey(a);
        final dateB = _getDateFromGroupKey(b);

        // Sort by date in descending order (newest first)
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: sortedGroups.length + 1,
      itemBuilder: (context, index) {
        if (index == sortedGroups.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final groupKey = sortedGroups[index];
        final campaigns = groupedCampaigns[groupKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                groupKey,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Campaigns for this date
            ...campaigns.map((campaign) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCampaignCard(campaign),
                )),
          ],
        );
      },
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final salonName = campaign['salonName'] ??
        AppTranslations.getString(context, 'saloon_name');
    final createdAt = campaign['createdAt'] ?? '';
    final message = campaign['invitationMessage'] ?? '';
    final promotion = campaign['promotion'] ?? 0;
    final promotionType = campaign['promotionType'] ?? 'percentage';

    // Format date and time exactly like in the image
    final dateTime = _formatDateTime(createdAt);

    // Format promotion exactly like in the image
    final promotionText = _formatPromotion(promotion, promotionType);

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => DeleteCampaignBloc(),
              child: CampaignDetailsScreen(
                campaign: campaign,
                onCampaignDeleted: () {
                  // Refresh campaigns when a campaign is deleted
                  context
                      .read<InfluencerCampaignsBloc>()
                      .add(LoadInfluencerCampaigns(status: null));
                },
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), // Dark grey background as in image
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor), // Light grey border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salon name
            Text(
              salonName,
              style: const TextStyle(
                color: Colors.white, // White text
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Date and promotion row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date and time
                Text(
                  dateTime,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF), // Light grey text
                    fontSize: 14,
                  ),
                ),
                // Promotion (end of row)
                Text(
                  promotionText,
                  style: const TextStyle(
                    color: Colors.white, // White text
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Message
            if (message.isNotEmpty) ...[
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF), // Light grey text
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.length > 50) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    // TODO: Show full message
                  },
                  child: Text(
                    AppTranslations.getString(context, 'see_more'),
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF), // Light grey text
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ] else ...[
              Text(
                AppTranslations.getString(context, 'no_message'),
                style: const TextStyle(
                  color: Color(0xFF9CA3AF), // Light grey text
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPromotion(int promotion, String promotionType) {
    if (promotionType == 'percentage') {
      return '$promotion%';
    } else {
      return 'EUR $promotion';
    }
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          const CircularProgressIndicator(
            color: AppTheme.accentColor,
            strokeWidth: 2,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildErrorState(InfluencerCampaignsError state) {
    // Check if it's a 403 status code
    final isAccountNotActive = state.statusCode == 403;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Icon(
            isAccountNotActive
                ? Icons.account_circle_outlined
                : Icons.error_outline,
            color: AppTheme.greenColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isAccountNotActive
                ? AppTranslations.getString(context, 'account_not_active')
                : AppTranslations.getString(context, 'error_loading_campaigns'),
            style: AppTheme.applyPoppins(const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isAccountNotActive
                ? AppTranslations.getString(context, 'account_not_active')
                : state.message,
            style: AppTheme.applyPoppins(TextStyle(
              color: Colors.green,
              fontSize: 14,
            )),
            textAlign: TextAlign.center,
          ),
          // Only show retry button if it's not a 403 error
          if (!isAccountNotActive) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context
                    .read<InfluencerCampaignsBloc>()
                    .add(LoadInfluencerCampaigns(status: _selectedFilter));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.greenColor,
                foregroundColor: AppTheme.textPrimaryColor,
              ),
              child: Text(
                AppTranslations.getString(context, 'retry'),
                style: AppTheme.applyPoppins(const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNoCampaignsState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.campaign_outlined,
            color: AppTheme.textSecondaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.getString(context, 'no_campaigns_found'),
            style: AppTheme.applyPoppins(const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'campaigns_will_appear_here'),
            style: AppTheme.applyPoppins(const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            )),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          const CircularProgressIndicator(
            color: AppTheme.accentColor,
            strokeWidth: 2,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
