import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'service_details_screen.dart';

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

  @override
  void initState() {
    super.initState();

    // Add listeners for real-time validation
    serviceNameController.addListener(() {
      if (serviceNameFormKey.currentState != null) {
        serviceNameFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });

    servicePriceController.addListener(() {
      if (servicePriceFormKey.currentState != null) {
        servicePriceFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });

    serviceDescriptionController.addListener(() {
      if (serviceDescriptionFormKey.currentState != null) {
        serviceDescriptionFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });
  }

  @override
  void dispose() {
    serviceNameController.dispose();
    servicePriceController.dispose();
    serviceDescriptionController.dispose();
    super.dispose();
  }

  void _createService() {
    // First trigger validation to show inline errors
    serviceNameFormKey.currentState?.validate();
    servicePriceFormKey.currentState?.validate();
    serviceDescriptionFormKey.currentState?.validate();

    // Force UI rebuild to show validation errors
    setState(() {});

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

      // Create service using API
      context.read<SalonServicesBloc>().add(CreateSalonService(
            name: serviceNameController.text,
            price: price,
            description: serviceDescriptionController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalonServicesBloc, SalonServicesState>(
        listener: (context, state) {
          if (state is SalonServiceCreated) {
            // Debug: Print the service data to see what's available
            print('🔍 === SERVICE CREATION RESPONSE DATA ===');
            print('📊 Full serviceData: ${state.serviceData}');
            print('🆔 ID field: ${state.serviceData['id']}');
            print('🆔 _id field: ${state.serviceData['_id']}');
            print('📝 Name field: ${state.serviceData['name']}');
            print('💰 Price field: ${state.serviceData['price']}');
            print('📄 Description field: ${state.serviceData['description']}');
            print('🔍 === END SERVICE CREATION RESPONSE DATA ===');

            // Try to get the ID from different possible fields
            String serviceId = '';
            if (state.serviceData['id'] != null) {
              serviceId = state.serviceData['id'].toString();
            } else if (state.serviceData['_id'] != null) {
              serviceId = state.serviceData['_id'].toString();
            }

            print('🆔 Final Service ID: $serviceId');

            // Check if we have a valid service ID
            if (serviceId.isNotEmpty) {
              // Navigate to service details screen with the created service data
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
              // If no service ID, show success message and go back to home
              TopNotificationService.showSuccess(
                context: context,
                message:
                    '✅ ${AppTranslations.getString(context, 'service_created')} - ${serviceNameController.text}',
              );

              // Navigate back to home screen
              Navigator.of(context).pop();
            }
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        AppTranslations.getString(
                            context, 'create_new_service'),
                        style: AppTheme.headingStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),

                      const SizedBox(height: 24),

                      // Information Banner
                      _buildInformationBanner(),

                      const SizedBox(height: 32),

                      // Service Name Field
                      CustomTextField(
                        label:
                            AppTranslations.getString(context, 'service_name'),
                        placeholder: AppTranslations.getString(
                            context, 'enter_service_name'),
                        controller: serviceNameController,
                        keyboardType: TextInputType.text,
                        formFieldKey: serviceNameFormKey,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppTranslations.getString(
                                context, 'service_name_required');
                          }
                          return null;
                        },
                        autovalidateMode: true,
                        isError:
                            serviceNameFormKey.currentState?.hasError ?? false,
                        errorMessage:
                            serviceNameFormKey.currentState?.hasError == true
                                ? AppTranslations.getString(
                                    context, 'service_name_required')
                                : null,
                      ),

                      const SizedBox(height: 20),

                      // Service Price Field
                      CustomTextField(
                        label:
                            AppTranslations.getString(context, 'service_price'),
                        placeholder: AppTranslations.getString(
                            context, 'enter_service_price'),
                        controller: servicePriceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        formFieldKey: servicePriceFormKey,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppTranslations.getString(
                                context, 'service_price_required');
                          }
                          if (int.tryParse(value) == null) {
                            return AppTranslations.getString(
                                context, 'service_price_invalid');
                          }
                          return null;
                        },
                        autovalidateMode: true,
                        isError:
                            servicePriceFormKey.currentState?.hasError ?? false,
                        errorMessage:
                            servicePriceFormKey.currentState?.hasError == true
                                ? (int.tryParse(servicePriceController.text) ==
                                        null
                                    ? AppTranslations.getString(
                                        context, 'service_price_invalid')
                                    : AppTranslations.getString(
                                        context, 'service_price_required'))
                                : null,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppTranslations.getString(
                                context, 'service_description_required');
                          }
                          if (value.length < 10) {
                            return AppTranslations.getString(
                                context, 'service_description_too_short');
                          }
                          return null;
                        },
                        autovalidateMode: true,
                        isError:
                            serviceDescriptionFormKey.currentState?.hasError ??
                                false,
                        errorMessage: serviceDescriptionFormKey
                                    .currentState?.hasError ==
                                true
                            ? (serviceDescriptionController.text.length < 10
                                ? AppTranslations.getString(
                                    context, 'service_description_too_short')
                                : AppTranslations.getString(
                                    context, 'service_description_required'))
                            : null,
                      ),

                      const SizedBox(height: 40),

                      // Create Service Button
                      BlocBuilder<SalonServicesBloc, SalonServicesState>(
                        builder: (context, state) {
                          return CustomButton(
                            text: AppTranslations.getString(
                                context, 'create_new_service'),
                            onPressed: _createService,
                            isLoading: state is SalonServiceCreating,
                            leadingIcon: LucideIcons.plus,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildInformationBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.border2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.flag,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.getString(
                      context, 'create_only_services_you_want_to_promote'),
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.getString(
                      context, 'discounts_applied_with_ambassadors'),
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.getString(
                      context, 'packs_formulas_shared_more'),
                  style: const TextStyle(
                    color: AppTheme.accentColor,
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
}
