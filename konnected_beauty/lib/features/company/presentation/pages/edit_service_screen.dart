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

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing service data
    serviceNameController.text = widget.serviceName;
    servicePriceController.text = widget.servicePrice.replaceAll(' €', '');
    serviceDescriptionController.text = widget.serviceDescription;
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

      // Update service using API
      context.read<SalonServicesBloc>().add(UpdateSalonService(
            serviceId: widget.serviceId,
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

                          // Service Price Field
                          CustomTextField(
                            label: AppTranslations.getString(
                                context, 'service_price'),
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
}
