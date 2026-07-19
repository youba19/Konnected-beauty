import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'service_details_screen.dart';

abstract final class _CreateServiceUi {
  static const double radius = 16;
  static const double buttonRadius = 14;
  static const double buttonSize = 48;
  static const double horizontalPadding = 16;
}

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
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
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingPictures = false;

  @override
  void dispose() {
    serviceNameController.dispose();
    servicePriceController.dispose();
    serviceDescriptionController.dispose();
    super.dispose();
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
      TopNotificationService.showError(
        context: context,
        message: 'Failed to pick images: $e',
      );
    } finally {
      setState(() => _isLoadingPictures = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedPictures.removeAt(index));
  }

  void _createService() {
    serviceNameFormKey.currentState?.validate();
    servicePriceFormKey.currentState?.validate();
    serviceDescriptionFormKey.currentState?.validate();
    setState(() {});

    if (serviceNameController.text.isNotEmpty &&
        servicePriceController.text.isNotEmpty &&
        serviceDescriptionController.text.isNotEmpty) {
      final price = int.tryParse(servicePriceController.text);
      if (price == null) {
        TopNotificationService.showError(
          context: context,
          message: 'Please enter a valid price',
        );
        return;
      }

      context.read<SalonServicesBloc>().add(CreateSalonService(
            name: serviceNameController.text,
            price: price,
            description: serviceDescriptionController.text,
            pictures: _selectedPictures.isNotEmpty ? _selectedPictures : null,
          ));
    }
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
        borderRadius: BorderRadius.circular(_CreateServiceUi.radius),
        borderSide: BorderSide(color: ui.borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_CreateServiceUi.radius),
        borderSide: BorderSide(color: ui.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_CreateServiceUi.radius),
        borderSide: BorderSide(color: ui.textPrimary, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_CreateServiceUi.radius),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_CreateServiceUi.radius),
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
              if (state is SalonServiceCreated) {
                String serviceId = '';
                if (state.serviceData['id'] != null) {
                  serviceId = state.serviceData['id'].toString();
                } else if (state.serviceData['_id'] != null) {
                  serviceId = state.serviceData['_id'].toString();
                }

                if (serviceId.isNotEmpty) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(
                        serviceId: serviceId,
                        serviceName: serviceNameController.text,
                        servicePrice: servicePriceController.text,
                        serviceDescription: serviceDescriptionController.text,
                        showSuccessMessage: true,
                      ),
                    ),
                  );
                } else {
                  TopNotificationService.showSuccess(
                    context: context,
                    message:
                        '✅ ${AppTranslations.getString(context, 'service_created')} - ${serviceNameController.text}',
                  );
                  Navigator.of(context).pop();
                }
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
                                _CreateServiceUi.horizontalPadding,
                                topInset + 8,
                                _CreateServiceUi.horizontalPadding,
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
                                        'create_new_service',
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
                                  _CreateServiceUi.horizontalPadding,
                                  24,
                                  _CreateServiceUi.horizontalPadding,
                                  28,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInformationBanner(ui),
                                    const SizedBox(height: 28),
                                    _buildLabeledField(
                                      ui: ui,
                                      label: AppTranslations.getString(
                                        context,
                                        'service_name',
                                      ),
                                      child: TextFormField(
                                        key: serviceNameFormKey,
                                        controller: serviceNameController,
                                        style:
                                            TextStyle(color: ui.textPrimary),
                                        cursorColor: ui.textPrimary,
                                        decoration: _fieldDecoration(
                                          hintText:
                                              AppTranslations.getString(
                                            context,
                                            'enter_service_name',
                                          ),
                                          ui: ui,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
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
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        style:
                                            TextStyle(color: ui.textPrimary),
                                        cursorColor: ui.textPrimary,
                                        decoration: _fieldDecoration(
                                          hintText:
                                              AppTranslations.getString(
                                            context,
                                            'enter_service_price',
                                          ),
                                          ui: ui,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
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
                                        controller:
                                            serviceDescriptionController,
                                        maxLines: 5,
                                        style:
                                            TextStyle(color: ui.textPrimary),
                                        cursorColor: ui.textPrimary,
                                        decoration: _fieldDecoration(
                                          hintText:
                                              AppTranslations.getString(
                                            context,
                                            'describe_service',
                                          ),
                                          ui: ui,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
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
                                            state is SalonServiceCreating;
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton(
                                            onPressed: isLoading
                                                ? null
                                                : _createService,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  ui.primaryButtonBg,
                                              foregroundColor:
                                                  ui.primaryButtonFg,
                                              disabledBackgroundColor: ui
                                                  .primaryButtonBg
                                                  .withValues(alpha: 0.7),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  _CreateServiceUi.radius,
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
                                                      color:
                                                          ui.primaryButtonFg,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        AppTranslations
                                                            .getString(
                                                          context,
                                                          'create_new_service',
                                                        ),
                                                        style: TextStyle(
                                                          color: ui
                                                              .primaryButtonFg,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 8),
                                                      Icon(
                                                        LucideIcons.plus,
                                                        size: 18,
                                                        color: ui
                                                            .primaryButtonFg,
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
        width: _CreateServiceUi.buttonSize,
        height: _CreateServiceUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ui.buttonFillTop, ui.buttonFillBottom],
          ),
          borderRadius: BorderRadius.circular(_CreateServiceUi.buttonRadius),
          border: ui.isDark ? null : Border.all(color: ui.cardBorder, width: 1),
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

  Widget _buildInformationBanner(SalonUiTheme ui) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.flag,
            color: SalonUiTheme.accentBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.getString(
                    context,
                    'create_only_services_you_want_to_promote',
                  ),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.getString(
                    context,
                    'discounts_applied_with_ambassadors',
                  ),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.getString(
                    context,
                    'packs_formulas_shared_more',
                  ),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicturesSection(SalonUiTheme ui) {
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
              borderRadius: BorderRadius.circular(_CreateServiceUi.radius),
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
        if (_selectedPictures.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPictures.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(_CreateServiceUi.radius),
                        border: Border.all(color: ui.cardBorder, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(_CreateServiceUi.radius),
                        child: Image.file(
                          _selectedPictures[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
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
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
