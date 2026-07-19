import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../widgets/common/top_notification_banner.dart';

abstract final class _EditServiceUi {
  static const double radius = 16;
  static const double buttonRadius = 14;
  static const double buttonSize = 48;
  static const double horizontalPadding = 16;
}

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

  final List<File> _selectedPictures = [];
  final List<String> _existingPictureUrls = [];
  final Map<String, File> _existingPictureFilesMap = {};
  final List<String> _removedPictureUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingPictures = false;
  bool _isDownloadingExistingPictures = false;
  bool _hasDownloadedExistingPictures = false;

  @override
  void initState() {
    super.initState();
    serviceNameController.text = widget.serviceName;
    servicePriceController.text = widget.servicePrice.replaceAll(' €', '');
    serviceDescriptionController.text = widget.serviceDescription;
    _loadExistingPictures();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasDownloadedExistingPictures) {
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

        if (_existingPictureUrls.isNotEmpty &&
            !_hasDownloadedExistingPictures) {
          _downloadExistingPictures();
        }
      }
    }
  }

  Future<void> _downloadExistingPictures() async {
    if (_isDownloadingExistingPictures || _hasDownloadedExistingPictures) {
      return;
    }

    setState(() {
      _isDownloadingExistingPictures = true;
      _existingPictureFilesMap.clear();
    });

    final Map<String, File> downloadedFilesMap = {};

    for (int i = 0; i < _existingPictureUrls.length; i++) {
      try {
        final url = _existingPictureUrls[i];
        if (_removedPictureUrls.contains(url)) continue;

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();

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
          await tempFile.writeAsBytes(response.bodyBytes);
          downloadedFilesMap[url] = tempFile;
        }
      } catch (e) {
        print('📥 Error converting picture $i: $e');
      }
    }

    setState(() {
      _existingPictureFilesMap
        ..clear()
        ..addAll(downloadedFilesMap);
      _isDownloadingExistingPictures = false;
      _hasDownloadedExistingPictures = true;
    });
  }

  @override
  void dispose() {
    serviceNameController.dispose();
    servicePriceController.dispose();
    serviceDescriptionController.dispose();
    super.dispose();
  }

  void _updateService() {
    serviceNameFormKey.currentState?.validate();
    servicePriceFormKey.currentState?.validate();
    serviceDescriptionFormKey.currentState?.validate();

    if (serviceNameController.text.isNotEmpty &&
        servicePriceController.text.isNotEmpty &&
        serviceDescriptionController.text.isNotEmpty) {
      final price = int.tryParse(servicePriceController.text);
      if (price == null) {
        TopNotificationService.showError(
          context: context,
          message: AppTranslations.getString(
            context,
            'please_enter_valid_number',
          ),
        );
        return;
      }

      final List<File> allPictures = [];
      for (final url in _existingPictureUrls) {
        if (!_removedPictureUrls.contains(url) &&
            _existingPictureFilesMap.containsKey(url)) {
          allPictures.add(_existingPictureFilesMap[url]!);
        }
      }
      allPictures.addAll(_selectedPictures);

      final List<File>? picturesToSend =
          allPictures.isNotEmpty ? allPictures : null;

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
      setState(() => _isLoadingPictures = true);

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
      }
    } catch (e) {
      if (!mounted) return;
      TopNotificationService.showError(
        context: context,
        message: 'Failed to pick images: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPictures = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedPictures.removeAt(index));
  }

  void _removeExistingImage(int index) {
    final urlToRemove = _existingPictureUrls[index];
    setState(() {
      _removedPictureUrls.add(urlToRemove);
      _existingPictureUrls.removeAt(index);
      _existingPictureFilesMap.remove(urlToRemove);
    });
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required SalonUiTheme ui,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: ui.textMuted,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_EditServiceUi.radius),
        borderSide: BorderSide(color: ui.borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_EditServiceUi.radius),
        borderSide: BorderSide(color: ui.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_EditServiceUi.radius),
        borderSide: BorderSide(color: ui.textPrimary, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_EditServiceUi.radius),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_EditServiceUi.radius),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    required SalonUiTheme ui,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final topInset = MediaQuery.paddingOf(context).top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ui.systemOverlay,
          child: BlocListener<SalonServicesBloc, SalonServicesState>(
        listener: (context, state) {
          if (state is SalonServiceUpdated) {
            TopNotificationService.showSuccess(
              context: context,
              message:
                  '${AppTranslations.getString(context, 'service_updated')} - ${widget.serviceName}',
            );
            Navigator.of(context).pop();
          } else if (state is SalonServicesError) {
            TopNotificationService.showError(
              context: context,
              message: state.message,
            );
          }
        },
        child: ColoredBox(
          color: ui.bg,
          child: Scaffold(
            backgroundColor: ui.bg,
            body: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topInset + 160,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: ui.fullSheetGradient,
                            stops: ui.fullSheetStops,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            _EditServiceUi.horizontalPadding,
                            topInset + 8,
                            _EditServiceUi.horizontalPadding,
                            0,
                          ),
                          child: Row(
                            children: [
                              _buildBackButton(ui),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppTranslations.getString(
                                    context,
                                    'edit_service',
                                  ),
                                  style: TextStyle(
                                    color: ui.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              _EditServiceUi.horizontalPadding,
                              24,
                              _EditServiceUi.horizontalPadding,
                              28,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabeledField(
                                  ui: ui,
                                  label: AppTranslations.getString(
                                    context,
                                    'service_name',
                                  ),
                                  child: TextFormField(
                                    key: serviceNameFormKey,
                                    controller: serviceNameController,
                                    style: TextStyle(color: ui.textPrimary),
                                    cursorColor: ui.textPrimary,
                                    decoration: _fieldDecoration(
                                      hintText: AppTranslations.getString(
                                        context,
                                        'enter_service_name',
                                      ),
                                      ui: ui,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppTranslations.getString(
                                          context,
                                          'service_name_required',
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildPicturesSection(ui),
                                const SizedBox(height: 20),
                                _buildLabeledField(
                                  ui: ui,
                                  label:
                                      '${AppTranslations.getString(context, 'service_price')} (TTC)',
                                  child: TextFormField(
                                    key: servicePriceFormKey,
                                    controller: servicePriceController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: TextStyle(color: ui.textPrimary),
                                    cursorColor: ui.textPrimary,
                                    decoration: _fieldDecoration(
                                      hintText: AppTranslations.getString(
                                        context,
                                        'enter_service_price',
                                      ),
                                      ui: ui,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppTranslations.getString(
                                          context,
                                          'please_enter_valid_number',
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildLabeledField(
                                  ui: ui,
                                  label: AppTranslations.getString(
                                    context,
                                    'service_description',
                                  ),
                                  child: TextFormField(
                                    key: serviceDescriptionFormKey,
                                    controller: serviceDescriptionController,
                                    maxLines: 5,
                                    style: TextStyle(color: ui.textPrimary),
                                    cursorColor: ui.textPrimary,
                                    decoration: _fieldDecoration(
                                      hintText: AppTranslations.getString(
                                        context,
                                        'describe_service',
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
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 32),
                                BlocBuilder<SalonServicesBloc,
                                    SalonServicesState>(
                                  builder: (context, state) {
                                    final isLoading =
                                        state is SalonServiceUpdating;
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed:
                                            isLoading ? null : _updateService,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: ui.primaryButtonBg,
                                          foregroundColor: ui.primaryButtonFg,
                                          disabledBackgroundColor: ui
                                              .primaryButtonBg
                                              .withValues(alpha: 0.7),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              _EditServiceUi.radius,
                                            ),
                                          ),
                                        ),
                                        child: isLoading
                                            ? SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: ui.primaryButtonFg,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    AppTranslations.getString(
                                                      context,
                                                      'save_changes',
                                                    ),
                                                    style: TextStyle(
                                                      color: ui.primaryButtonFg,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    LucideIcons.save,
                                                    size: 18,
                                                    color: ui.primaryButtonFg,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildBackButton(SalonUiTheme ui) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: _EditServiceUi.buttonSize,
        height: _EditServiceUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ui.buttonFillTop,
              ui.buttonFillBottom,
            ],
          ),
          borderRadius: BorderRadius.circular(_EditServiceUi.buttonRadius),
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
    );
  }

  Widget _buildPicturesSection(SalonUiTheme ui) {
    final placeholder =
        ui.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'service_pictures'),
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _isLoadingPictures ? null : _pickImages,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(_EditServiceUi.radius),
              border: Border.all(color: ui.borderSubtle, width: 1),
            ),
            child: Center(
              child: _isLoadingPictures
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(ui.textPrimary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          color: ui.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppTranslations.getString(
                            context,
                            'upload_pictures',
                          ),
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
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
                          borderRadius:
                              BorderRadius.circular(_EditServiceUi.radius),
                          border: Border.all(
                            color: ui.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(_EditServiceUi.radius),
                          child: isExistingImage
                              ? Image.network(
                                  _existingPictureUrls[imageIndex],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: placeholder,
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: ui.textMuted,
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
                                      color: placeholder,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: ui.textMuted,
                                          ),
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
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
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
