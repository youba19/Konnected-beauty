import 'package:flutter/material.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../core/services/api/influencer_auth_service.dart';

class SocialInformationScreen extends StatefulWidget {
  const SocialInformationScreen({super.key});

  @override
  State<SocialInformationScreen> createState() =>
      _SocialInformationScreenState();
}

class _SocialInformationScreenState extends State<SocialInformationScreen> {
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _snapchatController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  // Add link form controllers
  final TextEditingController _newLinkNameController = TextEditingController();
  final TextEditingController _newLinkUrlController = TextEditingController();

  // Social media data
  Map<String, String> _socialLinks = {};
  List<Map<String, String>> _dynamicSocialLinks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load social media data directly
    _loadSocialMediaData();
  }

  @override
  void dispose() {
    _instagramController.dispose();
    _snapchatController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    _newLinkNameController.dispose();
    _newLinkUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -90,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
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

          // CONTENT
          SafeArea(
            child: _isLoading
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER - Now scrollable
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Loading content
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER - Now scrollable
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Social media content
                        _buildContent(),

                        // Extra padding at bottom for better scrolling
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          // Title with @ symbol
          Row(
            children: [
              const Text(
                '@ ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  AppTranslations.getString(context, 'your_socials') ??
                      'Yours socials',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instagram
        _buildSocialMediaField(
          label: AppTranslations.getString(context, 'instagram') ?? 'Instagram',
          controller: _instagramController,
        ),
        const SizedBox(height: 20),

        // Snapchat
        _buildSocialMediaField(
          label: AppTranslations.getString(context, 'snapchat') ?? 'Snapchat',
          controller: _snapchatController,
        ),
        const SizedBox(height: 20),

        // TikTok
        _buildSocialMediaField(
          label: AppTranslations.getString(context, 'tiktok') ?? 'TikTok',
          controller: _tiktokController,
        ),
        const SizedBox(height: 20),

        // YouTube
        _buildSocialMediaField(
          label: AppTranslations.getString(context, 'youtube') ?? 'YouTube',
          controller: _youtubeController,
        ),

        // Display all other social media platforms from API (including newly added ones)
        ..._buildAllOtherSocialMediaFields(),

        // Show newly added links with delete buttons
        if (_dynamicSocialLinks.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildNewlyAddedLinksSection(),
        ],

        // Add some extra spacing to ensure scrolling works properly
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSocialMediaField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              hintText: 'Enter link',
              hintStyle: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAllOtherSocialMediaFields() {
    List<Widget> widgets = [];

    // Get all social media links that are not the standard 4 platforms
    _socialLinks.forEach((name, link) {
      if (!['instagram', 'snapchat', 'tiktok', 'youtube'].contains(name)) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSocialMediaField(
                label: name.substring(0, 1).toUpperCase() + name.substring(1),
                controller: TextEditingController(text: link),
              ),
            ],
          ),
        );
      }
    });

    return widgets;
  }

  Widget _buildNewlyAddedLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Newly Added Links',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_dynamicSocialLinks.length, (index) {
          final socialLink = _dynamicSocialLinks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildNewlyAddedLinkField(
              label: socialLink['name'] ?? '',
              link: socialLink['link'] ?? '',
              onDelete: () => _deleteSocialLink(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNewlyAddedLinkField({
    required String label,
    required String link,
    required VoidCallback onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Static platform name (not editable)
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: TextField(
                  controller: TextEditingController(text: link),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                    hintText: 'Enter link',
                    hintStyle: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                  onChanged: (newValue) {
                    // Update the link value in the dynamic social links list
                    final index = _dynamicSocialLinks.indexWhere(
                      (item) => item['name'] == label && item['link'] == link,
                    );
                    if (index != -1) {
                      setState(() {
                        _dynamicSocialLinks[index]['link'] = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _deleteSocialLink(int index) {
    setState(() {
      _dynamicSocialLinks.removeAt(index);
    });

    TopNotificationService.showInfo(
      context: context,
      message: 'Link removed from list',
    );
  }

  Future<void> _loadSocialMediaData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await InfluencerAuthService.getSocials();

      if (result['success'] == true && result['data'] != null) {
        _populateSocialMediaControllers(result['data']);
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to load social media data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateSocialMediaControllers(List<dynamic> socialsData) {
    // Clear existing data
    _socialLinks.clear();
    _dynamicSocialLinks.clear();

    // Extract social media links from the API response
    for (var social in socialsData) {
      String name = social['name']?.toLowerCase() ?? '';
      String link = social['link'] ?? '';

      if (name.isNotEmpty && link.isNotEmpty) {
        // Check if it's one of the standard platforms
        if (['instagram', 'snapchat', 'tiktok', 'youtube'].contains(name)) {
          _socialLinks[name] = link;
        } else {
          // For any other platform, add it to the main social media section
          // This includes newly added links that were saved to the API
          _socialLinks[name] = link;
        }
      }
    }

    // Populate controllers with actual data or empty strings
    _instagramController.text = _socialLinks['instagram'] ?? '';
    _snapchatController.text = _socialLinks['snapchat'] ?? '';
    _tiktokController.text = _socialLinks['tiktok'] ?? '';
    _youtubeController.text = _socialLinks['youtube'] ?? '';
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSocialMediaData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Social Media Links Section
        _buildSocialMediaSection(),
        const SizedBox(height: 32),
        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  void _addNewSocialLink(String name, String link) {
    // Validate URL format
    if (!_isValidUrl(link)) {
      TopNotificationService.showError(
        context: context,
        message: 'Please enter a valid URL (e.g., https://example.com)',
      );
      return;
    }

    // Add to local list temporarily (will be cleared after API save)
    setState(() {
      _dynamicSocialLinks.add({
        'name': name,
        'link': link,
      });
    });

    // Clear the form
    _newLinkNameController.clear();
    _newLinkUrlController.clear();

    // Close the bottom sheet
    Navigator.of(context).pop();

    // Show success message
    TopNotificationService.showSuccess(
      context: context,
      message:
          'Link added to list! Click "Save changes" to save to your profile.',
    );
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;

    // Add protocol if missing
    String urlToCheck = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      urlToCheck = 'https://$url';
    }

    try {
      final uri = Uri.parse(urlToCheck);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, String>> _prepareAllSocialsForAPI() {
    List<Map<String, String>> allSocials = [];

    // Add standard social media platforms if they have content
    if (_instagramController.text.isNotEmpty) {
      allSocials.add({
        'name': 'instagram',
        'link': _instagramController.text.trim(),
      });
    }

    if (_snapchatController.text.isNotEmpty) {
      allSocials.add({
        'name': 'snapchat',
        'link': _snapchatController.text.trim(),
      });
    }

    if (_tiktokController.text.isNotEmpty) {
      allSocials.add({
        'name': 'tiktok',
        'link': _tiktokController.text.trim(),
      });
    }

    if (_youtubeController.text.isNotEmpty) {
      allSocials.add({
        'name': 'youtube',
        'link': _youtubeController.text.trim(),
      });
    }

    // Add dynamic social media links (these will be sent to API and then displayed in main list)
    allSocials.addAll(_dynamicSocialLinks);

    return allSocials;
  }

  Future<void> _saveAllChanges() async {
    // Store context locally to avoid async gap issues
    final currentContext = context;

    try {
      setState(() {
        _isLoading = true;
      });

      // Validate all URLs before sending to API
      final validationError = _validateAllSocials();
      if (validationError != null) {
        if (currentContext.mounted) {
          TopNotificationService.showError(
            context: currentContext,
            message: validationError,
          );
        }
        return;
      }

      final allSocials = _prepareAllSocialsForAPI();

      if (allSocials.isEmpty) {
        if (currentContext.mounted) {
          TopNotificationService.showError(
            context: currentContext,
            message: 'Please add at least one social media link',
          );
        }
        return;
      }

      final result = await InfluencerAuthService.updateSocials(allSocials);

      if (result['success'] == true) {
        if (currentContext.mounted) {
          TopNotificationService.showSuccess(
            context: currentContext,
            message:
                result['message'] ?? 'Social media links updated successfully',
          );
        }

        // Clear local dynamic links since they're now saved to API
        setState(() {
          _dynamicSocialLinks.clear();
        });

        // Refresh the data from API to ensure consistency
        await _loadSocialMediaData();
      } else {
        if (currentContext.mounted) {
          // Handle API validation errors more specifically
          String errorMessage = 'Failed to update social media links';
          if (result['message'] != null) {
            if (result['message'] is List) {
              // Handle array of validation errors
              final messages = result['message'] as List;
              errorMessage = messages.join(', ');
            } else {
              errorMessage = result['message'].toString();
            }
          }

          TopNotificationService.showError(
            context: currentContext,
            message: errorMessage,
          );
        }
      }
    } catch (e) {
      if (currentContext.mounted) {
        TopNotificationService.showError(
          context: currentContext,
          message: 'Error updating social media links: ${e.toString()}',
        );
      }
    } finally {
      if (currentContext.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateAllSocials() {
    // Validate standard social media fields
    if (_instagramController.text.isNotEmpty &&
        !_isValidUrl(_instagramController.text)) {
      return 'Instagram link must be a valid URL';
    }
    if (_snapchatController.text.isNotEmpty &&
        !_isValidUrl(_snapchatController.text)) {
      return 'Snapchat link must be a valid URL';
    }
    if (_tiktokController.text.isNotEmpty &&
        !_isValidUrl(_tiktokController.text)) {
      return 'TikTok link must be a valid URL';
    }
    if (_youtubeController.text.isNotEmpty &&
        !_isValidUrl(_youtubeController.text)) {
      return 'YouTube link must be a valid URL';
    }

    // Validate dynamic social media links
    for (int i = 0; i < _dynamicSocialLinks.length; i++) {
      final link = _dynamicSocialLinks[i]['link'] ?? '';
      if (link.isNotEmpty && !_isValidUrl(link)) {
        final name = _dynamicSocialLinks[i]['name'] ?? 'Link ${i + 1}';
        return '$name link must be a valid URL';
      }
    }

    return null; // All valid
  }

  void _showAddLinkBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => _buildAddLinkBottomSheet(),
    );
  }

  Widget _buildAddLinkBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                AppTranslations.getString(context, 'add_link') ?? 'Add link',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Link Name Field
              _buildAddLinkField(
                label: AppTranslations.getString(context, 'link_name') ??
                    'Link name',
                controller: _newLinkNameController,
                placeholder: AppTranslations.getString(
                        context, 'link_name_placeholder') ??
                    'Link name',
              ),
              const SizedBox(height: 20),

              // Link URL Field
              _buildAddLinkField(
                label: AppTranslations.getString(context, 'link') ?? 'Link',
                controller: _newLinkUrlController,
                placeholder:
                    AppTranslations.getString(context, 'link_placeholder') ??
                        'www.....',
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _newLinkNameController.clear();
                          _newLinkUrlController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side:
                                const BorderSide(color: Colors.white, width: 1),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppTranslations.getString(context, 'cancel') ??
                              'Cancel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Add Link Button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle adding the new link
                          if (_newLinkNameController.text.isNotEmpty &&
                              _newLinkUrlController.text.isNotEmpty) {
                            _addNewSocialLink(
                              _newLinkNameController.text.trim(),
                              _newLinkUrlController.text.trim(),
                            );
                          } else {
                            TopNotificationService.showError(
                              context: context,
                              message: 'Please fill in both fields',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppTranslations.getString(context, 'add_link') ??
                              'Add link',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddLinkField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Changes Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAllChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoading
                  ? Colors.grey.withOpacity(0.3)
                  : AppTheme.transparentBackground,
              foregroundColor: _isLoading ? Colors.grey : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Colors.white, // White border
                  width: 1, // Border thickness
                ),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppTranslations.getString(context, 'save_changes') ??
                            'Save changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.edit, // Modification icon
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Add Link Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              _showAddLinkBottomSheet();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.transparentBackground,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white, width: 1),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppTranslations.getString(context, 'add_link') ?? 'Add link',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
