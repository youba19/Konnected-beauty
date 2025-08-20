import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'influencer_details_screen.dart';

class InfluencersScreen extends StatefulWidget {
  const InfluencersScreen({super.key});

  @override
  State<InfluencersScreen> createState() => _InfluencersScreenState();
}

class _InfluencersScreenState extends State<InfluencersScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock data for influencers - replace with real API data later
  final List<Map<String, dynamic>> influencers = [
    {
      'id': '1',
      'username': 'lastradamir',
      'rating': 5,
      'zone': 'Zone',
      'phone': '+33 6 12 34 56 78',
      'email': 'lastradamir@example.com',
      'description':
          'Vous avez les cheveux bouclés s\'ils forment des spirales plus ou moins larges...',
      'profileImage':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    },
    {
      'id': '2',
      'username': 'antpiebass',
      'rating': 4,
      'zone': 'Zone',
      'phone': '+33 6 23 45 67 89',
      'email': 'antpiebass@example.com',
      'description':
          'Vous avez les cheveux bouclés s\'ils forment des spirales plus ou moins larges...',
      'profileImage':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
    },
    {
      'id': '3',
      'username': 'farmlandpie',
      'rating': 3,
      'zone': 'Zone',
      'description':
          'Vous avez les cheveux bouclés s\'ils forment des spirales plus ou moins larges...',
      'profileImage':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    },
    {
      'id': '4',
      'username': 'volleyball',
      'rating': 5,
      'zone': 'Zone',
      'description':
          'Vous avez les cheveux bouclés s\'ils forment des spirales plus ou moins larges...',
      'profileImage':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    },
    {
      'id': '5',
      'username': 'beautyexpert',
      'rating': 4,
      'zone': 'Zone',
      'description':
          'Vous avez les cheveux bouclés s\'ils forment des spirales plus ou moins larges Vous avez les cheveux bouclés s\'ils forment des spirales plus ou moins larges...',
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
    },
    {
      'id': '6',
      'username': 'styleguru',
      'rating': 5,
      'zone': 'Zone',
      'description':
          'Vous avez les cheveux bouclés s\'ils forment des spirales plus ou moins larges...',
      'profileImage':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // TODO: Implement search functionality
    print('Searching for: $value');
  }

  void _showFilterScreen() {
    // TODO: Implement filter functionality
    TopNotificationService.showInfo(
      context: context,
      message: AppTranslations.getString(context, 'filter_coming_soon'),
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
                    child: _buildMainContent(),
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

  Widget _buildMainContent() {
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
                  child: Image.network(
                    influencer['profileImage'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        color: AppTheme.textSecondaryColor.withOpacity(0.3),
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.textSecondaryColor,
                          size: 20,
                        ),
                      );
                    },
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
                            '@${influencer['username']}',
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Rating
                      Row(
                        children: [
                          Text(
                            '${influencer['rating']} ',
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const Spacer(),
                          Text(
                            influencer['zone'],
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
                final text = influencer['description'] ?? '';
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
}
