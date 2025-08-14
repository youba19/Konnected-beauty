import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/saloon_registration/saloon_registration_bloc.dart';
import '../../../../core/bloc/welcome/welcome_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../widgets/forms/custom_dropdown.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'welcome_screen.dart';
import '../../../company/presentation/pages/salon_home_screen.dart';
import '../../../../core/bloc/language/language_bloc.dart';

class SaloonRegistrationScreen extends StatefulWidget {
  const SaloonRegistrationScreen({super.key});

  @override
  State<SaloonRegistrationScreen> createState() =>
      _SaloonRegistrationScreenState();
}

class _SaloonRegistrationScreenState extends State<SaloonRegistrationScreen>
    with TickerProviderStateMixin {
  // Local TextEditingControllers
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController otpController;
  late TextEditingController saloonNameController;
  late TextEditingController saloonAddressController;
  late TextEditingController saloonDomainController;
  late TextEditingController saloonDescriptionController;

  // Form keys for validation
  final GlobalKey<FormFieldState> nameFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> emailFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> phoneFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> passwordFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> otpFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> saloonNameFormKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> saloonAddressFormKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> saloonDomainFormKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> saloonDescriptionFormKey =
      GlobalKey<FormFieldState>();

  // Password visibility state
  bool isPasswordVisible = false;

  // Timer for debouncing description updates
  Timer? _descriptionDebounceTimer;

  // Time options for dropdown
  final List<String> timeOptions = [
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

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    otpController = TextEditingController();
    saloonNameController = TextEditingController();
    saloonAddressController = TextEditingController();
    saloonDomainController = TextEditingController();
    saloonDescriptionController = TextEditingController();

    // TEMPORARY: Start directly at salon profile step for testing
    // This will be removed when going back to normal flow
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<SaloonRegistrationBloc>().add(GoToStep(3));
    // });

    // Add listeners to sync with Bloc state
    nameController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
      // Trigger validation for real-time error display
      if (nameFormKey.currentState != null) {
        nameFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });

    emailController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
      // Trigger validation for real-time error display
      if (emailFormKey.currentState != null) {
        emailFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });

    phoneController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
      // Trigger validation for real-time error display
      if (phoneFormKey.currentState != null) {
        phoneFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });

    passwordController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
      // Trigger validation for real-time error display
      if (passwordFormKey.currentState != null) {
        passwordFormKey.currentState!.validate();
        setState(() {}); // Update UI to show validation errors
      }
    });

    otpController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdateOtp(otpController.text));
    });

    saloonNameController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdateSalonInfo(
            saloonName: saloonNameController.text,
            saloonAddress: saloonAddressController.text,
            saloonDomain: saloonDomainController.text,
          ));
    });

    saloonAddressController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdateSalonInfo(
            saloonName: saloonNameController.text,
            saloonAddress: saloonAddressController.text,
            saloonDomain: saloonDomainController.text,
          ));
    });

    saloonDomainController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdateSalonInfo(
            saloonName: saloonNameController.text,
            saloonAddress: saloonAddressController.text,
            saloonDomain: saloonDomainController.text,
          ));
    });
  }

  void _showSuccessNotification(String message) {
    TopNotificationService.showSuccess(
      context: context,
      message: message,
    );
  }

  void _showErrorNotification(String message) {
    TopNotificationService.showError(
      context: context,
      message: message,
    );
  }

  void _syncDescriptionController(SaloonRegistrationState state) {
    // Only sync if the controller is empty and state has description, or if we're initializing
    if (saloonDescriptionController.text.isEmpty &&
        state.description.isNotEmpty) {
      saloonDescriptionController.text = state.description;
    }
  }

  @override
  void dispose() {
    // Dispose timer
    _descriptionDebounceTimer?.cancel();

    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    saloonNameController.dispose();
    saloonAddressController.dispose();
    saloonDomainController.dispose();
    saloonDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF3B3B3B),
            Color(0xFF1F1E1E), // Bottom color (darker)
            // Top color (lighter)
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BlocBuilder<SaloonRegistrationBloc, SaloonRegistrationState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(LucideIcons.arrowLeft,
                    color: AppTheme.textPrimaryColor),
                onPressed: () async {
                  // Dismiss keyboard before going back
                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 100));

                  if (state.currentStep > 0) {
                    // Go to previous step within registration flow
                    context.read<SaloonRegistrationBloc>().add(PreviousStep());
                  } else {
                    // Go back to welcome screen if we're on the first step
                    context.read<WelcomeBloc>().add(SkipLogoAnimation());
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                    );
                  }
                },
              );
            },
          ),
          actions: [
            BlocBuilder<SaloonRegistrationBloc, SaloonRegistrationState>(
              builder: (context, state) => _buildStepper(context, state),
            ),
            IconButton(
              icon: const Icon(
                LucideIcons.moreHorizontal,
                color: AppTheme.textPrimaryColor,
              ),
              onPressed: () {
                // TODO: Implement menu functionality
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocListener<SaloonRegistrationBloc, SaloonRegistrationState>(
            listener: (context, state) {
              // On full success: navigate to Salon Home and show top green banner
              if (state is SaloonRegistrationSuccess) {
                _showSuccessNotification(state.successMessage);
                // Navigate to Salon Home after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const SalonHomeScreen(),
                    ),
                    (route) => false,
                  );
                });
                return;
              }
              // Handle error messages (but not success messages that are handled by top banner)
              if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty &&
                  !state.errorMessage!.toLowerCase().contains('successfully') &&
                  !state.errorMessage!
                      .toLowerCase()
                      .contains('already verified')) {
                _showErrorNotification(state.errorMessage!);
              }

              // OTP validation success is handled by the top drop banner
              // No need to show additional SnackBar messages for OTP verification
            },
            child: BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, languageState) {
                return BlocBuilder<SaloonRegistrationBloc,
                    SaloonRegistrationState>(
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(),
                          const SizedBox(height: 32),

                          // Content
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          _buildStepContent(context, state),
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Bottom Button
                          _buildBottomButton(context, state),
                          // Add extra padding for keyboard
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'create_account'),
          style: AppTheme.headingStyle,
        ),
        const SizedBox(height: 8),
        Text(
          AppTranslations.getString(context, 'join_konnected_beauty'),
          style: AppTheme.subtitleStyle,
        ),
      ],
    );
  }

  Widget _buildStepContent(
      BuildContext context, SaloonRegistrationState state) {
    print('Building step content for step: ${state.currentStep}');
    try {
      switch (state.currentStep) {
        case 0:
          print('Building Personal Information step');
          return _buildPersonalInformationStep(context, state);
        case 1:
          print('Building OTP Verification step');
          return _buildOtpVerificationStep(context, state);
        case 2:
          print('Building Salon Information step');
          return _buildSaloonInformationStep(context, state);
        case 3:
          print('Building Salon Profile step');
          return _buildSaloonProfileStep(context, state);
        default:
          print('Building default step');
          return const SizedBox.shrink();
      }
    } catch (e) {
      print('Error building step content: $e');
      // Return a safe fallback widget if there's any error
      return Center(
        child: Text(
          AppTranslations.getString(context, 'something_went_wrong'),
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildPersonalInformationStep(
      BuildContext context, SaloonRegistrationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.user,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppTranslations.getString(context, 'personal_information'),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24), // Normal spacing between title and fields

        // Name Field
        CustomTextField(
          label: AppTranslations.getString(context, 'full_name'),
          placeholder:
              AppTranslations.getString(context, 'full_name_placeholder'),
          controller: nameController,
          validator: (value) => Validators.validateName(value, context),
          autovalidateMode: true,
          formFieldKey: nameFormKey,
          isError: nameFormKey.currentState?.hasError ?? false,
          errorMessage: nameFormKey.currentState?.hasError == true
              ? Validators.validateName(nameController.text, context)
              : null,
        ),
        const SizedBox(height: 20),

        // Email Field
        CustomTextField(
          label: AppTranslations.getString(context, 'email'),
          placeholder: AppTranslations.getString(context, 'email_placeholder'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => Validators.validateEmail(value, context),
          autovalidateMode: true,
          formFieldKey: emailFormKey,
          isError: emailFormKey.currentState?.hasError ?? false,
          errorMessage: emailFormKey.currentState?.hasError == true
              ? Validators.validateEmail(emailController.text, context)
              : null,
        ),
        const SizedBox(height: 20),

        // Phone Field
        CustomTextField(
          label: AppTranslations.getString(context, 'phone'),
          placeholder: AppTranslations.getString(context, 'phone_placeholder'),
          controller: phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) => Validators.validatePhone(value, context),
          autovalidateMode: true,
          formFieldKey: phoneFormKey,
          isError: phoneFormKey.currentState?.hasError ?? false,
          errorMessage: phoneFormKey.currentState?.hasError == true
              ? Validators.validatePhone(phoneController.text, context)
              : null,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            LengthLimitingTextInputFormatter(13), // +33 + 9 digits
          ],
        ),
        const SizedBox(height: 20),

        // Password Field
        CustomTextField(
          label: AppTranslations.getString(context, 'password'),
          placeholder:
              AppTranslations.getString(context, 'password_placeholder'),
          controller: passwordController,
          isPassword: true,
          isPasswordVisible: isPasswordVisible,
          validator: (value) => Validators.validatePassword(value, context),
          autovalidateMode: true,
          formFieldKey: passwordFormKey,
          isError: passwordFormKey.currentState?.hasError ?? false,
          errorMessage: passwordFormKey.currentState?.hasError == true
              ? Validators.validatePassword(passwordController.text, context)
              : null,
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              color: AppTheme.textSecondaryColor,
            ),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          ),
        ),
        const SizedBox(height: 100), // Extra space for keyboard
      ],
    );
  }

  Widget _buildOtpVerificationStep(
      BuildContext context, SaloonRegistrationState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.shield,
                color: AppTheme.textPrimaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppTranslations.getString(context, 'phone_verification'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Success message for signup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  color: Colors.green,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account created successfully! Please check your email for the verification code.',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: AppTranslations.getString(context, 'verification_code'),
            placeholder: AppTranslations.getString(context, 'otp_placeholder'),
            controller: otpController,
            keyboardType: TextInputType.number,
            isError: state.isOtpError,
            errorMessage: state.isOtpError
                ? AppTranslations.getString(context, 'wrong_code')
                : null,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) => Validators.validateOtp(value, context),
            autovalidateMode: true,
            formFieldKey: otpFormKey,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              context.read<SaloonRegistrationBloc>().add(ResendOtp());
            },
            child: Text(
              AppTranslations.getString(context, 'resend_code'),
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          // Add extra space for keyboard
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSaloonInformationStep(
      BuildContext context, SaloonRegistrationState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.building2,
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
          CustomTextField(
            label: AppTranslations.getString(context, 'salon_name'),
            placeholder:
                AppTranslations.getString(context, 'salon_name_placeholder'),
            controller: saloonNameController,
            validator: (value) => Validators.validateSalonName(value, context),
            autovalidateMode: true,
            formFieldKey: saloonNameFormKey,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'salon_address'),
            placeholder:
                AppTranslations.getString(context, 'salon_address_placeholder'),
            controller: saloonAddressController,
            keyboardType: TextInputType.streetAddress,
            validator: (value) =>
                Validators.validateSalonAddress(value, context),
            autovalidateMode: true,
            formFieldKey: saloonAddressFormKey,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'activity_domain'),
            placeholder: AppTranslations.getString(
                context, 'activity_domain_placeholder'),
            controller: saloonDomainController,
            keyboardType: TextInputType.text,
            validator: (value) =>
                Validators.validateSalonDomain(value, context),
            autovalidateMode: true,
            formFieldKey: saloonDomainFormKey,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSaloonProfileStep(
      BuildContext context, SaloonRegistrationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.image,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppTranslations.getString(context, 'salon_profile'),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Saloon Pictures Section
        Text(
          AppTranslations.getString(context, 'salon_photos'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            context.read<SaloonRegistrationBloc>().add(UploadImage());
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                AppTranslations.getString(context, 'upload_photos'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),

        // Uploaded Images
        if (state.uploadedImages.isNotEmpty)
          Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.uploadedImages.length,
                  itemBuilder: (context, index) {
                    final imageFile = state.uploadedImages[index];
                    final imageName = imageFile.path.split('/').last;
                    return Container(
                      width: 120, // Fixed width for consistent size
                      height: 32, // Fixed height for consistent size
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: AppTheme.borderColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              imageName,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Add ... when text is too long
                              maxLines: 1, // Limit to single line
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<SaloonRegistrationBloc>()
                                  .add(RemoveImage(index));
                            },
                            child: const Icon(
                              LucideIcons.trash2,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // Hours Section
        Row(
          children: [
            Expanded(
              child: CustomDropdown(
                label: AppTranslations.getString(context, 'opening_hour'),
                placeholder: AppTranslations.getString(context, 'select'),
                items: timeOptions,
                selectedValue: state.openHour,
                compact: true,
                onChanged: (value) {
                  print('🕐 Opening Hour Changed to: "${value ?? ''}"');
                  print(
                      '📝 Current Description: "${saloonDescriptionController.text}"');
                  print('🕐 Current Closing Hour: "${state.closingHour}"');
                  // Update local description controller into bloc to prevent overriding hours
                  context.read<SaloonRegistrationBloc>().add(UpdateSalonProfile(
                        description: saloonDescriptionController.text,
                        openHour: value ?? '',
                        closingHour: state.closingHour,
                      ));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDropdown(
                label: AppTranslations.getString(context, 'closing_hour'),
                placeholder: AppTranslations.getString(context, 'select'),
                items: timeOptions,
                selectedValue: state.closingHour,
                compact: true,
                onChanged: (value) {
                  print('🕐 Closing Hour Changed to: "${value ?? ''}"');
                  print(
                      '📝 Current Description: "${saloonDescriptionController.text}"');
                  print('🕐 Current Opening Hour: "${state.openHour}"');
                  context.read<SaloonRegistrationBloc>().add(UpdateSalonProfile(
                        description: saloonDescriptionController.text,
                        openHour: state.openHour,
                        closingHour: value ?? '',
                      ));
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
          controller: saloonDescriptionController,
          validator: (value) => Validators.validateDescription(value, context),
          autovalidateMode: true,
          maxLines: 4,
          formFieldKey: saloonDescriptionFormKey,
          onChanged: (value) {
            print('🎯 TextField onChanged: "$value"');
            print('🕐 State openHour: "${state.openHour}"');
            print('🕐 State closingHour: "${state.closingHour}"');
            // Cancel any pending debounced update
            _descriptionDebounceTimer?.cancel();
            // Update immediately to preserve hours
            context.read<SaloonRegistrationBloc>().add(UpdateSalonProfile(
                  description: value,
                  openHour: state.openHour,
                  closingHour: state.closingHour,
                ));
          },
        ),
      ],
    );
  }

  Widget _buildBottomButton(
      BuildContext context, SaloonRegistrationState state) {
    switch (state.currentStep) {
      case 0:
        return CustomButton(
          text: AppTranslations.getString(context, 'continue'),
          onPressed: state.isLoading
              ? () {}
              : () {
                  print('Continue button pressed for step 0');
                  // First trigger validation to show inline errors
                  _triggerValidationAndUpdateUI();

                  // Check if we can proceed after validation
                  if (_canProceedToNextStep(state)) {
                    print('Calling submitSignup');
                    context.read<SaloonRegistrationBloc>().add(SubmitSignup());
                  } else {
                    print('Validation failed - showing inline errors');
                  }
                },
          leadingIcon: LucideIcons.arrowRight,
          isLoading: state.isLoading,
        );
      case 1:
        return CustomButton(
          text: AppTranslations.getString(context, 'submit_continue'),
          onPressed: state.isLoading
              ? () {}
              : () {
                  _validateCurrentStep(state);
                  if (_canProceedToNextStep(state)) {
                    context.read<SaloonRegistrationBloc>().add(SubmitOtp());
                  }
                },
          isLoading: state.isLoading,
        );
      case 2:
        return CustomButton(
          text: AppTranslations.getString(context, 'continue'),
          onPressed: state.isLoading
              ? () {}
              : () {
                  _validateCurrentStep(state);
                  if (_canProceedToNextStep(state)) {
                    context
                        .read<SaloonRegistrationBloc>()
                        .add(SubmitSalonInfo());
                  }
                },
          isLoading: state.isLoading,
        );
      case 3:
        return CustomButton(
          text: AppTranslations.getString(context, 'continue'),
          onPressed: state.isLoading
              ? () {}
              : () {
                  _validateCurrentStep(state);
                  if (_canProceedToNextStep(state)) {
                    context
                        .read<SaloonRegistrationBloc>()
                        .add(SubmitSalonProfile());
                  }
                },
          isLoading: state.isLoading,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  bool _canProceedToNextStep(SaloonRegistrationState state) {
    switch (state.currentStep) {
      case 0:
        return nameController.text.isNotEmpty &&
            emailController.text.isNotEmpty &&
            phoneController.text.isNotEmpty &&
            passwordController.text.isNotEmpty &&
            _isValidEmail(emailController.text);
      case 1:
        return otpController.text.length == 6;
      case 2:
        return saloonNameController.text.isNotEmpty &&
            saloonAddressController.text.isNotEmpty &&
            saloonDomainController.text.isNotEmpty;
      case 3:
        return state.openHour.isNotEmpty &&
            state.closingHour.isNotEmpty &&
            saloonDescriptionController.text.isNotEmpty;
      default:
        return false;
    }
  }

  void _validateCurrentStep(SaloonRegistrationState state) {
    switch (state.currentStep) {
      case 0:
        nameFormKey.currentState?.validate();
        emailFormKey.currentState?.validate();
        phoneFormKey.currentState?.validate();
        passwordFormKey.currentState?.validate();
        break;
      case 1:
        otpFormKey.currentState?.validate();
        break;
      case 2:
        saloonNameFormKey.currentState?.validate();
        saloonAddressFormKey.currentState?.validate();
        saloonDomainFormKey.currentState?.validate();
        break;
      case 3:
        saloonDescriptionFormKey.currentState?.validate();
        break;
    }
  }

  void _triggerValidationAndUpdateUI() {
    // Trigger validation for all fields in step 0
    if (nameFormKey.currentState != null) {
      nameFormKey.currentState!.validate();
    }
    if (emailFormKey.currentState != null) {
      emailFormKey.currentState!.validate();
    }
    if (phoneFormKey.currentState != null) {
      phoneFormKey.currentState!.validate();
    }
    if (passwordFormKey.currentState != null) {
      passwordFormKey.currentState!.validate();
    }

    // Force UI rebuild to show validation errors
    setState(() {});
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^[0-9]{10}$').hasMatch(cleanPhone);
  }

  Widget _buildStepper(BuildContext context, SaloonRegistrationState state) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepIndicator(
              context, 0, state.currentStep >= 0, state.currentStep == 0),
          const SizedBox(width: 8),
          _buildStepIndicator(
              context, 1, state.currentStep >= 1, state.currentStep == 1),
          const SizedBox(width: 8),
          _buildStepIndicator(
              context, 2, state.currentStep >= 2, state.currentStep == 2),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
      BuildContext context, int stepNumber, bool isCompleted, bool isCurrent) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent || isCompleted
            ? Colors.white
            : Colors.white.withOpacity(0.3),
      ),
    );
  }
}
