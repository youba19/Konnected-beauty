import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'edit_service_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String servicePrice;
  final String serviceDescription;
  final bool showSuccessMessage;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDescription,
    this.showSuccessMessage = false,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  _ServiceDetailsScreenState();

  @override
  void initState() {
    super.initState();
    // Always load services on app start
    context.read<SalonServicesBloc>().add(LoadSalonServices());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalonServicesBloc, SalonServicesState>(
      listener: (context, state) {
        if (state is SalonServiceDeleted) {
          // Show success message as top-dropping dialog with service name
          TopNotificationService.showSuccess(
            context: context,
            message:
                '${AppTranslations.getString(context, 'service_deleted')} - ${widget.serviceName}',
          );

          // Navigate back to home screen
          Navigator.of(context).pop();
        } else if (state is SalonServiceUpdated) {
          // Show success message for service update
          TopNotificationService.showSuccess(
            context: context,
            message: AppTranslations.getString(context, 'service_updated'),
          );

          // Trigger a rebuild to show updated data
          setState(() {});
        } else if (state is SalonServicesError) {
          // Show error message
          TopNotificationService.showError(
            context: context,
            message: state.message,
          );
        }
      },
      child: Container(
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    AppTranslations.getString(context, 'service_details'),
                    style: AppTheme.headingStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Message (if needed)
                        if (widget.showSuccessMessage) ...[
                          _buildSuccessMessage(),
                          const SizedBox(height: 24),
                        ],

                        // Service Information
                        _buildServiceInformation(),

                        const SizedBox(height: 40),

                        // Action Buttons
                        _buildActionButtons(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 10.0, bottom: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.textPrimaryColor,
              size: 32,
            ),
            onPressed: () {
              // Navigate back to previous screen
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppTranslations.getString(
                  context, 'service_created_successfully'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInformation() {
    return BlocBuilder<SalonServicesBloc, SalonServicesState>(
      builder: (context, state) {
        // Get current service data from bloc state
        String currentName = widget.serviceName;
        String currentPrice = widget.servicePrice;
        String currentDescription = widget.serviceDescription;
        List<dynamic> servicePictures = [];

        if (state is SalonServicesLoaded) {
          // Find the updated service in the loaded services
          final updatedService = state.services.firstWhere(
            (service) => service['id'] == widget.serviceId,
            orElse: () => {
              'name': widget.serviceName,
              'price': widget.servicePrice,
              'description': widget.serviceDescription,
            },
          );

          currentName = updatedService['name'] ?? widget.serviceName;
          currentPrice =
              updatedService['price']?.toString() ?? widget.servicePrice;
          currentDescription =
              updatedService['description'] ?? widget.serviceDescription;
          servicePictures = updatedService['pictures'] as List<dynamic>? ?? [];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Pictures
            if (servicePictures.isNotEmpty) ...[
              _buildServicePictures(servicePictures),
              const SizedBox(height: 24),
            ],

            // Service Name
            Text(
              currentName,
              style: AppTheme.headingStyle.copyWith(fontSize: 24),
            ),

            const SizedBox(height: 8),

            // Service Price
            Text(
              '$currentPrice EURO (TTC)',
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Service Description
            Text(
              currentDescription,
              style: AppTheme.subtitleStyle.copyWith(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServicePictures(List<dynamic> pictures) {
    // Extract image URLs
    final imageUrls = pictures
        .map((pic) => (pic['url'] ?? pic['imageUrl'] ?? '').toString())
        .where((url) => url.isNotEmpty)
        .toList();

    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // If only one image, show it without carousel
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrls[0],
          width: double.infinity,
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
        ),
      );
    }

    // Multiple images: show carousel with indicators
    return SizedBox(
      height: 252,
      child: _ServicePicturesCarousel(imageUrls: imageUrls),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Edit Button
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                print('🆔 === NAVIGATING FROM SERVICE DETAILS TO EDIT ===');
                print('🆔 Service ID: ${widget.serviceId}');
                print('📝 Service Name: ${widget.serviceName}');
                print('💰 Service Price: ${widget.servicePrice}');
                print('📄 Service Description: ${widget.serviceDescription}');

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<SalonServicesBloc>(),
                      child: EditServiceScreen(
                        serviceId: widget.serviceId,
                        serviceName: widget.serviceName,
                        servicePrice: widget.servicePrice,
                        serviceDescription: widget.serviceDescription,
                      ),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppTheme.textPrimaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppTheme.textPrimaryColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                AppTranslations.getString(context, 'edit'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Delete Button
        Expanded(
          child: BlocBuilder<SalonServicesBloc, SalonServicesState>(
            builder: (context, state) {
              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: state is SalonServiceDeleting
                      ? null
                      : () {
                          _showDeleteConfirmation();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                  ),
                  child: state is SalonServiceDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Text(
                          AppTranslations.getString(context, 'delete'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            AppTranslations.getString(context, 'delete_service'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${AppTranslations.getString(context, 'delete_service_confirmation')} "${widget.serviceName}"?',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppTranslations.getString(context, 'cancel'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Delete the service using the API
                context.read<SalonServicesBloc>().add(DeleteSalonService(
                      serviceId: widget.serviceId,
                      serviceName: widget.serviceName,
                    ));
              },
              child: Text(
                AppTranslations.getString(context, 'delete'),
                style: const TextStyle(
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

// Image carousel widget with page indicators for service pictures
class _ServicePicturesCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _ServicePicturesCarousel({
    required this.imageUrls,
  });

  @override
  State<_ServicePicturesCarousel> createState() =>
      _ServicePicturesCarouselState();
}

class _ServicePicturesCarouselState extends State<_ServicePicturesCarousel> {
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
    return Stack(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrls[index],
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
                ),
              ),
            );
          },
        ),
        // Page indicators overlay at the bottom of the image
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: _buildPageIndicators(widget.imageUrls.length),
        ),
      ],
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
