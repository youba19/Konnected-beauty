import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;

  const CampaignDetailsScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        return Scaffold(
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
                // Header
                _buildHeader(),

                // Campaign Information
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCampaignWithSection(),
                        const SizedBox(height: 24),
                        _buildCreatedAtSection(),
                        const SizedBox(height: 24),
                        _buildPromotionSection(),
                        const SizedBox(height: 24),
                        _buildClicksSection(),
                        const SizedBox(height: 24),
                        _buildCompletedOrdersSection(),
                        const SizedBox(height: 24),
                        _buildTotalSection(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimaryColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignWithSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.getString(context, 'campaign_with'),
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
              ),
            ),

            // Status Button
            _buildStatusButton(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[600],
              child: Icon(
                Icons.person,
                color: AppTheme.textPrimaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '@${widget.campaign['influencer']['pseudo']}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['date'],
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
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.campaign['promotionType'] ?? 'Pourcentage',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                'Value',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.campaign['promotionValue'] ?? '20%',
                style: const TextStyle(
                  color: Colors.white,
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

  Widget _buildClicksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'clicks'),
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.campaign['clicks']} Clicks',
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
          'Completed orders',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.campaign['completedOrders'] ?? 350}',
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
          'Total',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaign['total'] ?? '12,000 EUR',
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text(
              'Finished',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 5,
            ),
            Icon(
              Icons.done_all_outlined, // 👤 profile icon
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ],
        ),
      );
    } else if (status == 'waiting for influencer') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text(
              'Waiting for influencer',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 5,
            ),
            Icon(
              Icons.person_2_outlined, // 👤 profile icon
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
    } else if (status == 'waiting for influencer') {
      // Only delete button for waiting campaigns
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _showDeleteCampaignDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.transparentBackground,
            foregroundColor: AppTheme.borderColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                  color: Colors.white, width: 1), // ✅ White border
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Delete Campaign',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete, size: 24),
            ],
          ),
        ),
      );
    } else {
      // Both buttons for ongoing campaigns
      return Column(
        children: [
          // Finish Campaign Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement finish campaign functionality
                TopNotificationService.showSuccess(
                  context: context,
                  message: 'Campaign finished successfully!',
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
                children: const [
                  Text(
                    'Finish campaign',
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

          const SizedBox(height: 16),

          // Copy Link Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement copy link functionality
                Clipboard.setData(
                    const ClipboardData(text: 'https://campaign-link.com'));
                TopNotificationService.showSuccess(
                  context: context,
                  message: 'Campaign link copied to clipboard!',
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
                children: const [
                  Text(
                    'Copy link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.link, size: 24),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  void _showDeleteCampaignDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Campaign',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this campaign?',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // TODO: Implement delete campaign functionality
                TopNotificationService.showSuccess(
                  context: context,
                  message: 'Campaign deleted successfully!',
                );
                Navigator.of(context).pop(); // Go back to campaigns screen
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
