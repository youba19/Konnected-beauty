import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import '../../../../core/bloc/salon_payment_information/salon_payment_information_bloc.dart';
import '../../../../core/bloc/salon_payment_information/salon_payment_information_event.dart';
import '../../../../core/bloc/salon_payment_information/salon_payment_information_state.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class SalonPaymentInformationScreen extends StatefulWidget {
  const SalonPaymentInformationScreen({super.key});

  @override
  State<SalonPaymentInformationScreen> createState() =>
      _SalonPaymentInformationScreenState();
}

class _SalonPaymentInformationScreenState
    extends State<SalonPaymentInformationScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _registryNumberController =
      TextEditingController();
  final TextEditingController _ibanNumberController = TextEditingController();

  bool _hasTextInAnyField = false;
  bool _isLoading = true;

  // Track original values to detect changes
  String _originalBusinessName = '';
  String _originalRegistryNumber = '';
  String _originalIbanNumber = '';

  @override
  void initState() {
    super.initState();
    _fetchPaymentInformation();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _registryNumberController.dispose();
    _ibanNumberController.dispose();
    super.dispose();
  }

  void _checkIfAnyFieldHasText() {
    final hasText = _businessNameController.text.trim().isNotEmpty ||
        _registryNumberController.text.trim().isNotEmpty ||
        _ibanNumberController.text.trim().isNotEmpty;

    if (hasText != _hasTextInAnyField) {
      setState(() {
        _hasTextInAnyField = hasText;
      });
    }
  }

  Future<void> _fetchPaymentInformation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final salonProfileService = SalonProfileService();
      final result = await salonProfileService.getPaymentInformation();

      if (result['success'] == true) {
        final data = result['data'];

        // Populate the text fields with the fetched data (or empty if no data)
        _businessNameController.text = data?['businessName'] ?? '';
        _registryNumberController.text = data?['registryNumber'] ?? '';
        _ibanNumberController.text = data?['IBAN'] ?? '';

        // Store original values for change detection
        _originalBusinessName = _businessNameController.text;
        _originalRegistryNumber = _registryNumberController.text;
        _originalIbanNumber = _ibanNumberController.text;

        // Check if any field has text after populating
        _checkIfAnyFieldHasText();

        setState(() {
          _isLoading = false;
        });
      } else {
        // If API call fails, just show empty fields instead of error
        _businessNameController.text = '';
        _registryNumberController.text = '';
        _ibanNumberController.text = '';

        // Store original values for change detection
        _originalBusinessName = _businessNameController.text;
        _originalRegistryNumber = _registryNumberController.text;
        _originalIbanNumber = _ibanNumberController.text;

        _checkIfAnyFieldHasText();

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // If there's an error, just show empty fields instead of error state
      _businessNameController.text = '';
      _registryNumberController.text = '';
      _ibanNumberController.text = '';

      // Store original values for change detection
      _originalBusinessName = _businessNameController.text;
      _originalRegistryNumber = _registryNumberController.text;
      _originalIbanNumber = _ibanNumberController.text;

      _checkIfAnyFieldHasText();

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalonPaymentInformationBloc(),
      child: _SalonPaymentInformationContent(
        parentState: this,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: AppTranslations.getString(context, 'your_business_name'),
            placeholder:
                AppTranslations.getString(context, 'business_name_placeholder'),
            controller: _businessNameController,
            onChanged: (value) => _checkIfAnyFieldHasText(),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'registry_number_rcs'),
            placeholder: AppTranslations.getString(
                context, 'registry_number_placeholder'),
            controller: _registryNumberController,
            onChanged: (value) => _checkIfAnyFieldHasText(),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'iban_number'),
            placeholder:
                AppTranslations.getString(context, 'iban_number_placeholder'),
            controller: _ibanNumberController,
            onChanged: (value) => _checkIfAnyFieldHasText(),
          ),
          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShimmerContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Name Field Shimmer
            _buildShimmerTextField(),
            const SizedBox(height: 20),

            // Registry Number Field Shimmer
            _buildShimmerTextField(),
            const SizedBox(height: 20),

            // IBAN Number Field Shimmer
            _buildShimmerTextField(),
            const SizedBox(height: 32),

            // Save Button Shimmer
            _buildShimmerButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label shimmer
        Container(
          height: 16,
          width: 140,
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

  Widget _buildShimmerButton() {
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

          // Title with Icon
          Row(
            children: [
              const Icon(
                LucideIcons.wallet,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.getString(context, 'payment_information'),
                style: AppTheme.headingStyle.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<SalonPaymentInformationBloc,
        SalonPaymentInformationState>(
      builder: (context, state) {
        final isLoading = state is SalonPaymentInformationLoading;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _saveInformations(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _hasTextInAnyField
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  width: _hasTextInAnyField ? 2 : 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  isLoading
                      ? 'Saving...'
                      : AppTranslations.getString(context, 'save_informations'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _hasTextInAnyField
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveInformations(BuildContext context) {
    print('💾 Saving salon payment information...');
    print('Business Name: ${_businessNameController.text}');
    print('Registry Number: ${_registryNumberController.text}');
    print('IBAN Number: ${_ibanNumberController.text}');

    // Check if there are any changes
    if (!_hasChanges()) {
      print('📝 No changes detected, showing message instead of API call');
      TopNotificationService.showInfo(
        context: context,
        message: AppTranslations.getString(context, 'no_changes_made'),
      );
      return;
    }

    // Dispatch the update event to the BLoC
    context.read<SalonPaymentInformationBloc>().add(
          UpdateSalonPaymentInformation(
            businessName: _businessNameController.text.trim(),
            registryNumber: _registryNumberController.text.trim(),
            iban: _ibanNumberController.text.trim(),
          ),
        );
  }

  void _resetButtonState() {
    setState(() {
      _hasTextInAnyField = false;
    });

    // Update original values to current values after successful save
    _originalBusinessName = _businessNameController.text.trim();
    _originalRegistryNumber = _registryNumberController.text.trim();
    _originalIbanNumber = _ibanNumberController.text.trim();
  }

  bool _hasChanges() {
    return _businessNameController.text.trim() != _originalBusinessName ||
        _registryNumberController.text.trim() != _originalRegistryNumber ||
        _ibanNumberController.text.trim() != _originalIbanNumber;
  }
}

class _SalonPaymentInformationContent extends StatelessWidget {
  final _SalonPaymentInformationScreenState parentState;

  const _SalonPaymentInformationContent({
    required this.parentState,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalonPaymentInformationBloc,
        SalonPaymentInformationState>(
      listener: (context, state) {
        if (state is SalonPaymentInformationSuccess) {
          TopNotificationService.showSuccess(
            context: context,
            message: AppTranslations.getString(
                context, 'payment_information_updated'),
          );
          // Reset the button state after successful save
          parentState._resetButtonState();
        } else if (state is SalonPaymentInformationError) {
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
              Color(0xFF1F1E1E),
              Color(0xFF3B3B3B),
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
                children: [
                  parentState._buildHeader(),
                  Expanded(
                    child: parentState._buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
