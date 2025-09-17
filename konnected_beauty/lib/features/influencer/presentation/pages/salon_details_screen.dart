import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_details/salon_details_bloc.dart';
import '../../../../core/bloc/salon_details/salon_details_event.dart';
import '../../../../core/bloc/salon_details/salon_details_state.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
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
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.textPrimaryColor,
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
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.textSecondaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.applyPoppins(const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            )),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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
              foregroundColor: AppTheme.textPrimaryColor,
            ),
            child: Text(
              'Retry',
              style: AppTheme.applyPoppins(const TextStyle(
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
                  style: AppTheme.applyPoppins(const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  )),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  "$description",
                  style: AppTheme.applyPoppins(const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                  )),
                ),
                const SizedBox(height: 24),

                // Services Section
                _buildServicesSection(services),
                const SizedBox(height: 24),

                // Invite for Campaign Button
                _buildInviteButton(),
                const SizedBox(height: 32),

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
                  color: AppTheme.textSecondaryColor,
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
                              color: AppTheme.textSecondaryColor,
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
                          color: AppTheme.textSecondaryColor,
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
            style: AppTheme.applyPoppins(const TextStyle(
              color: AppTheme.textSecondaryColor,
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
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.border2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  serviceName,
                  style: AppTheme.applyPoppins(const TextStyle(
                    color: AppTheme.textPrimaryColor,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement invite for campaign functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invite for campaign functionality coming soon!',
                style: AppTheme.applyPoppins(const TextStyle(
                  color: AppTheme.textPrimaryColor,
                )),
              ),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.textPrimaryColor,
          foregroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppTranslations.getString(context, 'invite_for_campaign'),
              style: AppTheme.applyPoppins(const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
            ),
            const SizedBox(width: 15),
            const Icon(
              LucideIcons.ticket,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(double averageRating, int totalRatings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'reviews'),
          style: AppTheme.applyPoppins(const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          )),
        ),
        const SizedBox(height: 12),
        if (totalRatings == 0)
          Text(
            AppTranslations.getString(context, 'no_reviews_yet'),
            style: AppTheme.applyPoppins(const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            )),
          )
        else
          Column(
            children: [
              // Mock review data - replace with real data when available
              _buildReviewItem(
                  'Influencer name', '4s ago', 'Very pro, i liked his work 💪'),
              const SizedBox(height: 12),
              _buildReviewItem('Another Influencer', '2h ago',
                  'Great service and professional staff!'),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewItem(
      String influencerName, String timeAgo, String reviewText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                influencerName,
                style: AppTheme.applyPoppins(const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
              ),
              Text(
                timeAgo,
                style: AppTheme.applyPoppins(const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reviewText,
            style: AppTheme.applyPoppins(const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            )),
          ),
        ],
      ),
    );
  }
}
