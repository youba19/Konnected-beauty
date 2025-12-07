import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/influencer_campaigns/influencer_campaign_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class InfluencerCampaignDetailScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;

  const InfluencerCampaignDetailScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<InfluencerCampaignDetailScreen> createState() =>
      _InfluencerCampaignDetailScreenState();
}

class _InfluencerCampaignDetailScreenState
    extends State<InfluencerCampaignDetailScreen> {
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
          // Navigate back after successful action
          Navigator.of(context).pop();
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
            backgroundColor:
                AppTheme.getScaffoldBackground(Theme.of(context).brightness),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        SizedBox(height: 24),

                        // Campaign Information
                        _buildCreatedAtSection(),
                        SizedBox(height: 24),
                        _buildPromotionSection(),
                        SizedBox(height: 24),
                        _buildMessageSection(),
                        SizedBox(height: 24),
                        _buildClicksSection(),
                        SizedBox(height: 24),
                        _buildCompletedOrdersSection(),
                        SizedBox(height: 24),
                        _buildTotalSection(),
                        SizedBox(height: 20),
                        _buildActionButtons(),
                        SizedBox(
                            height: 20), // Bottom padding for better scrolling
                      ],
                    ),
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
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.transparentBackground : AppTheme.textWhite54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                size: 24,
              ),
            ),
          ),
          SizedBox(height: 20),

          // Campaign name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(context, 'campaign_with'),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.campaign['saloonName'] ?? 'Salon name',
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Button
              _buildStatusButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignWithSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'campaign_with'),
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.campaign['saloonName'] ?? 'Salon name',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatedAtSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'created_at'),
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.campaign['createdAt'] ?? '14/07/2025',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'promotion_type'),
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.campaign['promotionType'] ?? 'Pourcentage',
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'value'),
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.campaign['promotionValue'] ?? '20%',
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'message'),
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.campaign['message'] ?? 'Salut Perdo! Accepter svp!',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildClicksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'clicks'),
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.campaign['clicks']?.toString() ?? '0',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'completed_orders'),
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.campaign['completedOrders']?.toString() ?? '0',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'total'),
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.campaign['total'] ?? '0 EUR',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton() {
    final status = widget.campaign['status']?.toString().toLowerCase() ?? '';
    final initiator =
        widget.campaign['initiator']?.toString().toLowerCase() ?? '';

    if (status == 'finished') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Builder(
              builder: (context) => Text(
                'Finished',
                style: TextStyle(
                  color:
                      AppTheme.getSecondaryColor(Theme.of(context).brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.done_all_outlined,
              color: AppTheme.getSecondaryColor(Theme.of(context).brightness),
              size: 20,
            ),
          ],
        ),
      );
    } else if (status == 'waiting for you' ||
        (status == 'pending' && initiator == 'salon')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              status == 'waiting for you'
                  ? 'Waiting for you'
                  : AppTranslations.getString(context, 'received_invitation'),
              style: TextStyle(
                color: AppTheme.getSecondaryColor(Theme.of(context).brightness),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              status == 'waiting for you' ? Icons.person : Icons.mail,
              color: AppTheme.getSecondaryColor(Theme.of(context).brightness),
              size: 20,
            ),
          ],
        ),
      );
    } else {
      // On going or other statuses
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.lightTextPrimaryColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'On going',
              style: TextStyle(
                color: AppTheme.lightTextPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.lightTextPrimaryColor,
                    width: 1,
                    style: BorderStyle.solid),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTextPrimaryColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    final status = widget.campaign['status']?.toString().toLowerCase() ?? '';
    final initiator =
        widget.campaign['initiator']?.toString().toLowerCase() ?? '';

    if (status == 'finished') {
      // No buttons for finished campaigns
      return const SizedBox.shrink();
    } else if (status == 'waiting for you' ||
        (status == 'pending' && initiator == 'salon')) {
      // Accept and Refuse buttons for waiting campaigns and received invitations
      return Column(
        children: [
          // Accept Campaign Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<InfluencerCampaignBloc>().add(
                      AcceptCampaign(widget.campaign['id'] ?? ''),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppTranslations.getString(context, 'accept_campaign'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check, size: 24),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Refuse Campaign Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showRefuseCampaignDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.transparentBackground : AppTheme.textWhite54,
                foregroundColor:
                    AppTheme.getBorderColor(Theme.of(context).brightness),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppTranslations.getString(context, 'refuse_campaign'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.close, size: 24),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Copy Link Button for ongoing campaigns
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            context.read<InfluencerCampaignBloc>().add(
                  CopyCampaignLink(widget.campaign['id'] ?? ''),
                );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.transparentBackground : AppTheme.textWhite54,
            foregroundColor:
                AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppTranslations.getString(context, 'copy_link'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.copy, size: 24),
            ],
          ),
        ),
      );
    }
  }

  void _showRefuseCampaignDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme.getSecondaryColor(Theme.of(context).brightness),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTranslations.getString(context, 'refuse_campaign'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppTranslations.getString(context, 'refuse_campaign_confirmation'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppTranslations.getString(context, 'cancel'),
                style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<InfluencerCampaignBloc>().add(
                      RefuseCampaign(widget.campaign['id'] ?? ''),
                    );
              },
              child: Text(
                AppTranslations.getString(context, 'refuse'),
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
