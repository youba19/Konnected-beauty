import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/influencer_registration/influencer_registration_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'welcome_screen.dart';

class InfluencerRegistrationScreen extends StatefulWidget {
  final InfluencerRegistrationBloc? existingBloc;
  final int? initialStep;

  const InfluencerRegistrationScreen({
    super.key,
    this.existingBloc,
    this.initialStep,
  });

  @override
  State<InfluencerRegistrationScreen> createState() =>
      _InfluencerRegistrationScreenState();
}

class _InfluencerRegistrationScreenState
    extends State<InfluencerRegistrationScreen> with TickerProviderStateMixin {
  // Local TextEditingControllers
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController otpController;
  late TextEditingController pseudoController;
  late TextEditingController bioController;
  late TextEditingController zoneController;
  late TextEditingController instagramController;
  late TextEditingController tiktokController;
  late TextEditingController youtubeController;

  // Form keys for validation
  final GlobalKey<FormFieldState> nameFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> emailFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> phoneFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> passwordFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> otpFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> pseudoFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> bioFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> zoneFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> instagramFormKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> tiktokFormKey = GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> youtubeFormKey = GlobalKey<FormFieldState>();

  // Password visibility state
  bool isPasswordVisible = false;

  // Timer for debouncing bio updates
  Timer? _bioDebounceTimer;

  // Resend OTP cooldown timer
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 0;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  // Zone options for dropdown
  final List<String> zoneOptions = [
    'Young people',
    'Adults',
    'Teenagers',
    'Seniors',
    'All ages',
  ];

  // Image picker methods
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Update bloc state with the selected image
        context.read<InfluencerRegistrationBloc>().add(
              UpdateProfileInfo(
                pseudo: pseudoController.text,
                bio: bioController.text,
                zone: zoneController.text,
                profilePicture: pickedFile.path,
              ),
            );
      }
    } catch (e) {
      print('Error picking image: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppTranslations.getString(context, 'select_image_source'),
            style: const TextStyle(color: AppTheme.textPrimaryColor),
          ),
          backgroundColor: AppTheme.scaffoldBackground,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(LucideIcons.camera, color: AppTheme.accentColor),
                title: Text(
                  AppTranslations.getString(context, 'camera'),
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(LucideIcons.image, color: AppTheme.accentColor),
                title: Text(
                  AppTranslations.getString(context, 'gallery'),
                  style: const TextStyle(color: AppTheme.accentColor),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(LucideIcons.trash2,
                      color: AppTheme.errorColor),
                  title: Text(
                    AppTranslations.getString(context, 'remove_image'),
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });

    // Update bloc state to remove profile picture
    context.read<InfluencerRegistrationBloc>().add(
          UpdateProfileInfo(
            pseudo: pseudoController.text,
            bio: bioController.text,
            zone: zoneController.text,
            profilePicture: null,
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    otpController = TextEditingController();
    pseudoController = TextEditingController();
    bioController = TextEditingController();
    zoneController = TextEditingController();
    instagramController = TextEditingController();
    tiktokController = TextEditingController();
    youtubeController = TextEditingController();

    // Add listeners to sync with Bloc state
    nameController.addListener(() {
      context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
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
      context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
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
      context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
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
      context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
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
      print('=== OTP CONTROLLER LISTENER ===');
      print('OTP Controller text changed to: "${otpController.text}"');
      print('================================');
      context
          .read<InfluencerRegistrationBloc>()
          .add(UpdateOtp(otpController.text));
    });

    pseudoController.addListener(() {
      context.read<InfluencerRegistrationBloc>().add(UpdateProfileInfo(
            pseudo: pseudoController.text,
            bio: bioController.text,
            zone: zoneController.text,
          ));
    });

    bioController.addListener(() {
      // Debounce bio updates to avoid too many API calls
      _bioDebounceTimer?.cancel();
      _bioDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        context.read<InfluencerRegistrationBloc>().add(UpdateProfileInfo(
              pseudo: pseudoController.text,
              bio: bioController.text,
              zone: zoneController.text,
            ));
      });
    });

    zoneController.addListener(() {
      context.read<InfluencerRegistrationBloc>().add(UpdateProfileInfo(
            pseudo: pseudoController.text,
            bio: bioController.text,
            zone: zoneController.text,
          ));
    });

    instagramController.addListener(() {
      context.read<InfluencerRegistrationBloc>().add(UpdateSocials(
            instagram: instagramController.text,
            tiktok: tiktokController.text,
            youtube: youtubeController.text,
          ));
    });

    tiktokController.addListener(() {
      context.read<InfluencerRegistrationBloc>().add(UpdateSocials(
            instagram: instagramController.text,
            tiktok: tiktokController.text,
            youtube: youtubeController.text,
          ));
    });

    youtubeController.addListener(() {
      context.read<InfluencerRegistrationBloc>().add(UpdateSocials(
            instagram: instagramController.text,
            tiktok: tiktokController.text,
            youtube: youtubeController.text,
          ));
    });

    // Start initial cooldown timer
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendCooldownSeconds = 30; // 30 seconds cooldown
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCooldownSeconds > 0) {
            _resendCooldownSeconds--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  void _resetResendCooldown() {
    _resendCooldownTimer?.cancel();
    _startResendCooldown();
  }

  void _showErrorNotification(String message) {
    TopNotificationService.showError(
      context: context,
      message: message,
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    pseudoController.dispose();
    bioController.dispose();
    zoneController.dispose();
    instagramController.dispose();
    tiktokController.dispose();
    youtubeController.dispose();

    // Cancel timers
    _bioDebounceTimer?.cancel();
    _resendCooldownTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          widget.existingBloc ??
          InfluencerRegistrationBloc(initialStep: widget.initialStep),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFF1E1E1E),
              Color(0xFF2D2D2D),
              Color(0xFF3D3D3D),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: BlocBuilder<InfluencerRegistrationBloc,
                InfluencerRegistrationState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(LucideIcons.arrowLeft,
                      color: AppTheme.textPrimaryColor),
                  onPressed: () async {
                    // Dismiss keyboard before going back
                    final currentStep = state.currentStep;
                    final bloc = context.read<InfluencerRegistrationBloc>();
                    final navigator = Navigator.of(context);
                    FocusScope.of(context).unfocus();
                    await Future.delayed(const Duration(milliseconds: 100));

                    if (mounted) {
                      if (currentStep > 0) {
                        // Go to previous step within registration flow
                        bloc.add(PreviousStep());
                      } else {
                        // Go back to welcome screen if we're on the first step
                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const WelcomeScreen(),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
            actions: [
              BlocBuilder<InfluencerRegistrationBloc,
                  InfluencerRegistrationState>(
                builder: (context, state) => _buildStepper(context, state),
              ),
            ],
          ),
          body: SafeArea(
            child: BlocListener<InfluencerRegistrationBloc,
                InfluencerRegistrationState>(
              listener: (context, state) {
                // Handle success messages
                if (state is InfluencerRegistrationSuccess) {
                  TopNotificationService.showSuccess(
                    context: context,
                    message: state.successMessage,
                  );
                  return;
                }

                // Handle error messages (but not success messages that are handled by top banner)
                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty &&
                    !state.errorMessage!
                        .toLowerCase()
                        .contains('successfully') &&
                    !state.errorMessage!
                        .toLowerCase()
                        .contains('already verified')) {
                  _showErrorNotification(state.errorMessage!);
                }

                // OTP validation success is handled by the top drop banner
                // No need to show additional SnackBar messages for OTP verification
              },
              child: BlocBuilder<InfluencerRegistrationBloc,
                  InfluencerRegistrationState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          color: Colors.transparent,
                          child: _buildHeader(),
                        ),
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
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              ),
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
          AppTranslations.getString(context, 'create_influencer_account'),
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

  Widget _buildStepper(
      BuildContext context, InfluencerRegistrationState state) {
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
          const SizedBox(width: 8),
          _buildStepIndicator(
              context, 3, state.currentStep >= 3, state.currentStep == 3),
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
            ? AppTheme.accentColor
            : AppTheme.accentColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildStepContent(
      BuildContext context, InfluencerRegistrationState state) {
    try {
      switch (state.currentStep) {
        case 0:
          return _buildPersonalInformationStep(context, state);
        case 1:
          return _buildOtpVerificationStep(context, state);
        case 2:
          return _buildInfluencerProfileStep(context, state);
        case 3:
          return _buildSocialMediaStep(context, state);
        default:
          return const SizedBox.shrink();
      }
    } catch (e) {
      // Return a safe fallback widget if there's any error
      return Center(
        child: Text(
          AppTranslations.getString(context, 'something_went_wrong'),
          style: const TextStyle(color: AppTheme.accentColor),
        ),
      );
    }
  }

  Widget _buildPersonalInformationStep(
      BuildContext context, InfluencerRegistrationState state) {
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
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
                  name: value,
                  email: emailController.text,
                  phone: phoneController.text,
                  password: passwordController.text,
                ));
          },
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
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
                  name: nameController.text,
                  email: value,
                  phone: phoneController.text,
                  password: passwordController.text,
                ));
          },
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
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
                  name: nameController.text,
                  email: emailController.text,
                  phone: value,
                  password: passwordController.text,
                ));
          },
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
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(UpdatePersonalInfo(
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  password: value,
                ));
          },
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
        // No extra space needed when using MainAxisAlignment.end
      ],
    );
  }

  Widget _buildOtpVerificationStep(
      BuildContext context, InfluencerRegistrationState state) {
    // Debug: Check OTP controller value when step is loaded
    print('=== OTP STEP DEBUG ===');
    print('OTP Controller text: "${otpController.text}"');
    print('State OTP: "${state.otp}"');
    print('======================');

    // Manually sync OTP controller with state when step is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (otpController.text.isNotEmpty && otpController.text != state.otp) {
        print('=== MANUAL SYNC TRIGGERED ===');
        context
            .read<InfluencerRegistrationBloc>()
            .add(UpdateOtp(otpController.text));
      }
    });

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
              color: AppTheme.successLightColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
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
            onTap: (state.isLoading || _resendCooldownSeconds > 0)
                ? null // Disable tap when loading or in cooldown
                : () {
                    context.read<InfluencerRegistrationBloc>().add(ResendOtp());
                    _resetResendCooldown(); // Reset cooldown after sending
                  },
            child: Text(
              state.isLoading
                  ? AppTranslations.getString(context, 'resend_code')
                  : _resendCooldownSeconds > 0
                      ? '${AppTranslations.getString(context, 'resend_code')} (${_resendCooldownSeconds}s)'
                      : AppTranslations.getString(context, 'resend_code'),
              style: TextStyle(
                color: (state.isLoading || _resendCooldownSeconds > 0)
                    ? AppTheme.textSecondaryColor.withOpacity(0.7)
                    : AppTheme.accentColor,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          // Add extra space for keyboard
          // No extra space needed when using MainAxisAlignment.end
        ],
      ),
    );
  }

  Widget _buildInfluencerProfileStep(
      BuildContext context, InfluencerRegistrationState state) {
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
              AppTranslations.getString(context, 'your_information'),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Debug: Show current language and translation

        const SizedBox(height: 8),

        // Profile Picture Section
        Text(
          AppTranslations.getString(context, 'profile_picture'),
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedImage != null
                ? Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.getString(context, 'tap_to_change'),
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        LucideIcons.upload,
                        color: AppTheme.textSecondaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.getString(
                            context, 'upload_your_profile_picture'),
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTranslations.getString(context, 'tap_to_select'),
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Pseudo Field
        CustomTextField(
          label: AppTranslations.getString(context, 'pseudo'),
          placeholder:
              AppTranslations.getString(context, 'enter_your_special_name'),
          controller: pseudoController,
          validator: (value) =>
              Validators.validateRequired(value, 'pseudo', context),
          autovalidateMode: true,
          formFieldKey: pseudoFormKey,
          isError: pseudoFormKey.currentState?.hasError ?? false,
          errorMessage: pseudoFormKey.currentState?.hasError == true
              ? Validators.validateRequired(
                  pseudoController.text, 'pseudo', context)
              : null,
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(
                  UpdateProfileInfo(
                    pseudo: value,
                    bio: bioController.text,
                    zone: zoneController.text,
                    profilePicture: null, // Will be set when image is picked
                  ),
                );
          },
        ),
        const SizedBox(height: 20),

        // Bio Field
        CustomTextField(
          label: AppTranslations.getString(context, 'bio'),
          placeholder:
              AppTranslations.getString(context, 'describe_yourself_quickly'),
          controller: bioController,
          validator: (value) => Validators.validateDescription(value, context),
          autovalidateMode: true,
          formFieldKey: bioFormKey,
          isError: bioFormKey.currentState?.hasError ?? false,
          errorMessage: bioFormKey.currentState?.hasError == true
              ? Validators.validateDescription(bioController.text, context)
              : null,
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(
                  UpdateProfileInfo(
                    pseudo: pseudoController.text,
                    bio: value,
                    zone: zoneController.text,
                    profilePicture: null, // Will be set when image is picked
                  ),
                );
          },
        ),
        const SizedBox(height: 20),

        // Zone Field
        CustomTextField(
          label: AppTranslations.getString(context, 'zone'),
          placeholder: AppTranslations.getString(context, 'select_your_zone'),
          controller: zoneController,
          validator: (value) =>
              Validators.validateRequired(value, 'zone', context),
          autovalidateMode: true,
          formFieldKey: zoneFormKey,
          isError: zoneFormKey.currentState?.hasError ?? false,
          errorMessage: zoneFormKey.currentState?.hasError == true
              ? Validators.validateRequired(
                  zoneController.text, 'zone', context)
              : null,
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(
                  UpdateProfileInfo(
                    pseudo: pseudoController.text,
                    bio: bioController.text,
                    zone: value,
                    profilePicture: null, // Will be set when image is picked
                  ),
                );
          },
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildSocialMediaStep(
      BuildContext context, InfluencerRegistrationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.share2,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppTranslations.getString(context, 'social_media'),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Instagram Field
        CustomTextField(
          label: AppTranslations.getString(context, 'instagram'),
          placeholder:
              AppTranslations.getString(context, 'enter_instagram_link'),
          controller: instagramController,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 20),

        // TikTok Field
        CustomTextField(
          label: AppTranslations.getString(context, 'tiktok'),
          placeholder: AppTranslations.getString(context, 'enter_tiktok_link'),
          controller: tiktokController,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 20),

        // YouTube Field
        CustomTextField(
          label: AppTranslations.getString(context, 'youtube'),
          placeholder: AppTranslations.getString(context, 'enter_youtube_link'),
          controller: youtubeController,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBottomButton(
      BuildContext context, InfluencerRegistrationState state) {
    switch (state.currentStep) {
      case 0:
        return CustomButton(
          text: AppTranslations.getString(context, 'continue'),
          onPressed: state.isLoading
              ? () {}
              : () {
                  // First trigger validation to show inline errors
                  _triggerValidationAndUpdateUI();

                  // Check if we can proceed after validation
                  if (_canProceedToNextStep(state)) {
                    context
                        .read<InfluencerRegistrationBloc>()
                        .add(SubmitSignup());
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
                    context.read<InfluencerRegistrationBloc>().add(SubmitOtp());
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
                        .read<InfluencerRegistrationBloc>()
                        .add(SubmitProfileInfo());
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
                        .read<InfluencerRegistrationBloc>()
                        .add(SubmitSocials());
                  }
                },
          isLoading: state.isLoading,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  bool _canProceedToNextStep(InfluencerRegistrationState state) {
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
        return pseudoController.text.isNotEmpty &&
            bioController.text.isNotEmpty &&
            zoneController.text.isNotEmpty;
      case 3:
        return true; // Social media is optional
      default:
        return false;
    }
  }

  void _validateCurrentStep(InfluencerRegistrationState state) {
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
        pseudoFormKey.currentState?.validate();
        bioFormKey.currentState?.validate();
        zoneFormKey.currentState?.validate();
        break;
      case 3:
        // Social media validation is optional
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
}
