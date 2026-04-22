import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class EditServiceScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String servicePrice;
  final String serviceDescription;

  const EditServiceScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDescription,
  });

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController servicePriceController = TextEditingController();
  final TextEditingController serviceDescriptionController =
      TextEditingController();
  final GlobalKey<FormFieldState> serviceNameFormKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> servicePriceFormKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> serviceDescriptionFormKey =
      GlobalKey<FormFieldState>();

  // Picture handling
  final List<File> _selectedPictures = []; // New pictures to upload
  final List<String> _existingPictureUrls =
      []; // Existing pictures from server (URLs)
  final Map<String, File> _existingPictureFilesMap =
      {}; // Map URL -> File for existing pictures
  final List<String> _removedPictureUrls =
      []; // Existing pictures marked for removal
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingPictures = false;
  bool _isDownloadingExistingPictures = false;
  bool _hasDownloadedExistingPictures =
      false; // Track if we've already downloaded

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing service data
    serviceNameController.text = widget.serviceName;
    servicePriceController.text = widget.servicePrice.replaceAll(' €', '');
    serviceDescriptionController.text = widget.serviceDescription;

    // Load existing pictures from bloc
    _loadExistingPictures();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload pictures when screen becomes visible again (e.g., after update)
    // Reset download flag to allow re-downloading if data changed
    if (_hasDownloadedExistingPictures) {
      // Check if we need to reload (e.g., after coming back from update)
      final state = context.read<SalonServicesBloc>().state;
      if (state is SalonServicesLoaded) {
        final service = state.services.firstWhere(
          (s) => s['id'] == widget.serviceId,
          orElse: () => {},
        );
        if (service.isNotEmpty) {
          final pictures = service['pictures'] as List<dynamic>? ?? [];
          final currentUrls = pictures
              .map((pic) => (pic['url'] ?? pic['imageUrl'] ?? '').toString())
              .where((url) => url.isNotEmpty)
              .toList();

          // If URLs changed, reset and reload
          if (currentUrls.length != _existingPictureUrls.length ||
              !currentUrls.every((url) => _existingPictureUrls.contains(url))) {
            setState(() {
              _hasDownloadedExistingPictures = false;
              _existingPictureUrls.clear();
              _existingPictureFilesMap.clear();
              _removedPictureUrls.clear();
            });
            _loadExistingPictures();
          }
        }
      }
    }
  }

  void _loadExistingPictures() {
    final state = context.read<SalonServicesBloc>().state;
    if (state is SalonServicesLoaded) {
      final service = state.services.firstWhere(
        (s) => s['id'] == widget.serviceId,
        orElse: () => {},
      );

      if (service.isNotEmpty) {
        final pictures = service['pictures'] as List<dynamic>? ?? [];
        setState(() {
          _existingPictureUrls.clear();
          for (var pic in pictures) {
            final url = pic['url'] ?? pic['imageUrl'] ?? '';
            if (url.toString().isNotEmpty) {
              _existingPictureUrls.add(url.toString());
            }
          }
        });

        // Download existing pictures as files to preserve them (only once)
        if (_existingPictureUrls.isNotEmpty &&
            !_hasDownloadedExistingPictures) {
          _downloadExistingPictures();
        }
      }
    }
  }

  Future<void> _downloadExistingPictures() async {
    if (_isDownloadingExistingPictures || _hasDownloadedExistingPictures) {
      print('📥 Skipping download - already downloaded or in progress');
      return;
    }

    setState(() {
      _isDownloadingExistingPictures = true;
      _existingPictureFilesMap.clear();
    });

    print('📥 === DOWNLOADING EXISTING PICTURES ===');
    print('📥 Converting ${_existingPictureUrls.length} URLs to files');

    final Map<String, File> downloadedFilesMap = {};

    for (int i = 0; i < _existingPictureUrls.length; i++) {
      try {
        final url = _existingPictureUrls[i];

        // Skip if this picture was marked for removal
        if (_removedPictureUrls.contains(url)) {
          print('📥 Skipping removed picture: $url');
          continue;
        }

        print('📥 Downloading image $i: $url');

        // Download the image
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          // Create a temporary file with proper extension
          final tempDir = await getTemporaryDirectory();

          // Extract file extension from URL
          String extension = 'jpg';
          if (url.contains('.')) {
            final urlParts = url.split('.');
            final possibleExtension =
                urlParts.last.toLowerCase().split('?').first;
            if (['jpg', 'jpeg', 'png', 'gif', 'webp']
                .contains(possibleExtension)) {
              extension = possibleExtension;
            }
          }

          // Create a cleaner filename for storage
          String cleanName = 'service_image_${i + 1}';
          if (url.contains('/')) {
            final originalName = url.split('/').last.split('?').first;
            if (originalName.isNotEmpty) {
              cleanName = originalName.split('.').first;
            }
          }

          final fileName =
              '${cleanName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
          final tempFile = File('${tempDir.path}/$fileName');

          // Write the downloaded bytes to file
          await tempFile.writeAsBytes(response.bodyBytes);
          downloadedFilesMap[url] = tempFile; // Store with URL as key

          print('📥 ✅ Converted: ${tempFile.path}');
        } else {
          print('📥 ❌ Failed to download $url: ${response.statusCode}');
        }
      } catch (e) {
        print('📥 ❌ Error converting picture $i: $e');
      }
    }

    setState(() {
      _existingPictureFilesMap.clear();
      _existingPictureFilesMap.addAll(downloadedFilesMap);
      _isDownloadingExistingPictures = false;
      _hasDownloadedExistingPictures = true; // Mark as downloaded
    });

    print('📥 === DOWNLOAD COMPLETE ===');
    print('📥 Converted ${_existingPictureFilesMap.length} pictures to files');
  }

  @override
  void dispose() {
    serviceNameController.dispose();
    servicePriceController.dispose();
    serviceDescriptionController.dispose();
    super.dispose();
  }

  void _updateService() {
    print('🆔 === EDITING SERVICE ===');
    print('🆔 Service ID: ${widget.serviceId}');
    print('📝 Service Name: ${serviceNameController.text}');
    print('💰 Service Price: ${servicePriceController.text}');
    print('📄 Service Description: ${serviceDescriptionController.text}');

    // Validate fields
    serviceNameFormKey.currentState?.validate();
    servicePriceFormKey.currentState?.validate();
    serviceDescriptionFormKey.currentState?.validate();

    // Check if all fields are valid
    if (serviceNameController.text.isNotEmpty &&
        servicePriceController.text.isNotEmpty &&
        serviceDescriptionController.text.isNotEmpty) {
      // Parse price to integer
      final price = int.tryParse(servicePriceController.text);
      if (price == null) {
        // Show error for invalid price
        TopNotificationService.showError(
          context: context,
          message: 'Please enter a valid price',
        );
        return;
      }

      // Combine existing pictures (downloaded as files) + new pictures
      // Filter out removed pictures from existing files
      List<File> allPictures = [];

      // Add existing pictures that are NOT removed
      for (var url in _existingPictureUrls) {
        if (!_removedPictureUrls.contains(url) &&
            _existingPictureFilesMap.containsKey(url)) {
          allPictures.add(_existingPictureFilesMap[url]!);
        }
      }

      // Add new uploaded pictures
      allPictures.addAll(_selectedPictures);

      print('📸 === PICTURES TO SEND ===');
      print('📸 Existing picture URLs: ${_existingPictureUrls.length}');
      print(
          '📸 Existing picture files (not removed): ${allPictures.length - _selectedPictures.length}');
      print('📸 New pictures: ${_selectedPictures.length}');
      print('📸 Total pictures to send: ${allPictures.length}');
      print('📸 Removed pictures: ${_removedPictureUrls.length}');

      // Only send pictures if there are any (existing + new)
      // If no pictures at all, don't send pictures parameter
      List<File>? picturesToSend = allPictures.isNotEmpty ? allPictures : null;

      // Update service using API
      context.read<SalonServicesBloc>().add(UpdateSalonService(
            serviceId: widget.serviceId,
            name: serviceNameController.text,
            price: price,
            description: serviceDescriptionController.text,
            pictures: picturesToSend,
          ));
    }
  }

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isLoadingPictures = true;
      });

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedPictures
              .addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
        print('📸 Images picked: ${_selectedPictures.length}');
      }
    } catch (e) {
      print('❌ Error picking images: $e');
      TopNotificationService.showError(
        context: context,
        message: 'Failed to pick images: $e',
      );
    } finally {
      setState(() {
        _isLoadingPictures = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedPictures.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    final urlToRemove = _existingPictureUrls[index];
    setState(() {
      _removedPictureUrls.add(urlToRemove);
      _existingPictureUrls.removeAt(index);
      // Also remove from the map using URL as key
      _existingPictureFilesMap.remove(urlToRemove);
    });
    print('🗑️ Removed existing image at index $index');
    print('🗑️ URL removed: $urlToRemove');
    print('🗑️ Remaining existing images: ${_existingPictureUrls.length}');
    print('🗑️ Remaining existing files: ${_existingPictureFilesMap.length}');
  }

  @override
  Widget build(BuildContext context) {
    // Force dark mode for salon - wrap in Theme with dark brightness
    return Theme(
      data: ThemeData.dark(),
      child: BlocListener<SalonServicesBloc, SalonServicesState>(
        listener: (context, state) {
          if (state is SalonServiceUpdated) {
            // Show success message as top-dropping dialog with service name
            TopNotificationService.showSuccess(
              context: context,
              message:
                  '${AppTranslations.getString(context, 'service_updated')} - ${widget.serviceName}',
            );

            // Navigate back to service details screen
            Navigator.of(context).pop();
          } else if (state is SalonServicesError) {
            // Show error message as top-dropping dialog
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
              child: GestureDetector(
                onTap: () {
                  // Close keyboard when tapping outside text fields
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        AppTranslations.getString(context, 'edit_service'),
                        style: AppTheme.headingStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Information Banner

                            const SizedBox(height: 32),

                            // Service Name Field
                            CustomTextField(
                              label: AppTranslations.getString(
                                  context, 'service_name'),
                              placeholder: AppTranslations.getString(
                                  context, 'enter_service_name'),
                              controller: serviceNameController,
                              keyboardType: TextInputType.text,
                              formFieldKey: serviceNameFormKey,
                            ),

                            const SizedBox(height: 20),

                            // Service Pictures Field
                            _buildPicturesSection(),

                            const SizedBox(height: 20),

                            // Service Price Field
                            CustomTextField(
                              label:
                                  '${AppTranslations.getString(context, 'service_price')} (TTC)',
                              placeholder: AppTranslations.getString(
                                  context, 'enter_service_price'),
                              controller: servicePriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]')),
                              ],
                              formFieldKey: servicePriceFormKey,
                            ),

                            const SizedBox(height: 20),

                            // Service Description Field
                            CustomTextField(
                              label: AppTranslations.getString(
                                  context, 'service_description'),
                              placeholder: AppTranslations.getString(
                                  context, 'describe_service'),
                              controller: serviceDescriptionController,
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              formFieldKey: serviceDescriptionFormKey,
                            ),

                            const SizedBox(height: 40),

                            // Save Changes Button
                            BlocBuilder<SalonServicesBloc, SalonServicesState>(
                              builder: (context, state) {
                                return CustomButton(
                                  text: AppTranslations.getString(
                                      context, 'save_changes'),
                                  onPressed: _updateService,
                                  isLoading: state is SalonServiceUpdating,
                                  leadingIcon: LucideIcons.save,
                                );
                              },
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.textPrimaryColor,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInformationBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.edit3,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'Edit your service details. '),
                  TextSpan(text: 'All fields are optional.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Pictures',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        // Upload Button
        GestureDetector(
          onTap: _isLoadingPictures ? null : _pickImages,
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
              child: _isLoadingPictures
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          color: AppTheme.textPrimaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Upload Pictures',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        // All Images Preview (Existing + New) - Horizontal Scroll
        if (_existingPictureUrls.isNotEmpty ||
            _selectedPictures.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingPictureUrls.length + _selectedPictures.length,
              itemBuilder: (context, index) {
                final isExistingImage = index < _existingPictureUrls.length;
                final imageIndex = isExistingImage
                    ? index
                    : index - _existingPictureUrls.length;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index <
                            (_existingPictureUrls.length +
                                _selectedPictures.length -
                                1)
                        ? 12
                        : 0,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isExistingImage
                              ? Image.network(
                                  _existingPictureUrls[imageIndex],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: AppTheme.border2,
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: AppTheme.textSecondaryColor,
                                        size: 32,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: AppTheme.border2,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  _selectedPictures[imageIndex],
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            if (isExistingImage) {
                              _removeExistingImage(imageIndex);
                            } else {
                              _removeImage(imageIndex);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
