import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';

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
        _showTopNotification(
          context,
          'Please enter a valid price',
          Colors.red,
          Icons.error,
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

  void _showTopNotification(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalonServicesBloc, SalonServicesState>(
      listener: (context, state) {
        if (state is SalonServiceUpdated) {
          // Show success message as top-dropping dialog with service name
          _showTopNotification(
            context,
            '✅ ${AppTranslations.getString(context, 'service_updated')} - ${widget.serviceName}',
            Colors.green,
            Icons.check_circle,
          );

          // Navigate back to service details screen
          Navigator.of(context).pop();
        } else if (state is SalonServicesError) {
          // Show error message as top-dropping dialog
          _showTopNotification(
            context,
            state.message,
            Colors.red,
            Icons.error,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            leadingIcon: Icons.save,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimaryColor,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppTranslations.getString(context, 'edit_service'),
              style: AppTheme.headingStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
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
              Icons.edit_outlined,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Edit your service details. '),
                  const TextSpan(text: 'All fields are optional.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
