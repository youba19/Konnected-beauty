import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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

// Static set to track newly added links across navigation sessions
class _SessionTracker {
  static Set<String> newlyAddedLinks = {};

  static void addNewLink(String linkName) {
    newlyAddedLinks.add(linkName.toLowerCase());
  }

  static bool isNewlyAdded(String linkName) {
    return newlyAddedLinks.contains(linkName.toLowerCase());
  }

  static void removeNewLink(String linkName) {
    newlyAddedLinks.remove(linkName.toLowerCase());
  }

  static void clearAll() {
    newlyAddedLinks.clear();
  }
}

class _SocialInformationScreenState extends State<SocialInformationScreen> {
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  // Add link form controllers
  final TextEditingController _newLinkNameController = TextEditingController();
  final TextEditingController _newLinkUrlController = TextEditingController();

  // Social media data
  Map<String, String> _socialLinks = {};
  List<Map<String, String>> _dynamicSocialLinks = [];
  List<Map<String, String>> _newlyAddedLinks =
      []; // Track newly added links separately
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
                ? _buildShimmerContent()
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

  Widget _buildShimmerContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER - Now scrollable
            _buildHeader(),
            const SizedBox(height: 24),

            // Social media fields shimmer
            _buildShimmerSocialField(),
            const SizedBox(height: 20),

            _buildShimmerSocialField(),
            const SizedBox(height: 20),

            _buildShimmerSocialField(),
            const SizedBox(height: 20),

            _buildShimmerSocialField(),
            const SizedBox(height: 20),

            _buildShimmerSocialField(),
            const SizedBox(height: 20),

            // Add link button shimmer
            _buildShimmerAddButton(),
            const SizedBox(height: 20),

            // Extra padding at bottom for better scrolling
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSocialField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label shimmer
        Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),

        // Text field shimmer
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerAddButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
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
    Set<String> displayedLinks =
        {}; // Track displayed links to avoid duplicates

    print('🔍 Building fields - newly added links: ${_newlyAddedLinks.length}');
    print('🔍 Building fields - social links: ${_socialLinks.length}');

    // FIRST: Display all newly added links (these should always show with delete icons)
    for (int i = 0; i < _newlyAddedLinks.length; i++) {
      final newLink = _newlyAddedLinks[i];
      final name = newLink['name'] ?? '';
      final link = newLink['link'] ?? '';

      if (name.isNotEmpty && link.isNotEmpty) {
        displayedLinks.add(name.toLowerCase()); // Track this link as displayed

        // Use the link from _newlyAddedLinks to ensure we have the latest value
        // If the link was saved to API, use the API value
        String displayLink = _socialLinks[name.toLowerCase()] ?? link;

        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildUnifiedSocialMediaField(
                label: name.substring(0, 1).toUpperCase() + name.substring(1),
                controller: TextEditingController(text: displayLink),
                isNewlyAdded: true, // Always true for newly added links
                onDelete: () => _showDeleteConfirmation(i),
              ),
            ],
          ),
        );
      }
    }

    // SECOND: Display other links from API that haven't been displayed yet
    _socialLinks.forEach((name, link) {
      if (!['instagram', 'tiktok', 'youtube'].contains(name) &&
          !displayedLinks.contains(name.toLowerCase())) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildUnifiedSocialMediaField(
                label: name.substring(0, 1).toUpperCase() + name.substring(1),
                controller: TextEditingController(text: link),
                isNewlyAdded: false, // These are existing links from API only
                onDelete: null, // No delete for purely existing links
              ),
            ],
          ),
        );
      }
    });

    return widgets;
  }

  Widget _buildUnifiedSocialMediaField({
    required String label,
    required TextEditingController controller,
    required bool isNewlyAdded,
    VoidCallback? onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Text field with delete icon in the same row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter $label link',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    // Update the corresponding link in _socialLinks
                    if (!isNewlyAdded) {
                      _socialLinks[label.toLowerCase()] = value;
                    } else {
                      // Update in newly added links
                      final index = _newlyAddedLinks.indexWhere((newLink) =>
                          newLink['name']?.toLowerCase() ==
                          label.toLowerCase());
                      if (index != -1) {
                        _newlyAddedLinks[index]['link'] = value;
                      }
                    }
                  },
                ),
              ),
            ),
            // Show delete icon for newly added links in the same row
            if (isNewlyAdded && onDelete != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _addNewSocialLink(String name, String link) async {
    // Validate URL format
    if (!_isValidUrl(link)) {
      TopNotificationService.showError(
        context: context,
        message: 'Please enter a valid URL (e.g., https://example.com)',
      );
      return;
    }

    // Clear the form and close bottom sheet first
    _newLinkNameController.clear();
    _newLinkUrlController.clear();
    Navigator.of(context).pop();

    // Store context locally to avoid async gap issues
    final currentContext = context;

    try {
      setState(() {
        _isLoading = true;
      });

      // Prepare all existing links + new link for API
      final allSocials = _prepareAllSocialsForAPI();
      allSocials.add({
        'name': name,
        'link': link,
      });

      print('🔗 === ADDING NEW SOCIAL LINK ===');
      print('🔗 New link: $name -> $link');
      print('🔗 Total links to save: ${allSocials.length}');

      final result = await InfluencerAuthService.updateSocials(allSocials);

      if (result['success'] == true) {
        if (currentContext.mounted) {
          TopNotificationService.showSuccess(
            context: currentContext,
            message: 'Link added successfully!',
          );
        }

        // Add to newly added links for persistent delete icons
        setState(() {
          _newlyAddedLinks.add({
            'name': name,
            'link': link,
          });
        });

        // Mark this link as newly added in session tracker
        _SessionTracker.addNewLink(name);

        // Refresh data from API to ensure consistency
        await _loadSocialMediaData();
      } else {
        if (currentContext.mounted) {
          String errorMessage = 'Failed to add social media link';
          if (result['message'] != null) {
            if (result['message'] is List) {
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
          message: 'Error adding social media link: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation(int index) async {
    final linkToDelete = _newlyAddedLinks[index];
    final linkName = linkToDelete['name'] ?? 'this link';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Delete Link',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "$linkName"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteNewlyAddedLink(index);
    }
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

  Future<void> _deleteNewlyAddedLink(int index) async {
    final linkToDelete = _newlyAddedLinks[index];
    final linkName = linkToDelete['name'] ?? '';

    // Store context locally to avoid async gap issues
    final currentContext = context;

    try {
      setState(() {
        _isLoading = true;
      });

      // Prepare all existing links except the one to delete
      final allSocials = _prepareAllSocialsForAPI();

      // Remove the link we want to delete from the list
      allSocials.removeWhere(
          (social) => social['name']?.toLowerCase() == linkName.toLowerCase());

      print('🗑️ === DELETING NEWLY ADDED LINK ===');
      print('🗑️ Deleting link: $linkName');
      print('🗑️ Remaining links: ${allSocials.length}');

      final result = await InfluencerAuthService.updateSocials(allSocials);

      if (result['success'] == true) {
        if (currentContext.mounted) {
          TopNotificationService.showSuccess(
            context: currentContext,
            message: 'Link deleted successfully!',
          );
        }

        // Remove from newly added links list
        setState(() {
          _newlyAddedLinks.removeAt(index);
        });

        // Refresh data from API to ensure consistency
        await _loadSocialMediaData();
      } else {
        if (currentContext.mounted) {
          String errorMessage = 'Failed to delete social media link';
          if (result['message'] != null) {
            if (result['message'] is List) {
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
          message: 'Error deleting social media link: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    // Don't clear _newlyAddedLinks here - they need to keep their "new" status
    // until user interacts with them or saves changes

    // Extract social media links from the API response
    for (var social in socialsData) {
      String name = social['name']?.toLowerCase() ?? '';
      String link = social['link'] ?? '';

      if (name.isNotEmpty && link.isNotEmpty) {
        // Check if it's one of the standard platforms
        if (['instagram', 'tiktok', 'youtube'].contains(name)) {
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
    _tiktokController.text = _socialLinks['tiktok'] ?? '';
    _youtubeController.text = _socialLinks['youtube'] ?? '';

    // Rebuild _newlyAddedLinks from session tracker
    _newlyAddedLinks.clear();
    for (var social in socialsData) {
      String name = social['name']?.toLowerCase() ?? '';
      String link = social['link'] ?? '';

      if (name.isNotEmpty &&
          link.isNotEmpty &&
          _SessionTracker.isNewlyAdded(name)) {
        _newlyAddedLinks.add({
          'name': name,
          'link': link,
        });
      }
    }

    print('🔄 Rebuilt newly added links: ${_newlyAddedLinks.length}');
    for (var link in _newlyAddedLinks) {
      print('🔄 - ${link['name']}: ${link['link']}');
    }
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

    // Add newly added links as well when saving all changes
    allSocials.addAll(_newlyAddedLinks);

    return allSocials;
  }

  List<Map<String, String>> _prepareAllSocialsForAPISaveOnly() {
    List<Map<String, String>> allSocials = [];

    // Add standard social media platforms if they have content
    if (_instagramController.text.isNotEmpty) {
      allSocials.add({
        'name': 'instagram',
        'link': _instagramController.text.trim(),
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

    // Add other social media platforms from fetched data (exclude newly added ones)
    _socialLinks.forEach((name, link) {
      if (!['instagram', 'tiktok', 'youtube'].contains(name) &&
          link.isNotEmpty) {
        // Only add if it's not in the newly added links list
        bool isNewlyAdded = _newlyAddedLinks.any(
            (newLink) => newLink['name']?.toLowerCase() == name.toLowerCase());

        if (!isNewlyAdded) {
          allSocials.add({
            'name': name,
            'link': link.trim(),
          });
        }
      }
    });

    // Don't add dynamic social media links or newly added links here
    // as they should be saved separately when added

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

      // Prepare all links (existing + newly added)
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

      print('💾 === SAVING CHANGES - ALL LINKS (EXISTING + NEW) ===');
      print('💾 Saving ${allSocials.length} total links');
      print('💾 Newly added links: ${_newlyAddedLinks.length}');

      final result = await InfluencerAuthService.updateSocials(allSocials);

      if (result['success'] == true) {
        if (currentContext.mounted) {
          TopNotificationService.showSuccess(
            context: currentContext,
            message:
                result['message'] ?? 'Social media links updated successfully',
          );
        }

        // Clear only dynamic links, keep newly added links for persistent delete icons
        setState(() {
          _dynamicSocialLinks.clear();
          // DON'T clear _newlyAddedLinks - keep them to maintain delete icons
        });

        print(
            '🔍 After save, newly added links count: ${_newlyAddedLinks.length}');
        for (int i = 0; i < _newlyAddedLinks.length; i++) {
          print('🔍 Newly added link $i: ${_newlyAddedLinks[i]}');
        }

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

    // Validate newly added social media links
    for (int i = 0; i < _newlyAddedLinks.length; i++) {
      final link = _newlyAddedLinks[i]['link'] ?? '';
      if (link.isNotEmpty && !_isValidUrl(link)) {
        final name = _newlyAddedLinks[i]['name'] ?? 'New Link ${i + 1}';
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
