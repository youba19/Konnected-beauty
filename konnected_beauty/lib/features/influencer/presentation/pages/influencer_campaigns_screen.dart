import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/influencer_campaigns/influencer_campaign_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'influencer_campaign_detail_screen.dart';

class InfluencerCampaignsScreen extends StatefulWidget {
  const InfluencerCampaignsScreen({super.key});

  @override
  State<InfluencerCampaignsScreen> createState() =>
      _InfluencerCampaignsScreenState();
}

class _InfluencerCampaignsScreenState extends State<InfluencerCampaignsScreen> {
  @override
  void initState() {
    super.initState();
    // Load campaigns when screen initializes
    context.read<InfluencerCampaignBloc>().add(LoadInfluencerCampaigns());
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return BlocListener<InfluencerCampaignBloc, InfluencerCampaignState>(
      listener: (context, state) {
        if (state is CampaignActionSuccess) {
          TopNotificationService.showSuccess(
            context: context,
            message: state.message,
          );
        } else if (state is InfluencerCampaignError) {
          TopNotificationService.showError(
            context: context,
            message: state.message,
          );
        }
      },
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          return Scaffold(
            backgroundColor: AppTheme.getScaffoldBackground(Theme.of(context).brightness),
            body: Stack(
              children: [
                // TOP GREEN GLOW (same as influencer home screen)
                Positioned(
                  top: -80,
                  left: -60,
                  right: -60,
                  child: IgnorePointer(
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        // soft radial green halo like the screenshot
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.6),
                          radius: 0.6,
                          colors: [
                            AppTheme.greenPrimary.withOpacity(0.3),
                            Theme.of(context).brightness == Brightness.dark ? AppTheme.transparentBackground : AppTheme.textWhite54,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // CONTENT
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            AppTranslations.getString(context, 'campaigns'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<InfluencerCampaignBloc, InfluencerCampaignState>(
      builder: (context, state) {
        if (state is InfluencerCampaignLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        } else if (state is InfluencerCampaignError) {
          return _buildErrorState(state);
        } else if (state is InfluencerCampaignLoaded ||
            state is CampaignActionSuccess) {
          final campaigns = state is InfluencerCampaignLoaded
              ? state.campaigns
              : (state as CampaignActionSuccess).campaigns;

          if (campaigns.isEmpty) {
            return _buildEmptyState();
          }

          return _buildCampaignsList(campaigns);
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildCampaignsList(List<Map<String, dynamic>> campaigns) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.getSecondaryColor(Theme.of(context).brightness),
      onRefresh: () async {
        context.read<InfluencerCampaignBloc>().add(LoadInfluencerCampaigns());
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: campaigns.length,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return _buildCampaignCard(campaign);
        },
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final status = campaign['status']?.toString().toLowerCase() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                InfluencerCampaignDetailScreen(campaign: campaign),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getSecondaryColor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.getBorderColor(Theme.of(context).brightness).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with salon name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.getString(context, 'campaign_with'),
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        campaign['saloonName'] ?? 'Salon name',
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCampaignStatusBadge(status),
              ],
            ),

            SizedBox(height: 16),

            // Date and promotion info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.getString(context, 'created_at'),
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        campaign['createdAt'] ?? '14/07/2025',
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.getString(context, 'promotion_type'),
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        campaign['promotionType'] ?? 'Pourcentage',
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    campaign['promotionValue'] ?? '20%',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Statistics row
            Row(
              children: [
                _buildStatItem(
                  AppTranslations.getString(context, 'clicks'),
                  campaign['clicks']?.toString() ?? '0',
                ),
                SizedBox(width: 20),
                _buildStatItem(
                  AppTranslations.getString(context, 'orders'),
                  campaign['completedOrders']?.toString() ?? '0',
                ),
                Spacer(),
                Text(
                  campaign['total'] ?? '0 EUR',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (status) {
      case 'waiting for you':
        backgroundColor = AppTheme.statusOrange.withOpacity(0.1);
        textColor = AppTheme.statusOrange;
        displayText = AppTranslations.getString(context, 'waiting_for_you');
        icon = Icons.person;
        break;
      case 'on going':
        backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
        textColor = AppTheme.primaryColor;
        displayText = AppTranslations.getString(context, 'on_going');
        icon = Icons.play_circle_outline;
        break;
      case 'finished':
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        displayText = AppTranslations.getString(context, 'finished');
        icon = Icons.check_circle_outline;
        break;
      default:
        backgroundColor = AppTheme.getTextSecondaryColor(Theme.of(context).brightness).withOpacity(0.1);
        textColor = AppTheme.getTextSecondaryColor(Theme.of(context).brightness);
        displayText = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness).withOpacity(0.5),
          ),
          SizedBox(height: 24),
          Text(
            AppTranslations.getString(context, 'no_campaigns_yet'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'campaigns_will_appear_here'),
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              context
                  .read<InfluencerCampaignBloc>()
                  .add(LoadInfluencerCampaigns());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppTranslations.getString(context, 'refresh'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(InfluencerCampaignError state) {
    // Check if it's a 403 status code
    final isAccountNotActive = state.statusCode == 403;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAccountNotActive
                ? Icons.account_circle_outlined
                : Icons.error_outline,
            size: 80,
            color: isAccountNotActive
                ? AppTheme.statusRed
                : AppTheme.errorColor.withOpacity(0.5),
          ),
          SizedBox(height: 24),
          Text(
            isAccountNotActive
                ? AppTranslations.getString(context, 'account_not_active')
                : AppTranslations.getString(context, 'something_went_wrong'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isAccountNotActive
                ? AppTranslations.getString(context, 'account_not_active')
                : state.message,
            style: TextStyle(
              color:
                  isAccountNotActive ? AppTheme.statusRed : AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          // Only show retry button if it's not a 403 error
          if (!isAccountNotActive) ...[
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context
                    .read<InfluencerCampaignBloc>()
                    .add(LoadInfluencerCampaigns());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppTranslations.getString(context, 'try_again'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
