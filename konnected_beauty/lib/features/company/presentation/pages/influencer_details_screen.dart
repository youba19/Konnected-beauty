import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';

import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class InfluencerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> influencer;

  const InfluencerDetailsScreen({
    super.key,
    required this.influencer,
  });

  @override
  State<InfluencerDetailsScreen> createState() =>
      _InfluencerDetailsScreenState();
}

class _InfluencerDetailsScreenState extends State<InfluencerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPromotionType;
  final _promotionValueController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promotionValueController.dispose();
    super.dispose();
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
                Color(0xFF1F1E1E),
                Color(0xFF3B3B3B),
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildProfileSection(),
                          const SizedBox(height: 24),
                          _buildInviteButton(),
                          const SizedBox(height: 32),
                          _buildInformationSection(),
                          const SizedBox(height: 32),
                          _buildSocialMediaSection(),
                          const SizedBox(height: 32),
                          _buildReviewsSection(),
                          const SizedBox(height: 24),
                        ],
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              widget.influencer['profileImage'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.white.withOpacity(0.1),
                  child: const Icon(
                    LucideIcons.user,
                    color: Colors.white54,
                    size: 60,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '@${widget.influencer['username'] ?? ''}',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.influencer['description'] ?? '',
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 16,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInviteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          _showCampaignInviteDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Invite for a campaign',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(LucideIcons.plus, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Zone', widget.influencer['zone'] ?? 'Not specified'),
        const SizedBox(height: 16),
        _buildInfoRow('Phone', widget.influencer['phone'] ?? 'Not specified'),
        const SizedBox(height: 16),
        _buildInfoRow('Email', widget.influencer['email'] ?? 'Not specified'),
        const SizedBox(height: 16),
        _buildInfoRow(
          'Rating',
          '${widget.influencer['rating'] ?? 0}',
          isRating: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isRating = false}) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isRating
                      ? AppTheme.textSecondaryColor
                      : AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: isRating ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isRating) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.star,
                  color: AppTheme.textPrimaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.share2,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Social Media',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSocialMediaButton(
          'Instagram',
          LucideIcons.instagram,
          widget.influencer['instagram'],
        ),
        const SizedBox(height: 12),
        _buildSocialMediaButton(
          'LinkedIn',
          LucideIcons.linkedin,
          widget.influencer['linkedin'],
        ),
        const SizedBox(height: 12),
        _buildSocialMediaButton(
          'Snapchat',
          LucideIcons.smartphone,
          widget.influencer['snapchat'],
        ),
      ],
    );
  }

  Widget _buildSocialMediaButton(String platform, IconData icon, String? url) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          if (url != null && url.isNotEmpty) {
            _openSocialMedia(url);
          } else {
            TopNotificationService.showInfo(
              context: context,
              message: '$platform link not available.',
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Text(
                  platform,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(LucideIcons.externalLink, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.messageSquare,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Reviews',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Sample reviews for design preview
        _buildReviewCard(
          'Beauty Salon Pro',
          'Excellent work! Very professional and creative content. Highly recommend! 💪',
          '2 hours ago',
        ),

        const SizedBox(height: 12),

        _buildReviewCard(
          'Glamour Studio',
          'Amazing collaboration! The influencer delivered exactly what we needed. ⭐',
          '1 day ago',
        ),

        const SizedBox(height: 12),

        _buildReviewCard(
          'Style & Beauty Co.',
          'Great communication and timely delivery. Will definitely work together again! ✨',
          '3 days ago',
        ),
      ],
    );
  }

  Widget _buildReviewCard(
      String companyName, String reviewText, String timestamp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                companyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                timestamp,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reviewText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _openSocialMedia(String url) {
    TopNotificationService.showInfo(
      context: context,
      message: 'Opening $url...',
    );
  }

  void _showCampaignInviteDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Campaign Invite',
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: AppTheme.primaryColor,
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.95, // slightly wider for better button fit
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.getString(
                            context, 'campaign_invite_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppTranslations.getString(
                            context, 'campaign_invite_instructions'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppTranslations.getString(context, 'promotion_type'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedPromotionType,
                          decoration: InputDecoration(
                            hintText: AppTranslations.getString(
                                context, 'select_type'),
                            hintStyle: const TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          dropdownColor: const Color(0xFF2A2A2A),
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppTranslations.getString(
                                  context, 'please_select_promotion_type');
                            }
                            return null;
                          },
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPromotionType = newValue;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                                value: 'Discount', child: Text('Discount')),
                            DropdownMenuItem(
                                value: 'Free Service',
                                child: Text('Free Service')),
                            DropdownMenuItem(
                                value: 'Special Offer',
                                child: Text('Special Offer')),
                            DropdownMenuItem(
                                value: 'Package Deal',
                                child: Text('Package Deal')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppTranslations.getString(context, 'promotion_value'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _promotionValueController,
                        decoration: InputDecoration(
                          hintText: 'XX',
                          hintStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.white, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.white, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Colors.white, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppTranslations.getString(
                                context, 'please_enter_promotion_value');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Create Campaign & Invite Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _createCampaignAndInvite,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        AppTranslations.getString(
                                            context, 'create_campaign_invite'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      LucideIcons.tag,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: AppTheme.textPrimaryColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppTranslations.getString(context, 'cancel'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _createCampaignAndInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Close dialog
    Navigator.of(context).pop();

    // Show success message
    TopNotificationService.showSuccess(
      context: context,
      message:
          AppTranslations.getString(context, 'campaign_created_successfully'),
    );
  }
}
