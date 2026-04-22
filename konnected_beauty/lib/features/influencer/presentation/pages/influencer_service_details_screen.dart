import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';

class InfluencerServiceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> service;

  const InfluencerServiceDetailsScreen({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = service['name'] ??
        AppTranslations.getString(context, 'service_name_default');
    final servicePrice = service['price'] ?? 0;
    final serviceDescription = service['description'] ?? '';

    // Extract all images from pictures array
    final servicePictures = service['pictures'] as List<dynamic>? ?? [];
    final imageUrls = servicePictures
        .map((pic) {
          final picMap = pic as Map<String, dynamic>?;
          return picMap?['url'] ?? picMap?['imageUrl'] ?? '';
        })
        .where((url) => url.toString().isNotEmpty)
        .map((url) => url.toString())
        .toList();

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
          // Main content
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppTheme.getTextPrimaryColor(brightness),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Service Images Carousel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ServiceImageCarousel(
                      imageUrls: imageUrls,
                      brightness: brightness,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Service Information
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Name
                        Text(
                          serviceName,
                          style: AppTheme.applyPoppins(TextStyle(
                            color: brightness == Brightness.light
                                ? AppTheme.lightTextPrimaryColor
                                : AppTheme.getTextPrimaryColor(brightness),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                        const SizedBox(height: 12),
                        // Service Price
                        Text(
                          '${servicePrice.toStringAsFixed(2)} EUR (TTC)',
                          style: AppTheme.applyPoppins(TextStyle(
                            color: brightness == Brightness.light
                                ? AppTheme.lightTextPrimaryColor
                                : AppTheme.getTextPrimaryColor(brightness),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          )),
                        ),
                        const SizedBox(height: 24),
                        // Service Description
                        if (serviceDescription.isNotEmpty)
                          Text(
                            serviceDescription,
                            style: AppTheme.applyPoppins(TextStyle(
                              color: brightness == Brightness.light
                                  ? AppTheme.lightTextPrimaryColor
                                  : AppTheme.getTextPrimaryColor(brightness),
                              fontSize: 16,
                              height: 1.6,
                            )),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Image carousel widget with page indicators for service details
class _ServiceImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final Brightness brightness;

  const _ServiceImageCarousel({
    required this.imageUrls,
    required this.brightness,
  });

  @override
  State<_ServiceImageCarousel> createState() => _ServiceImageCarouselState();
}

class _ServiceImageCarouselState extends State<_ServiceImageCarousel> {
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
        screenWidth - 32; // Screen width - padding (16px left + 16px right)

    // If no images, show placeholder
    if (widget.imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 252,
          color: widget.brightness == Brightness.light
              ? AppTheme.lightBannerBackground
              : AppTheme.border2,
          child: Icon(
            Icons.image_outlined,
            color: AppTheme.getTextSecondaryColor(widget.brightness),
            size: 48,
          ),
        ),
      );
    }

    // If only one image, show it without indicators
    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 252,
          child: _buildCarouselImage(widget.imageUrls[0], 0),
        ),
      );
    }

    // Multiple images: show carousel with indicators
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
      child: Container(
        width: double.infinity,
        height: 252,
        color: widget.brightness == Brightness.light
            ? AppTheme.lightBannerBackground
            : AppTheme.border2,
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 252,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 252,
              color: widget.brightness == Brightness.light
                  ? AppTheme.lightBannerBackground
                  : AppTheme.border2,
              child: Icon(
                Icons.image_outlined,
                color: AppTheme.getTextSecondaryColor(widget.brightness),
                size: 48,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 252,
              color: widget.brightness == Brightness.light
                  ? AppTheme.lightBannerBackground
                  : AppTheme.border2,
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
