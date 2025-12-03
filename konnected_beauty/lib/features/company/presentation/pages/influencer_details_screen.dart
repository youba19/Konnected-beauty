import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _followersPromotionController = TextEditingController();
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
    _followersPromotionController.dispose();
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
    final email = data['email'] ?? '';
    final phoneNumber = data['phoneNumber'] ?? '';

    // Calculate average rating
    double averageRating = 0.0;
    if (receivedRatings.isNotEmpty) {
      final totalStars = receivedRatings.fold<int>(
        0,
        (int sum, dynamic rating) => sum + ((rating['stars'] as int?) ?? 0),
      );
      averageRating = totalStars / receivedRatings.length;
    }

    print('🎨 === BUILDING LOADED STATE ===');
    print('🎨 Profile: $profile');
    print('🎨 Socials: $socials');
    print('🎨 Received Ratings: $receivedRatings');
    print('🎨 Email: $email');
    print('🎨 Phone: $phoneNumber');
    print('🎨 Average Rating: $averageRating');

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
                      _buildProfileSection(
                          profile, email, phoneNumber, averageRating),
                      const SizedBox(height: 16),
                      _buildBioSection(profile),
                      const SizedBox(height: 24),
                      _buildInviteButton(),
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
      padding: const EdgeInsets.all(0.0),
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

  Widget _buildProfileSection(
    Map<String, dynamic> profile,
    String email,
    String phoneNumber,
    double averageRating,
  ) {
    final profilePicture = profile['profilePicture'];
    final pseudo = profile['pseudo'] ?? 'Unknown';
    final zone = profile['zone'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Picture with Rating Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: profilePicture != null && profilePicture.isNotEmpty
                    ? Image.network(
                        profilePicture,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(
                              LucideIcons.user,
                              color: Colors.white54,
                              size: 50,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.white.withOpacity(0.1),
                        child: const Icon(
                          LucideIcons.user,
                          color: Colors.white54,
                          size: 50,
                        ),
                      ),
              ),
            ),
            // Rating Badge overlapping bottom-center
            if (averageRating > 0)
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // User Information in the middle (centered with image)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Handle
              Text(
                '@$pseudo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Location
              if (zone.isNotEmpty)
                Text(
                  zone,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (zone.isNotEmpty) const SizedBox(height: 6),
              // Phone Number
              if (phoneNumber.isNotEmpty)
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (phoneNumber.isNotEmpty) const SizedBox(height: 6),
              // Email
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(Map<String, dynamic> profile) {
    final bio = profile['bio'] ??
        AppTranslations.getString(context, 'no_bio_available');

    return Text(
      bio,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
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
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isRating
                        ? AppTheme.textSecondaryColor
                        : AppTheme.textPrimaryColor,
                    fontSize: 16,
                    fontWeight: isRating ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
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
            final comment = rating['comment'] ?? '';
            final createdAt = rating['createdAt'] ?? '';
            final stars = rating['stars'] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReviewCard(
                salonName,
                comment.isEmpty
                    ? AppTranslations.getString(context, 'no_comment')
                    : comment,
                _formatDate(createdAt),
                stars,
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildReviewCard(
      String companyName, String reviewText, String timestamp, int stars) {
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
              Expanded(
                child: Text(
                  companyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                timestamp,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              _buildStarRating(stars),
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

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show the numeric rating
        Text(
          '$rating',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        // Show the star icon
        const Icon(
          Icons.star,
          color: Colors.yellow,
          size: 16,
        ),
      ],
    );
  }

  void _openSocialMedia(String url) async {
    try {
      // Ensure the URL has a proper scheme
      String urlToLaunch = url.trim();
      if (!urlToLaunch.startsWith('http://') &&
          !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }

      final Uri uri = Uri.parse(urlToLaunch);

      print('🔗 Attempting to open URL: $urlToLaunch');

      // Try to launch the URL directly (canLaunchUrl can be unreliable on Android)
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('✅ URL launched successfully');
        TopNotificationService.showSuccess(
          context: context,
          message: 'Opening link...',
        );
      } else {
        // If external application mode fails, try platform default
        print('⚠️ External application mode failed, trying platform default');
        bool launchedDefault = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );

        if (launchedDefault) {
          print('✅ URL launched with platform default mode');
          TopNotificationService.showSuccess(
            context: context,
            message: 'Opening link...',
          );
        } else {
          print('❌ Failed to launch URL with both modes');
          TopNotificationService.showError(
            context: context,
            message:
                'Could not open the link. Please check if the URL is valid.',
          );
        }
      }
    } catch (e) {
      print('❌ Error opening URL: $e');
      print('❌ URL was: $url');
      TopNotificationService.showError(
        context: context,
        message: 'Error opening link. Please check if the URL is valid.',
      );
    }
  }

  void _showCampaignInviteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (context) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          body: Container(
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
            child: SafeArea(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
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
                          // Followers promotion value
                          Text(
                            AppTranslations.getString(
                                context, 'followers_promotion_value'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _followersPromotionController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '00',
                              hintStyle: const TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Center(
                                  widthFactor: 1.0,
                                  child: Text(
                                    '%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppTranslations.getString(
                                    context, 'please_enter_promotion_value');
                              }

                              final intValue = int.tryParse(value);
                              if (intValue == null) {
                                return 'Please enter a valid number';
                              }

                              if (intValue < 0 || intValue > 100) {
                                return AppTranslations.getString(
                                    context, 'percentage_validation');
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Commission influencer
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.getString(
                                    context, 'commission_influencer'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                '8%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Commission Kbeauty
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.getString(
                                    context, 'commission_kbeauty'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                '3%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 1),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.black),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            AppTranslations.getString(context,
                                                'create_campaign_invite'),
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
                                backgroundColor: const Color(0xFF2A2A2A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
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
      // Get form data - always use percentage
      final promotionType = 'percentage';
      final promotionValue = int.parse(_followersPromotionController.text);
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
