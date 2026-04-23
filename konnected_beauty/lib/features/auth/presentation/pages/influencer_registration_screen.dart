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
import '../../../../widgets/forms/custom_dropdown.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'welcome_screen.dart';
import 'stripe_onboarding_webview_screen.dart';
import 'registration_success_screen.dart';
import '../../../influencer/presentation/pages/influencer_home_screen.dart';

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

  // Flag to ensure social media controllers are set up only once
  bool _socialMediaControllersSetup = false;

  // Flag to prevent multiple OTP resend requests
  bool _isResendRequestInProgress = false;

  // Flag to prevent multiple Stripe WebView openings
  bool _stripeWebViewOpened = false;
  // Flag to track if automatic opening has already happened (prevents auto-reopening after return)
  bool _hasAutoOpenedOnce = false;

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

  // French departments (wilayas) for zone dropdown
  final List<String> frenchDepartments = [
    'Paris',
    'Lyon',
    'Marseille',
    'Toulouse',
    'Nice',
    'Nantes',
    'Strasbourg',
    'Montpellier',
    'Bordeaux',
    'Lille',
    'Rennes',
    'Reims',
    'Saint-Étienne',
    'Toulon',
    'Le Havre',
    'Grenoble',
    'Dijon',
    'Angers',
    'Villeurbanne',
    'Le Mans',
    'Aix-en-Provence',
    'Brest',
    'Nîmes',
    'Limoges',
    'Clermont-Ferrand',
    'Tours',
    'Amiens',
    'Perpignan',
    'Metz',
    'Besançon',
    'Boulogne-Billancourt',
    'Orléans',
    'Mulhouse',
    'Rouen',
    'Saint-Denis',
    'Caen',
    'Argenteuil',
    'Saint-Paul',
    'Montreuil',
    'Nancy',
    'Roubaix',
    'Tourcoing',
    'Nanterre',
    'Avignon',
    'Vitry-sur-Seine',
    'Créteil',
    'Dunkerque',
    'Poitiers',
    'Asnières-sur-Seine',
    'Courbevoie',
    'Versailles',
    'Colombes',
    'Fort-de-France',
    'Cayenne',
    'Saint-Pierre',
    'Saint-Denis (Réunion)',
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
        final selectedFile = File(pickedFile.path);
        print('🖼️ === PROFILE PICTURE SELECTED ===');
        print('📁 File path: ${pickedFile.path}');
        print('📁 File exists: ${await selectedFile.exists()}');
        print('📁 File size: ${await selectedFile.length()} bytes');

        setState(() {
          _selectedImage = selectedFile;
        });

        print('🖼️ _selectedImage set to: $_selectedImage');
        print('🖼️ _selectedImage path: ${_selectedImage?.path}');

        // Update bloc state with the selected image
        context.read<InfluencerRegistrationBloc>().add(
              UpdateProfileInfo(
                pseudo: pseudoController.text,
                bio: bioController.text,
                zone: zoneController.text,
                profilePicture: selectedFile,
              ),
            );

        print(
            '🔄 BLoC UpdateProfileInfo event sent with profilePicture: $selectedFile');
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
    phoneController = TextEditingController(text: '+33');
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
            profilePicture: _selectedImage, // ✅ Include current profile picture
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
              profilePicture:
                  _selectedImage, // ✅ Include current profile picture
            ));
      });
    });

    zoneController.addListener(() {
      context.read<InfluencerRegistrationBloc>().add(UpdateProfileInfo(
            pseudo: pseudoController.text,
            bio: bioController.text,
            zone: zoneController.text,
            profilePicture: _selectedImage, // ✅ Include current profile picture
          ));
    });

    // Social media controllers will be set up in BlocListener when bloc becomes available

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

  void _setupSocialMediaControllers() {
    print('🔧 === SETTING UP SOCIAL MEDIA CONTROLLERS ===');

    // Remove existing listeners first to avoid duplicates
    instagramController.removeListener(_onInstagramChanged);
    tiktokController.removeListener(_onTiktokChanged);
    youtubeController.removeListener(_onYoutubeChanged);

    // Add new listeners
    instagramController.addListener(_onInstagramChanged);
    tiktokController.addListener(_onTiktokChanged);
    youtubeController.addListener(_onYoutubeChanged);

    print('✅ Social media controllers setup complete');
  }

  void _onInstagramChanged() {
    print('📱 === INSTAGRAM CONTROLLER LISTENER ===');
    print('📱 Instagram text changed to: "${instagramController.text}"');
    print('📱 TikTok text: "${tiktokController.text}"');
    print('📱 YouTube text: "${youtubeController.text}"');

    if (mounted) {
      final bloc = context.read<InfluencerRegistrationBloc>();
      bloc.add(UpdateSocials(
        instagram: instagramController.text,
        tiktok: tiktokController.text,
        youtube: youtubeController.text,
      ));
    }
  }

  void _onTiktokChanged() {
    print('📱 === TIKTOK CONTROLLER LISTENER ===');
    print('📱 Instagram text: "${instagramController.text}"');
    print('📱 TikTok text changed to: "${tiktokController.text}"');
    print('📱 YouTube text: "${youtubeController.text}"');

    if (mounted) {
      final bloc = context.read<InfluencerRegistrationBloc>();
      bloc.add(UpdateSocials(
        instagram: instagramController.text,
        tiktok: tiktokController.text,
        youtube: youtubeController.text,
      ));
    }
  }

  void _onYoutubeChanged() {
    print('📱 === YOUTUBE CONTROLLER LISTENER ===');
    print('📱 Instagram text: "${instagramController.text}"');
    print('📱 TikTok text: "${tiktokController.text}"');
    print('📱 YouTube text changed to: "${youtubeController.text}"');

    if (mounted) {
      final bloc = context.read<InfluencerRegistrationBloc>();
      bloc.add(UpdateSocials(
        instagram: instagramController.text,
        tiktok: tiktokController.text,
        youtube: youtubeController.text,
      ));
    }
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
                print('🎭 === BLOC LISTENER TRIGGERED ===');
                print('📱 Current Step: ${state.currentStep}');
                print('🎯 State Type: ${state.runtimeType}');

                // Handle success messages
                if (state is InfluencerRegistrationSuccess) {
                  print('🎉 === INFLUENCER REGISTRATION SUCCESS ===');
                  print('📱 Current Step: ${state.currentStep}');
                  print('💬 Success Message: ${state.successMessage}');
                  print('🎯 Navigating to step: ${state.currentStep}');

                  // Stripe skipped: go straight to influencer home
                  if (state.successMessage == 'stripe_onboarding_skipped') {
                    print(
                        '🏠 === STRIPE SKIPPED - NAVIGATING TO INFLUENCER HOME ===');
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const InfluencerHomeScreen(),
                      ),
                      (route) => false,
                    );
                    return;
                  }

                  // Final success (after Stripe onboarding completed)
                  if (state.successMessage == 'Account created successfully!') {
                    print(
                        '🎉 === REGISTRATION COMPLETE - NAVIGATING TO SUCCESS SCREEN ===');

                    // Navigate to success screen first, then to influencer home
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const RegistrationSuccessScreen(
                          userRole: 'influencer',
                        ),
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  } else {
                    // Show the default success message for other steps
                    TopNotificationService.showSuccess(
                      context: context,
                      message: AppTranslations.getString(
                          context, state.successMessage),
                    );
                    print(
                        '✅ Success notification shown, staying on current step');
                  }

                  // Reset resend request flag for OTP resend success
                  if (state.successMessage == 'otp_resent_success') {
                    _isResendRequestInProgress = false;
                  }

                  return;
                }

                // Handle step changes for navigation (regular state, not success state)
                if (state.currentStep == 3) {
                  print('📱 === STEP CHANGED TO SOCIALS (3) ===');
                  print('🎯 UI should now show social media step');
                  print('🔄 This is a regular state change, not success state');
                }

                // Handle error messages with top notifications
                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  print('❌ === SHOWING ERROR NOTIFICATION ===');
                  print('💬 Error Message: ${state.errorMessage}');
                  TopNotificationService.showError(
                    context: context,
                    message:
                        AppTranslations.getString(context, state.errorMessage!),
                  );

                  // Reset resend request flag for OTP resend errors
                  if (state.errorMessage!.contains('OTP') ||
                      state.errorMessage!.contains('resend')) {
                    _isResendRequestInProgress = false;
                  }
                }
              },
              child: BlocBuilder<InfluencerRegistrationBloc,
                  InfluencerRegistrationState>(
                buildWhen: (previous, current) {
                  print('🔍 === BLOC BUILDER BUILD WHEN ===');
                  print('📱 Previous Step: ${previous.currentStep}');
                  print('📱 Current Step: ${current.currentStep}');
                  print('🎯 Previous State Type: ${previous.runtimeType}');
                  print('🎯 Current State Type: ${current.runtimeType}');
                  print(
                      '🔄 Should rebuild: ${previous.currentStep != current.currentStep || previous.runtimeType != current.runtimeType}');
                  return true; // Always rebuild for debugging
                },
                builder: (context, state) {
                  print('🎭 === BLOC BUILDER REBUILD ===');
                  print('📱 Current Step: ${state.currentStep}');
                  print('🎯 State Type: ${state.runtimeType}');

                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header (hide for Stripe step)
                        if (state.currentStep != 4) ...[
                          _buildHeader(),
                          const SizedBox(height: 20),
                        ],

                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStepContent(context, state),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Button
                        _buildBottomButton(context, state),
                        // Add extra padding for keyboard
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
          AppTranslations.getString(
              context, 'complete_influencer_registration'),
          style: AppTheme.subtitleStyle,
        ),
        // Add step counter for debugging
      ],
    );
  }

  Widget _buildStepper(
      BuildContext context, InfluencerRegistrationState state) {
    print('🎯 === BUILDING STEPPER ===');
    print('📱 Current Step: ${state.currentStep}');
    print(
        '🎨 Step indicators: 0:${state.currentStep >= 0}, 1:${state.currentStep >= 1}, 2:${state.currentStep >= 2}, 3:${state.currentStep >= 3}');

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
          const SizedBox(width: 8),
          _buildStepIndicator(
              context, 4, state.currentStep >= 4, state.currentStep == 4),
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
      print('🎭 === BUILDING STEP CONTENT ===');
      print('📱 Current Step: ${state.currentStep}');
      print('🎯 Building step: ${state.currentStep}');

      switch (state.currentStep) {
        case 0:
          print('📝 Building Personal Information Step');
          return _buildPersonalInformationStep(context, state);
        case 1:
          print('🔐 Building OTP Verification Step');
          return _buildOtpVerificationStep(context, state);
        case 2:
          print('👤 Building Influencer Profile Step');
          return _buildInfluencerProfileStep(context, state);
        case 3:
          print('📱 Building Social Media Step');
          return _buildSocialMediaStep(context, state);
        case 4:
          print('💳 Building Stripe Onboarding Step');
          return _buildStripeOnboardingStep(context, state);
        default:
          print('❌ Unknown step: ${state.currentStep}');
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
              Text(
                AppTranslations.getString(context, 'phone_verification'),
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Success message for signup

          CustomTextField(
            label: AppTranslations.getString(context, 'verification_code'),
            placeholder: AppTranslations.getString(context, 'otp_placeholder'),
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) => Validators.validateOtp(value, context),
            autovalidateMode: true,
            formFieldKey: otpFormKey,
            onChanged: (value) {
              context.read<InfluencerRegistrationBloc>().add(UpdateOtp(value));
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: (state.isLoading ||
                    _resendCooldownSeconds > 0 ||
                    _isResendRequestInProgress)
                ? null // Disable tap when loading, in cooldown, or request in progress
                : () {
                    // Prevent multiple rapid clicks
                    if (!_isResendRequestInProgress) {
                      _isResendRequestInProgress = true;

                      // Send OTP resend request
                      context
                          .read<InfluencerRegistrationBloc>()
                          .add(ResendOtp());
                      _resetResendCooldown(); // Reset cooldown after sending

                      // Re-enable after a short delay to prevent spam
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _isResendRequestInProgress = false;
                          });
                        }
                      });
                    }
                  },
            child: Text(
              state.isLoading
                  ? AppTranslations.getString(context, 'resend_code')
                  : _resendCooldownSeconds > 0
                      ? '${AppTranslations.getString(context, 'resend_code')} (${_resendCooldownSeconds}s)'
                      : _isResendRequestInProgress
                          ? '${AppTranslations.getString(context, 'resend_code')}...'
                          : AppTranslations.getString(context, 'resend_code'),
              style: TextStyle(
                color: (state.isLoading ||
                        _resendCooldownSeconds > 0 ||
                        _isResendRequestInProgress)
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
        const SizedBox(height: 15),

        // Debug: Show current language and translation

        const SizedBox(height: 8),

        // Profile Picture Section
        Text(
          AppTranslations.getString(context, 'profile_picture'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _selectedImage != null
                  ? Row(
                      children: [
                        // Small preview image
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.borderColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(
                              _selectedImage!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Image name and info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getImageDisplayName(_selectedImage!.path),
                                style: const TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.getString(
                                    context, 'tap_to_change'),
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Change icon
                        Icon(
                          LucideIcons.edit,
                          color: AppTheme.textSecondaryColor,
                          size: 20,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          LucideIcons.upload,
                          color: AppTheme.textSecondaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppTranslations.getString(
                                context, 'upload_your_profile_picture'),
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    profilePicture:
                        _selectedImage, // ✅ Include current profile picture
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
                    profilePicture:
                        _selectedImage, // ✅ Include current profile picture
                  ),
                );
          },
        ),
        const SizedBox(height: 20),

        // Zone Field
        CustomDropdown(
          label: AppTranslations.getString(context, 'zone'),
          placeholder: AppTranslations.getString(context, 'select_your_zone'),
          items: frenchDepartments,
          selectedValue:
              zoneController.text.isNotEmpty ? zoneController.text : null,
          onChanged: (value) {
            if (value != null) {
              zoneController.text = value;
              context.read<InfluencerRegistrationBloc>().add(
                    UpdateProfileInfo(
                      pseudo: pseudoController.text,
                      bio: bioController.text,
                      zone: value,
                      profilePicture:
                          _selectedImage, // ✅ Include current profile picture
                    ),
                  );
            }
          },
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  String _getImageDisplayName(String imagePath) {
    final fileName = imagePath.split('/').last;
    // If filename is too long, truncate it
    if (fileName.length > 25) {
      return '${fileName.substring(0, 22)}...';
    }
    return fileName;
  }

  Widget _buildSocialMediaStep(
      BuildContext context, InfluencerRegistrationState state) {
    // Set up social media controllers when this step is built
    if (!_socialMediaControllersSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_socialMediaControllersSetup) {
          _setupSocialMediaControllers();
          _socialMediaControllersSetup = true;
        }
      });
    }

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

        // Help text
        Text(
          'Please provide at least one social media link to continue.',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),

        // Instagram Field
        CustomTextField(
          label: AppTranslations.getString(context, 'instagram'),
          placeholder:
              AppTranslations.getString(context, 'enter_instagram_link'),
          controller: instagramController,
          keyboardType: TextInputType.url,
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(
                  UpdateSocials(
                    instagram: value,
                    tiktok: tiktokController.text,
                    youtube: youtubeController.text,
                  ),
                );
          },
        ),
        const SizedBox(height: 20),

        // TikTok Field (Optional)
        CustomTextField(
          label:
              '${AppTranslations.getString(context, 'tiktok')} (${AppTranslations.getString(context, 'optional')})',
          placeholder: AppTranslations.getString(context, 'enter_tiktok_link'),
          controller: tiktokController,
          keyboardType: TextInputType.url,
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(
                  UpdateSocials(
                    instagram: instagramController.text,
                    tiktok: value,
                    youtube: youtubeController.text,
                  ),
                );
          },
        ),
        const SizedBox(height: 20),

        // YouTube Field (Optional)
        CustomTextField(
          label:
              '${AppTranslations.getString(context, 'youtube')} (${AppTranslations.getString(context, 'optional')})',
          placeholder: AppTranslations.getString(context, 'enter_youtube_link'),
          controller: youtubeController,
          keyboardType: TextInputType.url,
          onChanged: (value) {
            context.read<InfluencerRegistrationBloc>().add(
                  UpdateSocials(
                    instagram: instagramController.text,
                    tiktok: tiktokController.text,
                    youtube: value,
                  ),
                );
          },
        ),
        const SizedBox(height: 5),
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
                  print('Continue button pressed for step 0');
                  print('📧 Email: ${emailController.text}');
                  print('📧 Email validation: ${_isValidEmail(emailController.text)}');
                  print('📧 Form validation: ${emailFormKey.currentState?.validate()}');
                  // First trigger validation to show inline errors
                  _triggerValidationAndUpdateUI();

                  // Check if we can proceed after validation
                  final canProceed = _canProceedToNextStep(state);
                  print('✅ Can proceed: $canProceed');
                  print('  - Name: ${nameController.text.isNotEmpty}');
                  print('  - Email: ${emailController.text.isNotEmpty} && ${_isValidEmail(emailController.text)}');
                  print('  - Phone: ${phoneController.text.isNotEmpty}');
                  print('  - Password: ${passwordController.text.isNotEmpty}');
                  
                  if (canProceed) {
                    // Auto-convert 06 or 07 to +33 before sending
                    String phoneValue = phoneController.text.trim();
                    if (phoneValue.startsWith('06') ||
                        phoneValue.startsWith('07')) {
                      // Take only the first 10 digits (remove the 0 and take 9 more digits)
                      // This handles cases where user might have typed 11 digits by mistake
                      String digits =
                          phoneValue.substring(1); // Remove the leading 0
                      if (digits.length > 9) {
                        digits = digits.substring(
                            0, 9); // Take only 9 digits after the 0
                      }
                      phoneValue = '+33$digits';
                    }
                    // Always update the state with the phone number (whether it's +33 or converted from 06/07)
                    context
                        .read<InfluencerRegistrationBloc>()
                        .add(UpdatePersonalInfo(
                          name: nameController.text,
                          email: emailController.text,
                          phone: phoneValue,
                          password: passwordController.text,
                        ));
                    context
                        .read<InfluencerRegistrationBloc>()
                        .add(SubmitSignup());
                  }
                },
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
                  print('🔘 === SOCIAL MEDIA CONTINUE BUTTON PRESSED ===');
                  print('📱 Instagram text: "${instagramController.text}"');
                  print('📱 TikTok text: "${tiktokController.text}"');
                  print('📱 YouTube text: "${youtubeController.text}"');

                  _validateCurrentStep(state);
                  final canProceed = _canProceedToNextStep(state);
                  print('🎯 Can proceed to next step: $canProceed');

                  if (canProceed) {
                    print('✅ Proceeding with social media submission');
                    // Ensure bloc state is up-to-date before submit
                    context.read<InfluencerRegistrationBloc>().add(
                          UpdateSocials(
                            instagram: instagramController.text,
                            tiktok: tiktokController.text,
                            youtube: youtubeController.text,
                          ),
                        );
                    context
                        .read<InfluencerRegistrationBloc>()
                        .add(SubmitSocials());
                  } else {
                    print('❌ Cannot proceed - validation failed');
                  }
                },
          isLoading: state.isLoading,
        );
      case 4:
        // Single "Connect with Stripe" button
        // Automatically open WebView when URL is ready (only once, never again after return)
        if (state.stripeOnboardingUrl != null &&
            !state.isLoading &&
            !_stripeWebViewOpened &&
            !_hasAutoOpenedOnce) {
          _stripeWebViewOpened = true;
          _hasAutoOpenedOnce = true; // Mark that auto-opening has happened
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && state.stripeOnboardingUrl != null) {
              final url = state.stripeOnboardingUrl!;
              print('🌐 Auto-opening Stripe onboarding URL in WebView: $url');
              final registrationContext = context;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StripeOnboardingWebViewScreen(
                    onboardingUrl: url,
                    accountId: state.stripeAccountId,
                    onSuccess: () {
                      print('✅ Stripe onboarding completed and verified');
                      registrationContext
                          .read<InfluencerRegistrationBloc>()
                          .add(CompleteStripeOnboarding());
                    },
                    onFailure: () {
                      print('❌ Stripe onboarding had issues');
                      registrationContext
                          .read<InfluencerRegistrationBloc>()
                          .add(SkipStripeOnboarding());
                    },
                  ),
                ),
              ).then((_) {
                // Reset flag when user returns from WebView - button becomes clickable again
                // But don't reset _hasAutoOpenedOnce to prevent automatic reopening
                _stripeWebViewOpened = false;
                print('🔄 Reset _stripeWebViewOpened flag - button is clickable again (manual only)');
              });
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectStripeButton(context, state),
            const SizedBox(height: 12),
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      context
                          .read<InfluencerRegistrationBloc>()
                          .add(SkipStripeOnboarding());
                    },
              child: Text(
                AppTranslations.getString(context, 'skip_for_now'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
        // Instagram is required, TikTok and YouTube are optional
        final hasInstagram = instagramController.text.isNotEmpty;
        final hasTiktok = tiktokController.text.isNotEmpty;
        final hasYoutube = youtubeController.text.isNotEmpty;
        final canProceed = hasInstagram; // Only Instagram is required

        print('🔍 === SOCIAL MEDIA VALIDATION ===');
        print(
            '📱 Instagram: "${instagramController.text}" (${hasInstagram ? "Valid" : "Empty"})');
        print(
            '📱 TikTok: "${tiktokController.text}" (${hasTiktok ? "Valid" : "Empty"} - Optional)');
        print(
            '📱 YouTube: "${youtubeController.text}" (${hasYoutube ? "Valid" : "Empty"} - Optional)');
        print('🎯 Can proceed: $canProceed');

        return canProceed;
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
    // Accept emails in format: something@something.something
    // Allows hyphens in domain and TLD, and TLDs of any length (e.g., .paris, .photography)
    // Note: Hyphen must be at the end of character class to be treated as literal
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]+$').hasMatch(email);
  }

  Widget _buildStripeOnboardingStep(
      BuildContext context, InfluencerRegistrationState state) {
    // Don't automatically start - wait for user to click button

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title: "Link your Stripe"
        Text(
          AppTranslations.getString(context, 'link_your_stripe'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Description text
        Text(
          AppTranslations.getString(context, 'stripe_onboarding_description'),
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 100),
        // Logos: Konected and Stripe - centered
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 100),
                  // Konected Logo
                  Image.asset(
                    'assets/images/Konected beauty - Logo white.png',
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ],
              ),

              // Link icon (rotated -180 degrees)
              Transform.rotate(
                angle: -3.14159, // -180 degrees in radians
                child: Icon(
                  LucideIcons.link,
                  color: AppTheme.textSecondaryColor,
                  size: 24,
                ),
              ),
              // Stripe logo and text
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Stripe logo (stylized "S")
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Shadow/background "S"
                    ], // Main "S"
                  ),
                  // "stripe" text in blue
                  Text(
                    'stripe',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF635BFF), // Stripe blue
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(width: 50),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectStripeButton(
      BuildContext context, InfluencerRegistrationState state) {
    final isLoading = state.isLoading;
    final hasUrl = state.stripeOnboardingUrl != null;

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading || (hasUrl && _stripeWebViewOpened))
            ? null
            : () {
                if (hasUrl) {
                  // URL exists, open WebView manually (when user clicks after returning)
                  _stripeWebViewOpened = true;
                  final url = state.stripeOnboardingUrl!;
                  print('🌐 Manually opening Stripe onboarding URL in WebView: $url');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StripeOnboardingWebViewScreen(
                        onboardingUrl: url,
                        accountId: state.stripeAccountId,
                        onSuccess: () {
                          print('✅ Stripe onboarding completed and verified');
                          context
                              .read<InfluencerRegistrationBloc>()
                              .add(CompleteStripeOnboarding());
                        },
                        onFailure: () {
                          print('❌ Stripe onboarding had issues');
                          context
                              .read<InfluencerRegistrationBloc>()
                              .add(SkipStripeOnboarding());
                        },
                      ),
                    ),
                  ).then((_) {
                    // Reset flag when user returns from WebView - button becomes clickable again
                    _stripeWebViewOpened = false;
                    print('🔄 Reset _stripeWebViewOpened flag - button is clickable again');
                  });
                } else {
                  // URL doesn't exist, generate it
                  print('🔄 Starting Stripe onboarding to generate link...');
                  context
                      .read<InfluencerRegistrationBloc>()
                      .add(StartStripeOnboarding());
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.getString(context, 'connect_with_stripe'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stripe "S" icon (black)
                  Text(
                    'S',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppTranslations.getString(context, 'connect_with_stripe'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Custom painter for Stripe logo
class StripeLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.12;

    // Draw central circle (larger)
    canvas.drawCircle(center, baseRadius * 1.2, paint);

    // Draw top-left petal
    final topLeftRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center:
            Offset(center.dx - baseRadius * 0.8, center.dy - baseRadius * 1.5),
        width: baseRadius * 1.6,
        height: baseRadius * 2.2,
      ),
      Radius.circular(baseRadius * 0.8),
    );
    canvas.drawRRect(topLeftRect, paint);

    // Draw top-right petal
    final topRightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center:
            Offset(center.dx + baseRadius * 0.8, center.dy - baseRadius * 1.5),
        width: baseRadius * 1.6,
        height: baseRadius * 2.2,
      ),
      Radius.circular(baseRadius * 0.8),
    );
    canvas.drawRRect(topRightRect, paint);

    // Draw bottom-left petal
    final bottomLeftRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center:
            Offset(center.dx - baseRadius * 0.8, center.dy + baseRadius * 1.5),
        width: baseRadius * 1.6,
        height: baseRadius * 2.2,
      ),
      Radius.circular(baseRadius * 0.8),
    );
    canvas.drawRRect(bottomLeftRect, paint);

    // Draw bottom-right petal
    final bottomRightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center:
            Offset(center.dx + baseRadius * 0.8, center.dy + baseRadius * 1.5),
        width: baseRadius * 1.6,
        height: baseRadius * 2.2,
      ),
      Radius.circular(baseRadius * 0.8),
    );
    canvas.drawRRect(bottomRightRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
