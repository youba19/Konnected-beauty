import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_details/salon_details_bloc.dart';
import '../../../../core/bloc/salon_details/salon_details_event.dart';
import '../../../../core/bloc/salon_details/salon_details_state.dart';
import '../../../../core/bloc/invite_salon/invite_salon_bloc.dart';
import '../../../../core/bloc/invite_salon/invite_salon_event.dart';
import '../../../../core/bloc/invite_salon/invite_salon_state.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class SalonDetailsScreen extends StatefulWidget {
  final String salonId;
  final String? salonName;
  final String? salonDomain;
  final String? salonAddress;

  const SalonDetailsScreen({
    super.key,
    required this.salonId,
    this.salonName,
    this.salonDomain,
    this.salonAddress,
  });

  @override
  State<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SalonDetailsBloc>().add(LoadSalonDetails(
          widget.salonId,
          salonName: widget.salonName,
          salonDomain: widget.salonDomain,
          salonAddress: widget.salonAddress,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.8,
                    colors: [
                      AppTheme.greenPrimary.withOpacity(0.35),
                      brightness == Brightness.dark
                          ? AppTheme.transparentBackground
                          : AppTheme.textWhite54,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Main content with padding for back button
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
            child: BlocBuilder<SalonDetailsBloc, SalonDetailsState>(
              builder: (context, state) {
                if (state is SalonDetailsLoading) {
                  return _buildLoadingState();
                } else if (state is SalonDetailsLoaded) {
                  return _buildLoadedState(state.salonDetails);
                } else if (state is SalonDetailsError) {
                  return _buildErrorState(state.message);
                } else {
                  return _buildLoadingState();
                }
              },
            ),
          ),
          // Custom back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back,
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return _buildShimmerContent();
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.applyPoppins(TextStyle(
              color:
                  AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
              fontSize: 16,
            )),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<SalonDetailsBloc>().add(LoadSalonDetails(
                    widget.salonId,
                    salonName: widget.salonName,
                    salonDomain: widget.salonDomain,
                    salonAddress: widget.salonAddress,
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            ),
            child: Text(
              'Retry',
              style: AppTheme.applyPoppins(TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(Map<String, dynamic> salonDetails) {
    final name = salonDetails['name'] ??
        AppTranslations.getString(context, 'saloon_name_default');
    final description = salonDetails['description'] ??
        AppTranslations.getString(context, 'salon_description_default');
    final pictures = salonDetails['pictures'] as List<dynamic>? ?? [];
    final services = salonDetails['services'] as List<dynamic>? ?? [];
    final averageRating = (salonDetails['averageRating'] ?? 0).toDouble();
    final totalRatings = salonDetails['totalRatings'] ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Gallery
          _buildImageGallery(pictures),

          // Salon Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salon Name
                Text(
                  name,
                  style: AppTheme.applyPoppins(TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppTheme.lightTextPrimaryColor
                        : AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  )),
                ),
                SizedBox(height: 8),

                // Description
                Text(
                  "$description",
                  style: AppTheme.applyPoppins(TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppTheme.lightTextPrimaryColor
                        : AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                    fontSize: 16,
                  )),
                ),
                SizedBox(height: 24),

                // Services Section
                _buildServicesSection(services),
                SizedBox(height: 24),

                // Invite for Campaign Button
                _buildInviteButton(),
                SizedBox(height: 32),

                // Reviews Section
                _buildReviewsSection(averageRating, totalRatings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<dynamic> pictures) {
    if (pictures.isEmpty) {
      // Show placeholder images if no pictures available
      return Container(
        height: 156,
        margin: const EdgeInsets.all(16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: 129,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.border2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: AppTheme.getTextSecondaryColor(
                      Theme.of(context).brightness),
                  size: 48,
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 156,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pictures.length,
        itemBuilder: (context, index) {
          final picture = pictures[index];
          final imageUrl = picture['url'] ?? picture['imageUrl'] ?? '';

          return Container(
            width: 129,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.border2,
                          child: Center(
                            child: Icon(
                              Icons.image,
                              color: AppTheme.getTextSecondaryColor(
                                  Theme.of(context).brightness),
                              size: 48,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.border2,
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: AppTheme.getTextSecondaryColor(
                              Theme.of(context).brightness),
                          size: 48,
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServicesSection(List<dynamic> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (services.isEmpty)
          Text(
            AppTranslations.getString(context, 'no_services_available'),
            style: AppTheme.applyPoppins(TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightTextSecondaryColor
                  : AppTheme.getTextSecondaryColor(
                      Theme.of(context).brightness),
              fontSize: 14,
            )),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((service) {
              final serviceName = service['name'] ??
                  AppTranslations.getString(context, 'service_name_default');
              final brightness = Theme.of(context).brightness;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: brightness == Brightness.light
                      ? AppTheme.lightBannerBackground
                      : AppTheme.border2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  serviceName,
                  style: AppTheme.applyPoppins(TextStyle(
                    color: brightness == Brightness.light
                        ? AppTheme.lightTextPrimaryColor
                        : AppTheme.getTextPrimaryColor(brightness),
                    fontSize: 14,
                  )),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInviteButton() {
    return BlocListener<InviteSalonBloc, InviteSalonState>(
      listener: (context, state) {
        if (state is InviteSalonSuccess) {
          TopNotificationService.showSuccess(
            context: context,
            message: AppTranslations.getString(
                context, 'invitation_sent_successfully'),
          );
        } else if (state is InviteSalonError) {
          TopNotificationService.showError(
            context: context,
            message: state.message,
          );
        }
      },
      child: BlocBuilder<InviteSalonBloc, InviteSalonState>(
        builder: (context, state) {
          final isLoading = state is InviteSalonLoading;

          final brightness = Theme.of(context).brightness;
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      _showInviteDialog();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: brightness == Brightness.light
                    ? AppTheme.lightTextPrimaryColor
                    : AppTheme.accentColor,
                foregroundColor: brightness == Brightness.light
                    ? AppTheme.accentColor
                    : AppTheme.lightTextPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: brightness == Brightness.light
                            ? AppTheme.accentColor
                            : AppTheme.lightTextPrimaryColor,
                      ),
                    )
                  else
                    Text(
                      AppTranslations.getString(context, 'invite_for_campaign'),
                      style: AppTheme.applyPoppins(TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: brightness == Brightness.light
                            ? AppTheme.accentColor
                            : AppTheme.lightTextPrimaryColor,
                      )),
                    ),
                  if (!isLoading) ...[
                    SizedBox(width: 15),
                    Icon(
                      LucideIcons.ticket,
                      size: 20,
                      color: brightness == Brightness.light
                          ? AppTheme.accentColor
                          : AppTheme.lightTextPrimaryColor,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection(double averageRating, int totalRatings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'reviews'),
          style: AppTheme.applyPoppins(TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          )),
        ),
        SizedBox(height: 12),
        if (totalRatings == 0)
          Text(
            AppTranslations.getString(context, 'no_reviews_yet'),
            style: AppTheme.applyPoppins(TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightTextSecondaryColor
                  : AppTheme.getTextSecondaryColor(
                      Theme.of(context).brightness),
              fontSize: 14,
            )),
          )
        else
          Column(
            children: [
              // Mock review data - replace with real data when available
              _buildReviewItem(
                  'Influencer name', '4s ago', 'Very pro, i liked his work 💪'),
              SizedBox(height: 12),
              _buildReviewItem('Another Influencer', '2h ago',
                  'Great service and professional staff!'),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewItem(
      String influencerName, String timeAgo, String reviewText) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brightness == Brightness.light
            ? AppTheme.lightCardBackground
            : AppTheme.getSecondaryColor(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: brightness == Brightness.light
              ? AppTheme.lightCardBorderColor
              : AppTheme.border2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                influencerName,
                style: AppTheme.applyPoppins(TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
              ),
              Text(
                timeAgo,
                style: AppTheme.applyPoppins(TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextSecondaryColor
                      : AppTheme.getTextSecondaryColor(
                          Theme.of(context).brightness),
                  fontSize: 12,
                )),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            reviewText,
            style: AppTheme.applyPoppins(TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightTextPrimaryColor
                  : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 14,
            )),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    final _formKey = GlobalKey<FormState>();
    final followersPromotionController = TextEditingController();
    bool isLoading = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Salon Invite',
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightCardBackground
                : AppTheme.primaryColor,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? AppTheme.lightCardBackground
                    : AppTheme.primaryColor,
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
                            context, 'salon_invite_title'),
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppTranslations.getString(
                            context, 'salon_invite_instructions'),
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 24),
                      // Followers promotion value
                      Text(
                        AppTranslations.getString(
                            context, 'followers_promotion_value'),
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: followersPromotionController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '00',
                          hintStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextSecondaryColor
                                    : AppTheme.textWhite70,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                                width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                                width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                                width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Builder(
                              builder: (context) => Center(
                                widthFactor: 1.0,
                                child: Text(
                                  '%',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? AppTheme.lightTextPrimaryColor
                                        : AppTheme.getTextPrimaryColor(
                                            Theme.of(context).brightness),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness)),
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
                      SizedBox(height: 16),
                      // Your Commission
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            AppTranslations.getString(
                                context, 'your_commission'),
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '8%',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Commission Kbeauty
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            AppTranslations.getString(
                                context, 'commission_kbeauty'),
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '3%',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      // Create Campaign & Invite Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  final promotion = int.tryParse(
                                          followersPromotionController.text) ??
                                      20;

                                  context
                                      .read<InviteSalonBloc>()
                                      .add(InviteSalon(
                                        receiverId: widget.salonId,
                                        promotion: promotion,
                                        promotionType: 'percentage',
                                        invitationMessage: '',
                                      ));

                                  Navigator.of(context).pop();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getScaffoldBackground(
                                        Theme.of(context).brightness),
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : AppTheme.lightTextPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.white
                                            : AppTheme.lightTextPrimaryColor),
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
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      LucideIcons.tag,
                                      size: 18,
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.white
                                          : AppTheme.lightTextPrimaryColor,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 12),
                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightCardBackground
                                    : AppTheme.transparentBackground,
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.getTextPrimaryColor(
                                        Theme.of(context).brightness),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppTranslations.getString(context, 'cancel'),
                            style: TextStyle(
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

  Widget _buildShimmerContent() {
    return Shimmer.fromColors(
      baseColor: AppTheme.getShimmerBase(Theme.of(context).brightness),
      highlightColor:
          AppTheme.getShimmerHighlight(Theme.of(context).brightness),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery Shimmer
            _buildShimmerImageGallery(),

            // Salon Information Shimmer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Salon Name Shimmer
                  _buildShimmerText(width: 200, height: 28),
                  SizedBox(height: 8),

                  // Description Shimmer
                  _buildShimmerText(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  _buildShimmerText(width: 250, height: 16),
                  SizedBox(height: 24),

                  // Services Section Shimmer
                  _buildShimmerServicesSection(),
                  SizedBox(height: 24),

                  // Invite Button Shimmer
                  _buildShimmerButton(),
                  SizedBox(height: 32),

                  // Reviews Section Shimmer
                  _buildShimmerReviewsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerImageGallery() {
    return Container(
      height: 156,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 129,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppTheme.shimmerBaseMediumDark,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Services title shimmer
        _buildShimmerText(width: 100, height: 20),
        SizedBox(height: 12),
        // Services chips shimmer
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(4, (index) {
            return Container(
              width: 80 + (index * 20).toDouble(),
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.shimmerBaseMediumDark,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildShimmerButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.shimmerBaseMediumDark,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildShimmerReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews title shimmer
        _buildShimmerText(width: 100, height: 24),
        SizedBox(height: 12),
        // Review items shimmer
        _buildShimmerReviewItem(),
        SizedBox(height: 12),
        _buildShimmerReviewItem(),
      ],
    );
  }

  Widget _buildShimmerReviewItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.shimmerBaseMediumDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerText(width: 120, height: 16),
              _buildShimmerText(width: 40, height: 12),
            ],
          ),
          SizedBox(height: 8),
          _buildShimmerText(width: double.infinity, height: 14),
          SizedBox(height: 4),
          _buildShimmerText(width: 200, height: 14),
        ],
      ),
    );
  }

  Widget _buildShimmerText({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.shimmerBaseMediumDark,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
