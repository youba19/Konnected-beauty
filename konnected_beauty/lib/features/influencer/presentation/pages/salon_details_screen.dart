import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_details/salon_details_bloc.dart';
import '../../../../core/bloc/salon_details/salon_details_event.dart';
import '../../../../core/bloc/salon_details/salon_details_state.dart';
import '../../../../core/bloc/invite_salon/invite_salon_bloc.dart';
import '../../../../core/bloc/invite_salon/invite_salon_event.dart';
import '../../../../core/bloc/invite_salon/invite_salon_state.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'influencer_service_details_screen.dart';

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
              child: Icon(
                Icons.arrow_back,
                color:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                size: 24,
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
    final address = salonDetails['address'] ??
        AppTranslations.getString(context, 'unknown_address');
    final website = salonDetails['website'] as String?;
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

                // Address (under salon name, with green icon)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: AppTheme.greenPrimary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: AppTheme.applyPoppins(TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness),
                          fontSize: 15,
                        )),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Website and Invite buttons in same row
                _buildWebsiteAndInviteButtons(website),
                SizedBox(height: 24),

                // Bio Title
                Text(
                  AppTranslations.getString(context, 'bio'),
                  style: AppTheme.applyPoppins(TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppTheme.lightTextPrimaryColor
                        : AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                    fontSize: 24,
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
                    fontSize: 14,
                  )),
                ),
                SizedBox(height: 24),

                // Services Title
                Text(
                  AppTranslations.getString(context, 'services'),
                  style: AppTheme.applyPoppins(TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppTheme.lightTextPrimaryColor
                        : AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  )),
                ),
                SizedBox(height: 12),

                // Services Section
                _buildServicesSection(services),
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
      // Show placeholder if no pictures available
      return Container(
        height: 252,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
    }

    // Extract image URLs
    final imageUrls = pictures
        .map((pic) => (pic['url'] ?? pic['imageUrl'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .toList();

    if (imageUrls.isEmpty) {
      return Container(
        height: 252,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
    }

    // Use carousel widget with indicators
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: _SalonDetailsImageCarousel(
        imageUrls: imageUrls,
      ),
    );
  }

  Widget _buildWebsiteAndInviteButtons(String? website) {
    final brightness = Theme.of(context).brightness;

    return Row(
      children: [
        // Website Button
        if (website != null && website.isNotEmpty)
          Expanded(
            child: _buildWebsiteButton(website, brightness),
          ),
        if (website != null && website.isNotEmpty) SizedBox(width: 12),
        // Invite Button
        Expanded(
          child: _buildInviteButton(),
        ),
      ],
    );
  }

  Widget _buildWebsiteButton(String website, Brightness brightness) {
    // Ensure website URL has protocol
    String websiteUrl = website;
    if (!websiteUrl.startsWith('http://') &&
        !websiteUrl.startsWith('https://')) {
      websiteUrl = 'https://$websiteUrl';
    }

    return ElevatedButton(
      onPressed: () async {
        try {
          final uri = Uri.parse(websiteUrl);
          print('🔗 Attempting to open website: $websiteUrl');

          bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            print('✅ Website opened successfully');
          } else {
            // If external application mode fails, try platform default
            print(
                '⚠️ External application mode failed, trying platform default');
            bool launchedDefault = await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );

            if (!launchedDefault) {
              print('❌ Failed to launch website, copying to clipboard');
              await Clipboard.setData(ClipboardData(text: websiteUrl));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Website URL copied to clipboard',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
          }
        } catch (e) {
          print('❌ Error opening website: $e');
          // Fallback: copy to clipboard
          try {
            await Clipboard.setData(ClipboardData(text: websiteUrl));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Website URL copied to clipboard',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (clipboardError) {
            print('❌ Error copying to clipboard: $clipboardError');
          }
        }
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
          Flexible(
            child: Text(
              'Website',
              style: AppTheme.applyPoppins(TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: brightness == Brightness.light
                    ? AppTheme.accentColor
                    : AppTheme.lightTextPrimaryColor,
              )),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            LucideIcons.globe,
            size: 18,
            color: brightness == Brightness.light
                ? AppTheme.accentColor
                : AppTheme.lightTextPrimaryColor,
          ),
        ],
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
          Column(
            children: services.map((service) {
              return _buildServiceItem(service);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final serviceName = service['name'] ??
        AppTranslations.getString(context, 'service_name_default');
    final servicePrice = service['price'] ?? 0;

    // Extract image from pictures array (first picture if available)
    final servicePictures = service['pictures'] as List<dynamic>? ?? [];
    String serviceImage = '';
    if (servicePictures.isNotEmpty) {
      final firstPicture = servicePictures[0] as Map<String, dynamic>?;
      serviceImage = firstPicture?['url'] ?? firstPicture?['imageUrl'] ?? '';
    }

    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: () {
        // Navigate to service details screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InfluencerServiceDetailsScreen(
              service: service,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 129,
                height: 78,
                color: brightness == Brightness.light
                    ? AppTheme.lightBannerBackground
                    : AppTheme.border2,
                child: serviceImage.toString().isNotEmpty
                    ? Image.network(
                        serviceImage.toString(),
                        width: 129,
                        height: 78,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 129,
                            height: 78,
                            color: brightness == Brightness.light
                                ? AppTheme.lightBannerBackground
                                : AppTheme.border2,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppTheme.getTextSecondaryColor(brightness),
                              size: 32,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 129,
                            height: 78,
                            color: brightness == Brightness.light
                                ? AppTheme.lightBannerBackground
                                : AppTheme.border2,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.image_outlined,
                        color: AppTheme.getTextSecondaryColor(brightness),
                        size: 32,
                      ),
              ),
            ),
            SizedBox(width: 12),
            // Service Name and Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Service Name
                  Text(
                    serviceName,
                    style: AppTheme.applyPoppins(TextStyle(
                      color: brightness == Brightness.light
                          ? AppTheme.lightTextPrimaryColor
                          : AppTheme.getTextPrimaryColor(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                  SizedBox(height: 4),
                  // Service Price
                  Text(
                    '${servicePrice.toStringAsFixed(2)} EUR (TTC)',
                    style: AppTheme.applyPoppins(TextStyle(
                      color: brightness == Brightness.light
                          ? AppTheme.lightTextPrimaryColor
                          : AppTheme.getTextPrimaryColor(brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          return Expanded(
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
                    Flexible(
                      child: Text(
                        AppTranslations.getString(
                            context, 'invite_for_campaign'),
                        style: AppTheme.applyPoppins(TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: brightness == Brightness.light
                              ? AppTheme.accentColor
                              : AppTheme.lightTextPrimaryColor,
                        )),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (!isLoading) ...[
                    SizedBox(width: 8),
                    Icon(
                      LucideIcons.ticket,
                      size: 18,
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
    final messageController = TextEditingController();

    // Hide keyboard when dialog opens
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;

            return GestureDetector(
              onTap: () {
                // Hide keyboard when tapping outside
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightCardBackground
                      : AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          AppTranslations.getString(context, 'create_campaign'),
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Description
                        Text(
                          AppTranslations.getString(
                              context, 'create_campaign_description'),
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextSecondaryColor
                                    : Colors.white,
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
                              color: Theme.of(context).brightness ==
                                      Brightness.light
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
                              color: Theme.of(context).brightness ==
                                      Brightness.light
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
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.lightTextPrimaryColor
                                      : Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '%',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? AppTheme.lightTextPrimaryColor
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              AppTranslations.getString(
                                  context, 'your_commission'),
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
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
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Commission Konnected
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.lightTextPrimaryColor
                                      : Colors.white,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '%',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? AppTheme.lightTextPrimaryColor
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              AppTranslations.getString(
                                  context, 'commission_konnected'),
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Text(
                              '5%',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        // Message to saloon
                        Text(
                          AppTranslations.getString(
                              context, 'message_to_salon'),
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: AppTranslations.getString(
                                context, 'message_placeholder_salon'),
                            hintStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.lightTextSecondaryColor
                                  : Colors.white70,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.lightTextPrimaryColor
                                      : Colors.white,
                                  width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.lightTextPrimaryColor
                                      : Colors.white,
                                  width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? AppTheme.lightTextPrimaryColor
                                      : Colors.white,
                                  width: 1),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : Colors.white),
                        ),
                        SizedBox(height: 8),
                        // Info text
                        Text(
                          AppTranslations.getString(
                              context, 'single_message_allowed'),
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextSecondaryColor
                                    : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 24),
                        // Create Campaign & Invite Button
                        Builder(
                          builder: (context) {
                            final brightness = Theme.of(context).brightness;
                            final isLightMode = brightness == Brightness.light;
                            return SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }

                                        setState(() {
                                          isLoading = true;
                                        });

                                        final promotion = int.tryParse(
                                                followersPromotionController
                                                    .text) ??
                                            20;
                                        final message =
                                            messageController.text.trim();

                                        context
                                            .read<InviteSalonBloc>()
                                            .add(InviteSalon(
                                              receiverId: widget.salonId,
                                              promotion: promotion,
                                              promotionType: 'percentage',
                                              invitationMessage: message,
                                            ));

                                        Navigator.of(context).pop();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isLightMode ? Colors.black : Colors.white,
                                  foregroundColor:
                                      isLightMode ? Colors.white : Colors.black,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  isLightMode
                                                      ? Colors.white
                                                      : Colors.black),
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
                                          Icon(
                                            LucideIcons.tag,
                                            size: 18,
                                            color: isLightMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 12),
                        // Cancel Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? AppTheme.lightCardBackground
                                  : AppTheme.transparentBackground,
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.light
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
            );
          },
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

// Image carousel widget with page indicators for salon details
class _SalonDetailsImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _SalonDetailsImageCarousel({
    required this.imageUrls,
  });

  @override
  State<_SalonDetailsImageCarousel> createState() =>
      _SalonDetailsImageCarouselState();
}

class _SalonDetailsImageCarouselState
    extends State<_SalonDetailsImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth =
        screenWidth - 16; // Screen width - margin (8px left + 8px right)

    return SizedBox(
      height: 252,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.imageUrls.length - 1 ? 12 : 0,
                ),
                child: SizedBox(
                  width: imageWidth,
                  child: _buildCarouselImage(widget.imageUrls[index], index),
                ),
              );
            },
          ),
          // Page indicators overlay at the bottom of the image
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: _buildPageIndicators(widget.imageUrls.length),
            ),
        ],
      ),
    );
  }

  Widget _buildCarouselImage(String imageUrl, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 252,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 252,
                  color: AppTheme.border2,
                  child: Icon(
                    Icons.image,
                    color: AppTheme.getTextSecondaryColor(
                        Theme.of(context).brightness),
                    size: 40,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 252,
                  color: AppTheme.border2,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppTheme.accentColor,
                    ),
                  ),
                );
              },
            )
          : Container(
              height: 252,
              color: AppTheme.border2,
              child: Icon(
                Icons.image,
                color: AppTheme.getTextSecondaryColor(
                    Theme.of(context).brightness),
                size: 40,
              ),
            ),
    );
  }

  Widget _buildPageIndicators(int totalPages) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentPage == index ? 8 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: _currentPage == index
                ? AppTheme.greenPrimary
                : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
