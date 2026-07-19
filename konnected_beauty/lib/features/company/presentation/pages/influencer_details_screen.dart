import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/influencer_details/influencer_details_bloc.dart';
import '../../../../core/bloc/influencer_details/influencer_details_event.dart';
import '../../../../core/bloc/influencer_details/influencer_details_state.dart';
import '../../../../core/services/api/influencers_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../widgets/common/stripe_link_required_dialog.dart';

abstract final class _InfluencerDetailsUi {
  static const double radius = 16;
  static const double inviteProfileCardHeight = 55.29;
  static const double backButtonSize = 44;
  static const double horizontalPadding = 16;
}

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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);

        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return BlocBuilder<InfluencerDetailsBloc, InfluencerDetailsState>(
              builder: (context, state) {
                print('🎨 === INFLUENCER DETAILS SCREEN BUILD ===');
                print('🎨 State: ${state.runtimeType}');

                if (state is InfluencerDetailsLoading) {
                  return _buildLoadingState(ui);
                } else if (state is InfluencerDetailsError) {
                  return _buildErrorState(state, ui);
                } else if (state is InfluencerDetailsLoaded) {
                  return _buildLoadedState(state, ui);
                } else {
                  return _buildInitialState(ui);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState(SalonUiTheme ui) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ui.systemOverlay,
      child: ColoredBox(
        color: ui.bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              color: ui.isDark ? Colors.white : SalonUiTheme.blueUpper,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(InfluencerDetailsError state, SalonUiTheme ui) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ui.systemOverlay,
      child: ColoredBox(
        color: ui.bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildOverlayIconButton(
                    ui: ui,
                    icon: LucideIcons.arrowLeft,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppTranslations.getString(
                              context, 'error_loading_details'),
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(
                            color: ui.textSecondary,
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
                          icon: Icon(
                            LucideIcons.refreshCw,
                            color: ui.primaryButtonFg,
                          ),
                          label: Text(
                            AppTranslations.getString(context, 'retry'),
                            style: TextStyle(color: ui.primaryButtonFg),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ui.primaryButtonBg,
                            foregroundColor: ui.primaryButtonFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState(SalonUiTheme ui) {
    return ColoredBox(
      color: ui.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            color: ui.isDark ? Colors.white : SalonUiTheme.blueUpper,
          ),
        ),
      ),
    );
  }

  double _heroExpandedHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height * 0.52;
  }

  double _heroCollapsedHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 148;
  }

  Widget _buildLoadedState(InfluencerDetailsLoaded state, SalonUiTheme ui) {
    final data = state.influencerData;
    final profile = data['profile'] ?? {};
    final socials = data['socials'] ?? [];
    final receivedRatings = data['receivedRatings'] ?? [];
    final email = data['email']?.toString() ?? '';
    final phoneNumber = data['phoneNumber']?.toString() ?? '';
    final profilePicture = profile['profilePicture']?.toString();
    final pseudo = profile['pseudo']?.toString() ?? 'unknown';
    final zone = profile['zone']?.toString() ?? '';
    final bio = profile['bio']?.toString() ??
        AppTranslations.getString(context, 'no_bio_available');

    double averageRating = 0.0;
    if (receivedRatings.isNotEmpty) {
      final totalStars = receivedRatings.fold<int>(
        0,
        (int sum, dynamic rating) => sum + ((rating['stars'] as int?) ?? 0),
      );
      averageRating = totalStars / receivedRatings.length;
    }

    final expandedHeight = _heroExpandedHeight(context);
    final collapsedHeight = _heroCollapsedHeight(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ui.systemOverlay,
      child: ColoredBox(
        color: ui.bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _InfluencerHeroHeaderDelegate(
                  ui: ui,
                  expandedHeight: expandedHeight,
                  collapsedHeight: collapsedHeight,
                  topInset: topInset,
                  imageUrl: profilePicture,
                  pseudo: pseudo,
                  zone: zone,
                  phone: phoneNumber,
                  email: email,
                  rating: averageRating,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  _InfluencerDetailsUi.horizontalPadding,
                  8,
                  _InfluencerDetailsUi.horizontalPadding,
                  32,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      bio,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInviteButton(ui),
                    const SizedBox(height: 20),
                    _buildSocialMediaSection(socials, ui),
                    const SizedBox(height: 28),
                    Text(
                      AppTranslations.getString(context, 'reviews'),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (receivedRatings.isEmpty)
                      Text(
                        AppTranslations.getString(
                            context, 'no_reviews_available'),
                        style: TextStyle(
                          color: ui.textMuted,
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
                                ? AppTranslations.getString(
                                    context, 'no_comment')
                                : comment,
                            _formatDate(createdAt),
                            stars,
                            ui,
                          ),
                        );
                      }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayIconButton({
    required SalonUiTheme ui,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _InfluencerDetailsUi.backButtonSize,
          height: _InfluencerDetailsUi.backButtonSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ui.buttonFillTop, ui.buttonFillBottom],
            ),
            shape: BoxShape.circle,
            border: ui.isDark
                ? null
                : Border.all(color: ui.cardBorder, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: ui.buttonIcon, size: 22),
        ),
      ),
    );
  }

  Widget _buildInviteButton(SalonUiTheme ui) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showCampaignInviteDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: ui.primaryButtonBg,
          foregroundColor: ui.primaryButtonFg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppTranslations.getString(context, 'invite_for_campaign'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.ticket, size: 20, color: ui.primaryButtonFg),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection(List<dynamic> socials, SalonUiTheme ui) {
    if (socials.isEmpty) {
      return const SizedBox.shrink();
    }

    final widgets = <Widget>[];
    for (var i = 0; i < socials.length; i += 2) {
      final first = socials[i];
      final second = i + 1 < socials.length ? socials[i + 1] : null;

      if (second != null) {
        widgets.add(
          Row(
            children: [
              Expanded(
                child: _buildSocialMediaButton(
                  first['name'] ?? 'Unknown',
                  first['link'],
                  ui,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialMediaButton(
                  second['name'] ?? 'Unknown',
                  second['link'],
                  ui,
                ),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 12));
      } else {
        widgets.add(
          _buildSocialMediaButton(
            first['name'] ?? 'Unknown',
            first['link'],
            ui,
          ),
        );
        widgets.add(const SizedBox(height: 12));
      }
    }

    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }

    return Column(children: widgets);
  }

  Widget _buildSocialMediaButton(
    String platform,
    String? url,
    SalonUiTheme ui,
  ) {
    return GestureDetector(
      onTap: () {
        if (url != null && url.isNotEmpty) {
          _openSocialMedia(url);
        } else {
          TopNotificationService.showInfo(
            context: context,
            message: '$platform link not available.',
          );
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
          border: Border.all(
            color: ui.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                platform,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.externalLink,
              color: ui.textPrimary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(
    String companyName,
    String reviewText,
    String timestamp,
    int stars,
    SalonUiTheme ui,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
        border: Border.all(
          color: ui.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  companyName,
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                timestamp,
                style: TextStyle(
                  color: ui.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              _buildStarRating(stars, ui),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reviewText,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating, SalonUiTheme ui) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$rating',
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
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
    final ui = SalonUiTheme.from(context.read<ThemeBloc>().state.brightness);
    final blocState = context.read<InfluencerDetailsBloc>().state;
    if (blocState is! InfluencerDetailsLoaded) return;

    final data = blocState.influencerData;
    final profile = data['profile'] ?? {};
    final pseudo = profile['pseudo']?.toString() ?? 'unknown';
    final zone = profile['zone']?.toString() ?? '';
    final pictureUrl = profile['profilePicture']?.toString();
    final receivedRatings = data['receivedRatings'] ?? [];

    double averageRating = 0.0;
    if (receivedRatings.isNotEmpty) {
      final totalStars = receivedRatings.fold<int>(
        0,
        (int sum, dynamic rating) => sum + ((rating['stars'] as int?) ?? 0),
      );
      averageRating = totalStars / receivedRatings.length;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                height: sheetHeight,
                decoration: BoxDecoration(
                  color: ui.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 200,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: ui.sheetHeaderGradient,
                            stops: const [0.0, 0.35, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getString(
                                context,
                                'invite_influencer_confirm_title',
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildInviteProfileCard(
                              ui: ui,
                              pseudo: pseudo,
                              zone: zone,
                              pictureUrl: pictureUrl,
                              rating: averageRating,
                            ),
                            const SizedBox(height: 16),
                            _buildInviteCommissionCard(ui),
                            const SizedBox(height: 20),
                            Text(
                              AppTranslations.getString(
                                context,
                                'followers_promotion_value',
                              ),
                              style: TextStyle(
                                color: ui.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _followersPromotionController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(color: ui.textPrimary),
                              decoration: _inviteInputDecoration(
                                hintText: '00',
                                ui: ui,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTranslations.getString(
                                    context,
                                    'please_enter_promotion_value',
                                  );
                                }
                                final intValue = int.tryParse(value);
                                if (intValue == null) {
                                  return AppTranslations.getString(
                                    context,
                                    'please_enter_valid_number',
                                  );
                                }
                                if (intValue < 0 || intValue > 100) {
                                  return AppTranslations.getString(
                                    context,
                                    'percentage_validation',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppTranslations.getString(
                                context,
                                'message_to_influencer',
                              ),
                              style: TextStyle(
                                color: ui.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _messageController,
                              maxLines: 4,
                              style: TextStyle(color: ui.textPrimary),
                              decoration: _inviteInputDecoration(
                                hintText: AppTranslations.getString(
                                  context,
                                  'message_placeholder',
                                ),
                                ui: ui,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTranslations.getString(
                                    context,
                                    'please_enter_message',
                                  );
                                }
                                if (value.length < 10) {
                                  return AppTranslations.getString(
                                    context,
                                    'message_min_length',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => _createCampaignAndInvite(
                                          onLoadingChanged: (loading) {
                                            setModalState(
                                              () => isSubmitting = loading,
                                            );
                                          },
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ui.primaryButtonBg,
                                  foregroundColor: ui.primaryButtonFg,
                                  disabledBackgroundColor: ui.primaryButtonBg
                                      .withValues(alpha: 0.7),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      _InfluencerDetailsUi.radius,
                                    ),
                                  ),
                                ),
                                child: isSubmitting
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: ui.primaryButtonFg,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              AppTranslations.getString(
                                                context,
                                                'create_campaign_invite',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            LucideIcons.ticket,
                                            size: 20,
                                            color: ui.primaryButtonFg,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ui.textPrimary,
                                  backgroundColor: ui.bg,
                                  side: BorderSide(
                                    color: ui.borderSubtle,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      _InfluencerDetailsUi.radius,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  AppTranslations.getString(context, 'cancel'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inviteInputDecoration({
    required String hintText,
    required SalonUiTheme ui,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: ui.isDark ? ui.textMuted : Colors.black,
        fontSize: 16,
      ),
      filled: true,
      fillColor: ui.isDark ? Colors.transparent : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: hintText == '00'
          ? Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '%',
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
        borderSide: BorderSide(color: ui.borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
        borderSide: BorderSide(color: ui.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
        borderSide: BorderSide(color: ui.borderSubtle, width: 1),
      ),
    );
  }

  Widget _buildInviteProfileCard({
    required SalonUiTheme ui,
    required String pseudo,
    required String zone,
    required String? pictureUrl,
    required double rating,
  }) {
    final ratingLabel = rating > 0
        ? rating.toStringAsFixed(rating == rating.roundToDouble() ? 0 : 1)
        : null;

    return SizedBox(
      height: _InfluencerDetailsUi.inviteProfileCardHeight,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
          border: Border.all(
            color: ui.cardBorder,
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ui.buttonFillTop, ui.buttonFillBottom],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: pictureUrl != null && pictureUrl.isNotEmpty
                        ? Image.network(
                            pictureUrl,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _inviteAvatarPlaceholder(ui);
                            },
                          )
                        : _inviteAvatarPlaceholder(ui),
                  ),
                  if (ratingLabel != null)
                    Positioned(
                      bottom: -2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ui.isDark
                                ? Colors.black.withValues(alpha: 0.78)
                                : Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ratingLabel,
                                style: TextStyle(
                                  color: ui.isDark
                                      ? Colors.white
                                      : ui.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFC107),
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '@$pseudo',
                    style: TextStyle(
                      color: ui.isDark ? Colors.white : Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  if (zone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      zone,
                      style: TextStyle(
                        color: ui.isDark
                            ? Colors.white.withValues(alpha: 0.92)
                            : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteAvatarPlaceholder(SalonUiTheme ui) {
    final placeholderColor =
        ui.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB);
    return Container(
      width: 42,
      height: 42,
      color: placeholderColor,
      child: Icon(LucideIcons.user, color: ui.textMuted, size: 22),
    );
  }

  Widget _buildInviteCommissionCard(SalonUiTheme ui) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ui.bannerFill,
        borderRadius: BorderRadius.circular(_InfluencerDetailsUi.radius),
        border: Border.all(
          color: ui.borderSubtle.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInviteCommissionRow(
            ui: ui,
            label: AppTranslations.getString(context, 'commission_influencer'),
            value: '8%',
          ),
          const SizedBox(height: 12),
          _buildInviteCommissionRow(
            ui: ui,
            label: AppTranslations.getString(context, 'commission_kbeauty'),
            value: '3%',
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCommissionRow({
    required SalonUiTheme ui,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ui.borderSubtle, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Icon(
            LucideIcons.badge,
            color: ui.textPrimary,
            size: 12,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _createCampaignAndInvite({void Function(bool loading)? onLoadingChanged}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    onLoadingChanged?.call(true);

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

      onLoadingChanged?.call(false);

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
      } else if (result['stripeAccountNotLinked'] == true) {
        await StripeLinkRequiredDialog.show(
          context,
          bodyTranslationKey: 'stripe_not_linked_invite_body',
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

      onLoadingChanged?.call(false);

      // Close dialog
      Navigator.of(context).pop();

      // Show error message
      TopNotificationService.showError(
        context: context,
        message: 'Error sending campaign invite: $e',
      );
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
      } else if (difference.inSeconds > 0) {
        return '${difference.inSeconds}s ago';
      } else {
        return AppTranslations.getString(context, 'just_now');
      }
    } catch (e) {
      return AppTranslations.getString(context, 'unknown');
    }
  }
}

class _InfluencerHeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _InfluencerHeroHeaderDelegate({
    required this.ui,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topInset,
    required this.imageUrl,
    required this.pseudo,
    required this.zone,
    required this.phone,
    required this.email,
    required this.rating,
    required this.onBack,
  });

  final SalonUiTheme ui;
  final double expandedHeight;
  final double collapsedHeight;
  final double topInset;
  final String? imageUrl;
  final String pseudo;
  final String zone;
  final String phone;
  final String email;
  final double rating;
  final VoidCallback onBack;

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final profileTop = lerpDouble(maxExtent - 124, topInset + 52, t)!;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (t < 1)
          Positioned.fill(
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return _heroPlaceholder(ui);
                      },
                    )
                  : _heroPlaceholder(ui),
            ),
          ),
        if (t < 0.98)
          Positioned.fill(
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ui.isDark
                        ? [
                            Colors.transparent,
                            const Color(0x99000000),
                            ui.bg,
                          ]
                        : [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                            ui.bg,
                          ],
                    stops: const [0.38, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: ColoredBox(
            color: ui.bg.withValues(alpha: t),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset,
          child: ColoredBox(
            color: SalonUiTheme.blueTop.withValues(alpha: t),
          ),
        ),
        Positioned(
          top: topInset + 8,
          left: 16,
          child: GestureDetector(
            onTap: onBack,
            child: Container(
              width: _InfluencerDetailsUi.backButtonSize,
              height: _InfluencerDetailsUi.backButtonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ui.buttonFillTop, ui.buttonFillBottom],
                ),
                shape: BoxShape.circle,
                border: ui.isDark
                    ? null
                    : Border.all(color: ui.cardBorder, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.arrowLeft,
                color: ui.buttonIcon,
                size: 22,
              ),
            ),
          ),
        ),
        if (rating > 0)
          Positioned(
            top: topInset + 8,
            right: 16,
            child: Opacity(
              opacity: (1 - t * 1.6).clamp(0.0, 1.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ui.sheetOverlayButton,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rating.toStringAsFixed(
                        rating == rating.roundToDouble() ? 0 : 1,
                      ),
                      style: TextStyle(
                        color: ui.isDark ? Colors.white : ui.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFC107),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: _InfluencerDetailsUi.horizontalPadding,
          right: _InfluencerDetailsUi.horizontalPadding,
          top: profileTop,
          child: _HeroProfileInfo(
            ui: ui,
            collapseT: t,
            pseudo: pseudo,
            zone: zone,
            phone: phone,
            email: email,
          ),
        ),
      ],
    );
  }

  Widget _heroPlaceholder(SalonUiTheme ui) {
    final placeholderColor =
        ui.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB);
    return Container(
      color: placeholderColor,
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.user,
        color: ui.textMuted,
        size: 72,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _InfluencerHeroHeaderDelegate oldDelegate) {
    return ui.brightness != oldDelegate.ui.brightness ||
        expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        imageUrl != oldDelegate.imageUrl ||
        pseudo != oldDelegate.pseudo ||
        zone != oldDelegate.zone ||
        phone != oldDelegate.phone ||
        email != oldDelegate.email ||
        rating != oldDelegate.rating;
  }
}

class _HeroProfileInfo extends StatelessWidget {
  const _HeroProfileInfo({
    required this.ui,
    required this.collapseT,
    required this.pseudo,
    required this.zone,
    required this.phone,
    required this.email,
  });

  final SalonUiTheme ui;
  final double collapseT;
  final String pseudo;
  final String zone;
  final String phone;
  final String email;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        Color.lerp(Colors.white, ui.textPrimary, collapseT)!;
    final secondaryColor = Color.lerp(
      Colors.white.withValues(alpha: 0.93),
      ui.textSecondary,
      collapseT,
    )!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '@$pseudo',
          style: TextStyle(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        if (zone.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            zone,
            style: TextStyle(
              color: secondaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            phone,
            style: TextStyle(
              color: primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            email,
            style: TextStyle(
              color: primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
