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
            backgroundColor: const Color(0xFF121212),
            body: Stack(
              children: [
                // TOP GREEN GLOW (same as influencer home screen)
                Positioned(
                  top: -140,
                  left: -60,
                  right: -60,
                  child: IgnorePointer(
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        // soft radial green halo like the screenshot
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

                // CONTENT
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Campaign Information
                        _buildCreatedAtSection(),
                        const SizedBox(height: 24),
                        _buildPromotionSection(),
                        const SizedBox(height: 24),
                        _buildMessageSection(),
                        const SizedBox(height: 24),
                        _buildClicksSection(),
                        const SizedBox(height: 24),
                        _buildCompletedOrdersSection(),
                        const SizedBox(height: 24),
                        _buildTotalSection(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        const SizedBox(
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
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: AppTheme.textPrimaryColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 20),

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
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.campaign['saloonName'] ?? 'Salon name',
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
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
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['saloonName'] ?? 'Salon name',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
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
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['createdAt'] ?? '14/07/2025',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
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
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.campaign['promotionType'] ?? 'Pourcentage',
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'value'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.campaign['promotionValue'] ?? '20%',
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
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
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['message'] ?? 'Salut Perdo! Accepter svp!',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
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
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['clicks']?.toString() ?? '0',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
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
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['completedOrders']?.toString() ?? '0',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
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
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['total'] ?? '0 EUR',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton() {
    final status = widget.campaign['status']?.toString().toLowerCase() ?? '';

    if (status == 'finished') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Finished',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.done_all_outlined,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ],
        ),
      );
    } else if (status == 'waiting for you') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Waiting for you',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.person,
              color: AppTheme.secondaryColor,
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
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'On going',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black, width: 1, style: BorderStyle.solid),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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

    if (status == 'finished') {
      // No buttons for finished campaigns
      return const SizedBox.shrink();
    } else if (status == 'waiting for you') {
      // Accept and Refuse buttons for waiting campaigns
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
                foregroundColor: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 24),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Refuse Campaign Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showRefuseCampaignDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.transparentBackground,
                foregroundColor: AppTheme.borderColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppTranslations.getString(context, 'refuse_campaign'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.close, size: 24),
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
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.white, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppTranslations.getString(context, 'copy_link'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.copy, size: 24),
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
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTranslations.getString(context, 'refuse_campaign'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppTranslations.getString(context, 'refuse_campaign_confirmation'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppTranslations.getString(context, 'cancel'),
                style: const TextStyle(color: AppTheme.textPrimaryColor),
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
                style: const TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
