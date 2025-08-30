import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'campaign_details_screen.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  // Mock data for demonstration
  final List<Map<String, dynamic>> mockCampaigns = [
    {
      'id': '1',
      'date': '14/07/2025',
      'status': 'Finished',
      'influencer': {'profilePicture': null, 'pseudo': 'lastradamir'},
      'clicks': 12039,
      'promotionType': 'Pourcentage',
      'promotionValue': '20%',
      'completedOrders': 350,
      'total': '12,000 EUR',
    },
    {
      'id': '2',
      'date': '14/07/2025',
      'status': 'Waiting for influencer',
      'influencer': {'profilePicture': null, 'pseudo': 'farmlandpie'},
      'clicks': 639,
      'promotionType': 'Fixed Amount',
      'promotionValue': '50 EUR',
      'completedOrders': 45,
      'total': '2,250 EUR',
    },
    {
      'id': '3',
      'date': '15/05/2025',
      'status': 'On',
      'influencer': {'profilePicture': null, 'pseudo': 'lastradamir'},
      'clicks': 12039,
      'promotionType': 'Pourcentage',
      'promotionValue': '15%',
      'completedOrders': 280,
      'total': '8,400 EUR',
    },
  ];

  final bool hasCampaigns = true; // change to false to test empty state

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => _onSearchChanged(searchController.text));
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) print('Searching for: $value');
    });
  }

  void _showFilterScreen() {
    TopNotificationService.showInfo(
      context: context,
      message: AppTranslations.getString(context, 'filter_coming_soon'),
    );
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
                    child: hasCampaigns
                        ? _buildCampaignsList()
                        : _buildNoCampaignsState(),
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

  Widget _buildCampaignsList() {
    int totalClicks = mockCampaigns.fold<int>(
        0, (sum, campaign) => sum + (campaign['clicks'] as int));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.confirmation_num,
                  value: '${mockCampaigns.length}',
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: mockCampaigns.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCampaignCard(mockCampaigns[index]),
            ),
          ),
        )
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
          Text(
            title,
            style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CampaignDetailsScreen(campaign: campaign),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.transparentBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white, // 🔹 Change to your desired border color
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(campaign['date'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  campaign['status'],
                  style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                )
              ],
            ),
            const SizedBox(height: 12),
            // Influencer row
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Text('@${campaign['influencer']['pseudo']}',
                    style: const TextStyle(
                        color: AppTheme.textPrimaryColor, fontSize: 15))
              ],
            ),
            const SizedBox(height: 12),
            // Clicks
            Text('${campaign['clicks']} Clicks',
                style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
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
}
