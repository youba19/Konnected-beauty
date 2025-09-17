import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/influencer_details/influencer_details_bloc.dart';
import '../../../../core/bloc/influencer_details/influencer_details_event.dart';
import '../../../../core/bloc/influencer_details/influencer_details_state.dart';
import '../../../../core/services/api/influencers_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class InfluencerDetailsScreen extends StatefulWidget {
  final String influencerId;

  const InfluencerDetailsScreen({
    super.key,
    required this.influencerId,
  });

  @override
  State<InfluencerDetailsScreen> createState() =>
      _InfluencerDetailsScreenState();
}

class _InfluencerDetailsScreenState extends State<InfluencerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPromotionType;
  final _promotionValueController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('👤 === INFLUENCER DETAILS SCREEN INIT ===');
    print('🆔 Influencer ID: ${widget.influencerId}');

    // Load influencer details
    context.read<InfluencerDetailsBloc>().add(
          LoadInfluencerDetails(influencerId: widget.influencerId),
        );
  }

  @override
  void dispose() {
    _promotionValueController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        return BlocBuilder<InfluencerDetailsBloc, InfluencerDetailsState>(
          builder: (context, state) {
            print('🎨 === INFLUENCER DETAILS SCREEN BUILD ===');
            print('🎨 State: ${state.runtimeType}');

            if (state is InfluencerDetailsLoading) {
              return _buildLoadingState();
            } else if (state is InfluencerDetailsError) {
              return _buildErrorState(state);
            } else if (state is InfluencerDetailsLoaded) {
              return _buildLoadedState(state);
            } else {
              return _buildInitialState();
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.getString(
                    context, 'loading_influencer_details'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(InfluencerDetailsError state) {
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.getString(context, 'error_loading_details'),
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
                    context.read<InfluencerDetailsBloc>().add(
                          RefreshInfluencerDetails(
                              influencerId: widget.influencerId),
                        );
                  },
                  icon: const Icon(LucideIcons.refreshCw),
                  label: Text(AppTranslations.getString(context, 'retry')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
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
        body: Center(
          child: Text(
            AppTranslations.getString(context, 'initializing'),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(InfluencerDetailsLoaded state) {
    final data = state.influencerData;
    final profile = data['profile'] ?? {};
    final socials = data['socials'] ?? [];
    final receivedRatings = data['receivedRatings'] ?? [];

    print('🎨 === BUILDING LOADED STATE ===');
    print('🎨 Profile: $profile');
    print('🎨 Socials: $socials');
    print('🎨 Received Ratings: $receivedRatings');

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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileSection(profile),
                      const SizedBox(height: 24),
                      _buildInviteButton(),
                      const SizedBox(height: 32),
                      _buildInformationSection(profile),
                      const SizedBox(height: 32),
                      _buildSocialMediaSection(socials),
                      const SizedBox(height: 32),
                      _buildReviewsSection(receivedRatings),
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

  Widget _buildProfileSection(Map<String, dynamic> profile) {
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
            child: profile['profilePicture'] != null
                ? Image.network(
                    profile['profilePicture'],
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
                  )
                : Container(
                    color: Colors.white.withOpacity(0.1),
                    child: const Icon(
                      LucideIcons.user,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '@${profile['pseudo'] ?? 'Unknown'}',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile['bio'] ??
              AppTranslations.getString(context, 'no_bio_available'),
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 16,
            height: 1.4,
          ),
          maxLines: 3,
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
          children: [
            Text(
              AppTranslations.getString(context, 'invite_for_campaign'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(LucideIcons.plus, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationSection(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
            AppTranslations.getString(context, 'zone'),
            profile['zone'] ??
                AppTranslations.getString(context, 'not_specified')),
        const SizedBox(height: 16),
        _buildInfoRow(
            AppTranslations.getString(context, 'pseudo'),
            profile['pseudo'] ??
                AppTranslations.getString(context, 'not_specified')),
        const SizedBox(height: 16),
        _buildInfoRow(
            AppTranslations.getString(context, 'bio'),
            profile['bio'] ??
                AppTranslations.getString(context, 'not_specified')),
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

  Widget _buildSocialMediaSection(List<dynamic> socials) {
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
            Text(
              AppTranslations.getString(context, 'social_media'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (socials.isEmpty)
          Text(
            AppTranslations.getString(context, 'no_social_media_available'),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          )
        else
          ...socials.map<Widget>((social) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSocialMediaButton(
                social['name'] ?? 'Unknown',
                _getSocialIcon(social['name']),
                social['link'],
              ),
            );
          }).toList(),
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

  Widget _buildReviewsSection(List<dynamic> receivedRatings) {
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
            Text(
              AppTranslations.getString(context, 'reviews'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (receivedRatings.isEmpty)
          Text(
            AppTranslations.getString(context, 'no_reviews_available'),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          )
        else
          ...receivedRatings.map<Widget>((rating) {
            final salonInfo = rating['ratedBy']?['salonInfo'] ?? {};
            final salonName = salonInfo['name'] ??
                AppTranslations.getString(context, 'unknown_salon');
            final domain = salonInfo['domain'] ??
                AppTranslations.getString(context, 'unknown_domain');
            final address = salonInfo['address'] ??
                AppTranslations.getString(context, 'unknown_address');
            final createdAt = rating['createdAt'] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReviewCard(
                salonName,
                '${AppTranslations.getString(context, 'domain')}: $domain\n${AppTranslations.getString(context, 'address')}: $address',
                _formatDate(createdAt),
              ),
            );
          }).toList(),
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
                                value: 'percentage', child: Text('Percentage')),
                            DropdownMenuItem(
                                value: 'fixed', child: Text('Fixed Amount')),
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
                          hintText: _selectedPromotionType == 'percentage'
                              ? '20'
                              : '100',
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

                          // Parse the value as integer
                          final intValue = int.tryParse(value);
                          if (intValue == null) {
                            return 'Please enter a valid number';
                          }

                          // Validate based on promotion type
                          if (_selectedPromotionType == 'percentage') {
                            if (intValue < 0 || intValue > 100) {
                              return AppTranslations.getString(
                                  context, 'percentage_validation');
                            }
                          } else if (_selectedPromotionType == 'fixed') {
                            if (intValue <= 0) {
                              return AppTranslations.getString(
                                  context, 'fixed_amount_validation');
                            }
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppTranslations.getString(
                            context, 'message_to_influencer'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: AppTranslations.getString(
                              context, 'message_placeholder'),
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
                                context, 'please_enter_message');
                          }
                          if (value.length < 10) {
                            return AppTranslations.getString(
                                context, 'message_min_length');
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

    try {
      // Get form data
      final promotionType = _selectedPromotionType!;
      final promotionValue = int.parse(_promotionValueController.text);
      final message = _messageController.text;

      print('📝 === CREATING CAMPAIGN INVITE ===');
      print('📝 Promotion Type: $promotionType');
      print('📝 Promotion Value: $promotionValue');
      print('📝 Message: $message');
      print('📝 Influencer ID: ${widget.influencerId}');

      // Call the API
      final result = await InfluencersService.inviteInfluencer(
        receiverId: widget.influencerId,
        promotion: promotionValue,
        promotionType: promotionType,
        invitationMessage: message,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Close dialog
      Navigator.of(context).pop();

      // Show result message
      if (result['success'] == true) {
        print('✅ Campaign invite sent successfully');
        print('📊 Campaign Data: ${result['data']}');

        TopNotificationService.showSuccess(
          context: context,
          message: result['message'] ??
              AppTranslations.getString(
                  context, 'campaign_created_successfully'),
        );
      } else {
        print('❌ Failed to send campaign invite: ${result['message']}');

        TopNotificationService.showError(
          context: context,
          message: result['message'] ?? 'Failed to send campaign invite',
        );
      }
    } catch (e) {
      print('❌ Exception in _createCampaignAndInvite: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Close dialog
      Navigator.of(context).pop();

      // Show error message
      TopNotificationService.showError(
        context: context,
        message: 'Error sending campaign invite: $e',
      );
    }
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return LucideIcons.instagram;
      case 'tiktok':
        return LucideIcons.video;
      case 'youtube':
        return LucideIcons.youtube;
      case 'twitter':
        return LucideIcons.twitter;
      case 'facebook':
        return LucideIcons.facebook;
      case 'linkedin':
        return LucideIcons.linkedin;
      case 'snapchat':
        return LucideIcons.smartphone;
      default:
        return LucideIcons.share2;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        final days = difference.inDays;
        return '$days ${days == 1 ? AppTranslations.getString(context, 'day_ago') : AppTranslations.getString(context, 'days_ago')} ago';
      } else if (difference.inHours > 0) {
        final hours = difference.inHours;
        return '$hours ${hours == 1 ? AppTranslations.getString(context, 'hour_ago') : AppTranslations.getString(context, 'hours_ago')} ago';
      } else if (difference.inMinutes > 0) {
        final minutes = difference.inMinutes;
        return '$minutes ${minutes == 1 ? AppTranslations.getString(context, 'minute_ago') : AppTranslations.getString(context, 'minutes_ago')} ago';
      } else {
        return AppTranslations.getString(context, 'just_now');
      }
    } catch (e) {
      return AppTranslations.getString(context, 'unknown');
    }
  }
}
