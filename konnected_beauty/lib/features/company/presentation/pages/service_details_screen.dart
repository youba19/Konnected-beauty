import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'edit_service_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String servicePrice;
  final String serviceDescription;
  final bool showSuccessMessage;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDescription,
    this.showSuccessMessage = false,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  _ServiceDetailsScreenState();

  @override
  void initState() {
    super.initState();
    // Always load services on app start
    context.read<SalonServicesBloc>().add(LoadSalonServices());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalonServicesBloc, SalonServicesState>(
      listener: (context, state) {
        if (state is SalonServiceDeleted) {
          // Show success message as top-dropping dialog with service name
          TopNotificationService.showSuccess(
            context: context,
            message:
                '${AppTranslations.getString(context, 'service_deleted')} - ${widget.serviceName}',
          );

          // Navigate back to home screen
          Navigator.of(context).pop();
        } else if (state is SalonServicesError) {
          // Show error message
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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success Message (if needed)
                        if (widget.showSuccessMessage) ...[
                          _buildSuccessMessage(),
                          const SizedBox(height: 24),
                        ],

                        // Service Information
                        _buildServiceInformation(),

                        const SizedBox(height: 40),

                        // Action Buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 10.0, bottom: 5),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.textPrimaryColor,
              size: 32,
            ),
            onPressed: () {
              // Navigate back to previous screen
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppTranslations.getString(
                  context, 'service_created_successfully'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service Name
        Text(
          widget.serviceName,
          style: AppTheme.headingStyle.copyWith(fontSize: 24),
        ),

        const SizedBox(height: 8),

        // Service Price
        Text(
          '${widget.servicePrice}',
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // Service Description
        Text(
          widget.serviceDescription,
          style: AppTheme.subtitleStyle.copyWith(
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Edit Button
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                print('🆔 === NAVIGATING FROM SERVICE DETAILS TO EDIT ===');
                print('🆔 Service ID: ${widget.serviceId}');
                print('📝 Service Name: ${widget.serviceName}');
                print('💰 Service Price: ${widget.servicePrice}');
                print('📄 Service Description: ${widget.serviceDescription}');

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<SalonServicesBloc>(),
                      child: EditServiceScreen(
                        serviceId: widget.serviceId,
                        serviceName: widget.serviceName,
                        servicePrice: widget.servicePrice,
                        serviceDescription: widget.serviceDescription,
                      ),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppTheme.textPrimaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppTheme.textPrimaryColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                AppTranslations.getString(context, 'edit'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Delete Button
        Expanded(
          child: BlocBuilder<SalonServicesBloc, SalonServicesState>(
            builder: (context, state) {
              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: state is SalonServiceDeleting
                      ? null
                      : () {
                          _showDeleteConfirmation();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                  ),
                  child: state is SalonServiceDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Text(
                          AppTranslations.getString(context, 'delete'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            AppTranslations.getString(context, 'delete_service'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${AppTranslations.getString(context, 'delete_service_confirmation')} "${widget.serviceName}"?',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppTranslations.getString(context, 'cancel'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Delete the service using the API
                context.read<SalonServicesBloc>().add(DeleteSalonService(
                      serviceId: widget.serviceId,
                      serviceName: widget.serviceName,
                    ));
              },
              child: Text(
                AppTranslations.getString(context, 'delete'),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
