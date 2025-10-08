import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_info/salon_info_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_dropdown.dart';
import 'image_preview_screen.dart';

class SalonInformationScreen extends StatefulWidget {
  const SalonInformationScreen({super.key});

  @override
  State<SalonInformationScreen> createState() => _SalonInformationScreenState();
}

class _SalonInformationScreenState extends State<SalonInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salonNameController = TextEditingController();
  final _salonAddressController = TextEditingController();
  final _activityDomainController = TextEditingController();
  final _openingHourController = TextEditingController();
  final _closingHourController = TextEditingController();
  final _salonDescriptionController = TextEditingController();

  // Picture handling
  final List<File> _uploadedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingImages = false;

  // Existing pictures from profile API
  List<File> _existingPictureFiles = []; // Store as File objects
  List<Map<String, dynamic>> _existingPictureData =
      []; // Store metadata (id, url)
  bool _isLoadingPictures = false; // Track picture conversion loading state

  // Time options for dropdowns
  final List<String> _timeOptions = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00',
    '22:30',
    '23:00',
    '23:30',
  ];

  // Picture handling methods

  // Convert picture data from API to File objects immediately
  Future<void> _convertPicturesToFiles(List<dynamic> pictures) async {
    print('🔄 === CONVERTING PICTURES TO FILES ===');
    print('🔄 Converting ${pictures.length} pictures to File objects');

    // Show loading state
    setState(() {
      _isLoadingPictures = true;
    });

    List<File> downloadedFiles = [];
    List<Map<String, dynamic>> pictureData = [];

    for (int i = 0; i < pictures.length; i++) {
      try {
        final picture = pictures[i] as Map<String, dynamic>;
        final url = picture['url'] as String?;
        final id = picture['id'] as String?;

        if (url != null && url.isNotEmpty) {
          print('🔄 Converting picture $i: $url');

          // Download the image
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            // Create a temporary file with proper extension
            final tempDir = await getTemporaryDirectory();

            // Extract file extension from URL
            String extension = 'jpg';
            if (url.contains('.')) {
              final urlParts = url.split('.');
              final possibleExtension = urlParts.last.toLowerCase();
              if (['jpg', 'jpeg', 'png', 'gif', 'webp']
                  .contains(possibleExtension)) {
                extension = possibleExtension;
              }
            }

            // Create a cleaner filename for storage
            String cleanName = 'salon_image_${i + 1}';
            if (url.contains('/')) {
              final originalName = url.split('/').last.split('?').first;
              if (originalName.isNotEmpty &&
                  !originalName.contains('existing_')) {
                cleanName = originalName.split('.').first;
              }
            }

            final fileName =
                '${cleanName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
            final tempFile = File('${tempDir.path}/$fileName');

            // Write the downloaded bytes to file
            await tempFile.writeAsBytes(response.bodyBytes);
            downloadedFiles.add(tempFile);

            // Store metadata
            pictureData.add({
              'id': id ?? '',
              'url': url,
              'file': tempFile,
            });

            print('🔄 ✅ Converted: ${tempFile.path}');
          } else {
            print('🔄 ❌ Failed to download $url: ${response.statusCode}');
          }
        }
      } catch (e) {
        print('🔄 ❌ Error converting picture $i: $e');
      }
    }

    // Update state with new File objects and hide loading
    setState(() {
      _existingPictureFiles = downloadedFiles;
      _existingPictureData = pictureData;
      _isLoadingPictures = false; // Hide loading state
    });

    print('🔄 === CONVERSION COMPLETE ===');
    print('🔄 Converted ${_existingPictureFiles.length} pictures to files');
    print('🔄 Stored ${_existingPictureData.length} metadata entries');
  }

  // Convert existing picture URLs to File objects (legacy method - no longer used)
  Future<List<File>> _downloadExistingPictures() async {
    List<File> downloadedFiles = [];

    print('📥 === DOWNLOADING EXISTING PICTURES (LEGACY) ===');
    print('📥 Converting ${_existingPictureData.length} URLs to files');

    for (int i = 0; i < _existingPictureData.length; i++) {
      try {
        final picture = _existingPictureData[i];
        final url = picture['url'] as String?;

        if (url != null && url.isNotEmpty) {
          print('📥 Downloading image $i: $url');

          // Download the image
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            // Create a temporary file with proper extension
            final tempDir = await getTemporaryDirectory();

            // Extract file extension from URL or use jpg as fallback
            String extension = 'jpg';
            if (url.contains('.')) {
              final urlParts = url.split('.');
              final possibleExtension = urlParts.last.toLowerCase();
              if (['jpg', 'jpeg', 'png', 'gif', 'webp']
                  .contains(possibleExtension)) {
                extension = possibleExtension;
              }
            }

            final fileName =
                'existing_image_${i}_${DateTime.now().millisecondsSinceEpoch}.$extension';
            final tempFile = File('${tempDir.path}/$fileName');

            // Write the downloaded bytes to file
            await tempFile.writeAsBytes(response.bodyBytes);
            downloadedFiles.add(tempFile);

            print('📥 ✅ Downloaded and saved: ${tempFile.path}');
          } else {
            print('📥 ❌ Failed to download $url: ${response.statusCode}');
          }
        }
      } catch (e) {
        print('📥 ❌ Error downloading image $i: $e');
      }
    }

    print('📥 === DOWNLOAD COMPLETE ===');
    print('📥 Successfully downloaded: ${downloadedFiles.length} files');

    return downloadedFiles;
  }

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isLoadingImages = true;
      });

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _uploadedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
        print('📸 Images picked: ${_uploadedImages.length}');
      }
    } catch (e) {
      print('❌ Error picking images: $e');
      TopNotificationService.showError(
        context: context,
        message: 'Failed to pick images: $e',
      );
    } finally {
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
    print('🗑️ Image removed at index $index');
  }

  void _clearAllImages() {
    setState(() {
      _uploadedImages.clear();
    });
    print('🗑️ All uploaded images cleared');
  }

  void _clearExistingPictures() {
    setState(() {
      _existingPictureFiles.clear();
      _existingPictureData.clear();
    });
    print('🗑️ All existing pictures cleared');
  }

  void _clearAllPictures() {
    setState(() {
      _uploadedImages.clear();
      _existingPictureFiles.clear();
      _existingPictureData.clear();
    });
    print('🗑️ All pictures cleared');
  }

  void _removeExistingPicture(int index) {
    setState(() {
      _existingPictureFiles.removeAt(index);
      _existingPictureData.removeAt(index);
    });
    print('🗑️ Existing picture removed at index $index');
  }

  void _refreshImageLists() {
    print('🔄 === REFRESHING IMAGE LISTS ===');
    print('🔄 Current existing picture files: ${_existingPictureFiles.length}');
    print('🔄 Current uploaded images: ${_uploadedImages.length}');

    setState(() {
      _existingPictureFiles.clear();
      _existingPictureData.clear();
      _uploadedImages.clear();
    });
    print('🔄 Image lists cleared for refresh');

    // Add a small delay to ensure server has processed the update
    Future.delayed(const Duration(milliseconds: 500), () {
      print('🔄 Delayed refresh triggered - reloading data from API');
      // Force reload of data to get the latest images
      context.read<SalonInfoBloc>().add(LoadAllSalonData());
    });
  }

  void _previewImages(int initialIndex) {
    // Combine all images (existing + new) for preview
    List<File> allImages = [];
    allImages.addAll(_existingPictureFiles);
    allImages.addAll(_uploadedImages);

    if (allImages.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(
            images: allImages,
            initialIndex: initialIndex,
            imageData: _existingPictureData,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Load existing salon information from both APIs
    context.read<SalonInfoBloc>().add(LoadAllSalonData());
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _salonAddressController.dispose();
    _activityDomainController.dispose();
    _openingHourController.dispose();
    _closingHourController.dispose();
    _salonDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _populateControllers(Map<String, dynamic> salonInfo,
      Map<String, dynamic>? salonProfile) async {
    // Populate controllers with data from both APIs
    print('🎨 === POPULATING FORM FIELDS ===');

    // Salon Info API: /salon/salon-info
    print('🏷️  Setting Salon Name: ${salonInfo['name'] ?? 'N/A'}');
    print('📍 Setting Salon Address: ${salonInfo['address'] ?? 'N/A'}');
    print('🏢 Setting Activity Domain: ${salonInfo['domain'] ?? 'N/A'}');

    _salonNameController.text = salonInfo['name'] ?? '';
    _salonAddressController.text = salonInfo['address'] ?? '';
    _activityDomainController.text = salonInfo['domain'] ?? '';

    // Salon Profile API: /salon/salon-profile
    if (salonProfile != null) {
      print('⏰ Setting Opening Hour: ${salonProfile['openingHour'] ?? 'N/A'}');
      print('⏰ Setting Closing Hour: ${salonProfile['closingHour'] ?? 'N/A'}');
      print('📝 Setting Description: ${salonProfile['description'] ?? 'N/A'}');
      print('🖼️ Setting Pictures: ${salonProfile['pictures'] ?? 'N/A'}');

      // Handle opening hour (convert from "09:00:00" to "09:00")
      final openingHour = salonProfile['openingHour'] ?? '';
      if (openingHour.isNotEmpty && openingHour.length >= 5) {
        _openingHourController.text = openingHour.substring(0, 5);
      }

      // Handle closing hour (convert from "11:00:00" to "11:00")
      final closingHour = salonProfile['closingHour'] ?? '';
      if (closingHour.isNotEmpty && closingHour.length >= 5) {
        _closingHourController.text = closingHour.substring(0, 5);
      }

      _salonDescriptionController.text = salonProfile['description'] ?? '';

      // Handle existing pictures from profile API - only populate if lists are empty
      // This preserves user's current image management
      if (_existingPictureFiles.isEmpty && _uploadedImages.isEmpty) {
        final pictures = salonProfile['pictures'] as List<dynamic>?;
        if (pictures != null && pictures.isNotEmpty) {
          print(
              '🖼️ Populating empty lists with ${pictures.length} existing pictures from profile');
          print('🖼️ Picture data: $pictures');

          // Convert pictures to File objects immediately
          await _convertPicturesToFiles(pictures);
        } else {
          print('⚠️  No existing pictures found in profile');
        }
      } else {
        print(
            '🖼️ Preserving current image lists - not overwriting with API data');
        print(
            '🖼️ Current existing picture files: ${_existingPictureFiles.length}');
        print('🖼️ Current uploaded images: ${_uploadedImages.length}');
      }
    } else {
      print('⚠️  No salon profile data available');
    }

    print('🎨 === FORM FIELDS POPULATED ===');
  }

  // Shimmer loading widgets
  Widget _buildShimmerTextField() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
      ),
    );
  }

  Widget _buildShimmerDropdown() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16),
              height: 16,
              width: 100,
              color: const Color(0xFF3A3A3A),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF3A3A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerImageSection() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          Container(
            height: 16,
            width: 120,
            color: const Color(0xFF3A3A3A),
          ),
          const SizedBox(height: 16),
          // Image count shimmer
          Container(
            height: 14,
            width: 60,
            color: const Color(0xFF3A3A3A),
          ),
          const SizedBox(height: 8),
          // Image list shimmer
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPictureLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Salon Pictures',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Loading message with shimmer count
        Shimmer.fromColors(
          baseColor: const Color(0xFF2A2A2A),
          highlightColor: const Color(0xFF3A3A3A),
          child: Container(
            height: 14,
            width: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Converting pictures shimmer with animation
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Show more shimmer items during loading
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: const Color(0xFF2A2A2A),
                highlightColor: const Color(0xFF3A3A3A),
                child: Container(
                  width: 120,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4A4A4A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A5A5A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 8,
                        width: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A5A5A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Progress text shimmer
        Row(
          children: [
            const Icon(
              Icons.download,
              color: Color(0xFF3A3A3A),
              size: 16,
            ),
            const SizedBox(width: 8),
            Shimmer.fromColors(
              baseColor: const Color(0xFF2A2A2A),
              highlightColor: const Color(0xFF3A3A3A),
              child: Container(
                height: 12,
                width: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerButton() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSalonPicturesShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3, // Show 3 shimmer items
          itemBuilder: (context, index) {
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  // Image shimmer
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Picture name shimmer
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer (back button)
          Shimmer.fromColors(
            baseColor: const Color(0xFF2A2A2A),
            highlightColor: const Color(0xFF3A3A3A),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Form fields shimmer
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salon Name
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 16,
                width: 100,
                color: const Color(0xFF3A3A3A),
              ),
              _buildShimmerTextField(),
              const SizedBox(height: 16),

              // Salon Address
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 16,
                width: 120,
                color: const Color(0xFF3A3A3A),
              ),
              _buildShimmerTextField(),
              const SizedBox(height: 16),

              // Activity Domain
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 16,
                width: 110,
                color: const Color(0xFF3A3A3A),
              ),
              _buildShimmerTextField(),
              const SizedBox(height: 16),

              // Opening Hour
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 16,
                width: 100,
                color: const Color(0xFF3A3A3A),
              ),
              _buildShimmerDropdown(),
              const SizedBox(height: 16),

              // Closing Hour
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 16,
                width: 100,
                color: const Color(0xFF3A3A3A),
              ),
              _buildShimmerDropdown(),
              const SizedBox(height: 16),

              // Description
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 16,
                width: 80,
                color: const Color(0xFF3A3A3A),
              ),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
              ),
              const SizedBox(height: 24),

              // Images section
              _buildShimmerImageSection(),
              const SizedBox(height: 40),

              // Save button
              _buildShimmerButton(),
              const SizedBox(height: 66),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: BlocConsumer<SalonInfoBloc, SalonInfoState>(
            listener: (context, state) {
              if (state is SalonInfoLoaded) {
                // Schedule the async operation
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await _populateControllers(
                      state.salonInfo, state.salonProfile);
                });
              } else if (state is SalonInfoUpdated) {
                // Show one summary notification for all updates
                TopNotificationService.showSuccess(
                  context: context,
                  message: "Salon information updated successfully",
                );
                _refreshImageLists(); // Refresh image lists after successful update

                // Navigate back to settings screen after successful update
                Navigator.of(context).pop();
              } else if (state is SalonProfileUpdated) {
                // Don't show notification for profile update - already shown for info update
                print(
                    '✅ Profile update completed - notification already shown');
                _refreshImageLists(); // Refresh image lists after successful update
              } else if (state is SalonInfoError) {
                TopNotificationService.showError(
                  context: context,
                  message: state.error,
                );
              }
            },
            builder: (context, state) {
              if (state is SalonInfoLoading) {
                return _buildShimmerContent();
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSalonInformationSection(),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(
        LucideIcons.arrowLeft,
        color: AppTheme.textPrimaryColor,
        size: 24,
      ),
    );
  }

  Widget _buildSalonInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Salon Information Section (3rd step)
        Row(
          children: [
            const Icon(
              LucideIcons.store,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppTranslations.getString(context, 'salon_information'),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Salon Name
        CustomTextField(
          label: AppTranslations.getString(context, 'salon_name'),
          placeholder:
              AppTranslations.getString(context, 'salon_name_placeholder'),
          controller: _salonNameController,
        ),
        const SizedBox(height: 20),

        // Salon Address
        CustomTextField(
          label: AppTranslations.getString(context, 'salon_address'),
          placeholder:
              AppTranslations.getString(context, 'salon_address_placeholder'),
          controller: _salonAddressController,
          keyboardType: TextInputType.streetAddress,
        ),
        const SizedBox(height: 20),

        // Activity Domain
        CustomTextField(
          label: AppTranslations.getString(context, 'activity_domain'),
          placeholder:
              AppTranslations.getString(context, 'activity_domain_placeholder'),
          controller: _activityDomainController,
        ),
        const SizedBox(height: 20),

        // Salon Profile Section (4th step)

        // Saloon Pictures Section

        _buildSalonPicturesSection(),

        const SizedBox(height: 24),

        // Hours Section
        Row(
          children: [
            Expanded(
              child: CustomDropdown(
                label: AppTranslations.getString(context, 'opening_hour'),
                placeholder: AppTranslations.getString(context, 'select'),
                items: _timeOptions,
                selectedValue: _openingHourController.text.isNotEmpty
                    ? _openingHourController.text
                    : null,
                compact: true,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _openingHourController.text = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDropdown(
                label: AppTranslations.getString(context, 'closing_hour'),
                placeholder: AppTranslations.getString(context, 'select'),
                items: _timeOptions,
                selectedValue: _closingHourController.text.isNotEmpty
                    ? _closingHourController.text
                    : null,
                compact: true,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _closingHourController.text = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Description Section
        CustomTextField(
          label: AppTranslations.getString(context, 'salon_description'),
          placeholder:
              AppTranslations.getString(context, 'describe_salon_placeholder'),
          controller: _salonDescriptionController,
          maxLines: 4,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<SalonInfoBloc, SalonInfoState>(
      builder: (context, state) {
        final isLoading =
            state is SalonInfoUpdating || state is SalonProfileUpdating;

        return Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveSalonInformation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : Text(
                    AppTranslations.getString(context, 'save_edits'),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _saveSalonInformation() async {
    // Validate inputs
    if (_salonNameController.text.trim().isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'salon_name_required'),
      );
      return;
    }

    if (_salonAddressController.text.trim().isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'salon_address_required'),
      );
      return;
    }

    if (_activityDomainController.text.trim().isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'activity_domain_required'),
      );
      return;
    }

    // Validate profile data
    if (_openingHourController.text.trim().isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Opening hour is required',
      );
      return;
    }

    if (_closingHourController.text.trim().isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Closing hour is required',
      );
      return;
    }

    // Validate total images in list (existing + new)
    final totalImages = _existingPictureFiles.length + _uploadedImages.length;
    if (totalImages < 3) {
      TopNotificationService.showError(
        context: context,
        message: 'Please have at least 3 images total (minimum required)',
      );
      return;
    }

    if (totalImages > 10) {
      TopNotificationService.showError(
        context: context,
        message: 'Please have maximum 10 images total',
      );
      return;
    }

    print('💾 === SAVING SALON INFORMATION ===');
    print('🏷️  Name: ${_salonNameController.text.trim()}');
    print('📍 Address: ${_salonAddressController.text.trim()}');
    print('🏢 Domain: ${_activityDomainController.text.trim()}');
    print('⏰ Opening Hour: ${_openingHourController.text.trim()}');
    print('⏰ Closing Hour: ${_closingHourController.text.trim()}');
    print('📝 Description: ${_salonDescriptionController.text.trim()}');
    print('🖼️ Images Count: ${_uploadedImages.length}');

    // Update salon info (name, address, domain)
    context.read<SalonInfoBloc>().add(UpdateSalonInfo(
          name: _salonNameController.text.trim(),
          address: _salonAddressController.text.trim(),
          domain: _activityDomainController.text.trim(),
        ));

    // Update salon profile (opening hours, description, pictures)
    print('🖼️ === UPDATING SALON PROFILE WITH ALL FILES ===');
    print('🖼️ New uploaded images: ${_uploadedImages.length}');
    print(
        '🖼️ Existing picture files (already converted): ${_existingPictureFiles.length}');

    // Combine existing files + new uploaded files (both are already File objects)
    List<File> allFiles = [];
    allFiles.addAll(_existingPictureFiles); // Add existing File objects
    allFiles.addAll(_uploadedImages); // Add new uploaded images

    print('🖼️ === FINAL FILE COUNT ===');
    print('🖼️ Existing files: ${_existingPictureFiles.length}');
    print('🖼️ New uploaded files: ${_uploadedImages.length}');
    print('🖼️ Total files to send: ${allFiles.length}');

    // Log all files being sent
    for (int i = 0; i < allFiles.length; i++) {
      print('🖼️ File $i: ${allFiles[i].path}');
    }

    context.read<SalonInfoBloc>().add(UpdateSalonProfile(
          openingHour: '${_openingHourController.text.trim()}:00',
          closingHour: '${_closingHourController.text.trim()}:00',
          description: _salonDescriptionController.text.trim(),
          pictureFiles: allFiles.isNotEmpty ? allFiles : null,
        ));
  }

  Widget _buildSalonPicturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          AppTranslations.getString(context, 'salon_pictures'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        // Upload Area
        GestureDetector(
          onTap: _isLoadingImages ? null : _pickImages,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: _isLoadingImages
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      AppTranslations.getString(
                          context, 'upload_salon_pictures'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Show shimmer when loading pictures, otherwise show pictures grid
        if (_isLoadingPictures) ...[
          _buildSalonPicturesShimmer(),
        ] else if (_existingPictureFiles.isNotEmpty ||
            _uploadedImages.isNotEmpty) ...[
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingPictureFiles.length + _uploadedImages.length,
              itemBuilder: (context, index) {
                // Determine if this is an existing picture or new image
                if (index < _existingPictureFiles.length) {
                  // Existing picture
                  final pictureData = _existingPictureData[index];
                  String imageName = 'PictureName';

                  // Extract meaningful name from original URL
                  final originalUrl = pictureData['url'] as String?;
                  if (originalUrl != null && originalUrl.isNotEmpty) {
                    final urlParts = originalUrl.split('/');
                    if (urlParts.isNotEmpty) {
                      final fileName = urlParts.last;
                      final cleanName = fileName.split('?').first;
                      if (cleanName.isNotEmpty &&
                          !cleanName.startsWith('existing_')) {
                        imageName = cleanName;
                      }
                    }
                  }

                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        // Image
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _previewImages(index),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _existingPictureFiles[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFF2A2A2A),
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.white54,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Picture Name and Delete Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  imageName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeExistingPicture(index),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // New uploaded image
                  final newImageIndex = index - _existingPictureFiles.length;
                  final imageFile = _uploadedImages[newImageIndex];

                  String imageName = 'PictureName';
                  final fileName = imageFile.path.split('/').last;
                  if (fileName.contains('image_picker_')) {
                    final extension = fileName.split('.').last;
                    imageName = 'Image ${newImageIndex + 1}.$extension';
                  } else if (fileName.isNotEmpty) {
                    imageName = fileName;
                  }

                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        // Image
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _previewImages(index),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  imageFile,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFF2A2A2A),
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.white54,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Picture Name and Delete Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  imageName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeImage(newImageIndex),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
