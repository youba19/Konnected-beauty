import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
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

  // Filter state
  int? _currentMinRating;
  int? _currentMaxRating;
  String? _currentZone;

  @override
  void initState() {
    super.initState();

    // Load influencers on screen initialization
    context.read<InfluencersBloc>().add(LoadInfluencers());

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
        if (value.isEmpty) {
          // If search is empty, load all influencers
          context.read<InfluencersBloc>().add(LoadInfluencers());
        } else {
          // Search influencers with current filters
          final currentState = context.read<InfluencersBloc>().state;
          if (currentState is InfluencersLoaded) {
            context.read<InfluencersBloc>().add(SearchInfluencers(
                  search: value,
                  zone: currentState.currentZone,
                  sortOrder: currentState.currentSortOrder,
                ));
          } else {
            context
                .read<InfluencersBloc>()
                .add(SearchInfluencers(search: value));
          }
        }
      }
    });
  }

  void _onScrollChanged() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more influencers when near the bottom
      final currentState = context.read<InfluencersBloc>().state;
      if (currentState is InfluencersLoaded && currentState.hasMoreData) {
        context.read<InfluencersBloc>().add(LoadMoreInfluencers(
              page: currentState.currentPage + 1,
              search: currentState.currentSearch,
              zone: currentState.currentZone,
              sortOrder: currentState.currentSortOrder,
            ));
      }
    }
  }

  void _showFilterScreen() {
    final currentState = context.read<InfluencersBloc>().state;
    int? currentMinRating;
    int? currentMaxRating;
    String? currentZone;

    if (currentState is InfluencersLoaded) {
      // Extract current filter values from state if available
      currentZone = currentState.currentZone;
      // Note: Rating filters are not yet implemented in the API, so we'll use defaults
      currentMinRating = 1;
      currentMaxRating = 5;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InfluencersFilterScreen(
        currentMinRating: currentMinRating,
        currentMaxRating: currentMaxRating,
        currentZone: currentZone,
        onFilterApplied: (minRating, maxRating, zone) {
          // Apply the filter by loading influencers with new parameters
          context.read<InfluencersBloc>().add(LoadInfluencers(
                zone: zone,
                sortOrder: 'DESC',
              ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  // Header Section
                  _buildHeader(),

                  // Main Content
                  Expanded(
                    child: BlocBuilder<InfluencersBloc, InfluencersState>(
                      builder: (context, state) {
                        if (state is InfluencersLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentColor,
                            ),
                          );
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

  Widget _buildHeader() {
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
                  color: AppTheme.transparentBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textPrimaryColor,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.filter_list,
                    color: AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                  onPressed: _showFilterScreen,
                ),
              ),
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InfluencerDetailsScreen(
              influencer: influencer,
            ),
          ),
        );
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

                      // Zone
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
}
