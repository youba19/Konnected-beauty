import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/saloon_registration/saloon_registration_bloc.dart';
import '../../../../core/bloc/welcome/welcome_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_button.dart';
import '../../../../widgets/forms/custom_dropdown.dart';
import 'welcome_screen.dart';
import '../../../../core/bloc/language/language_bloc.dart';

class SaloonRegistrationScreen extends StatefulWidget {
  const SaloonRegistrationScreen({super.key});

  @override
  State<SaloonRegistrationScreen> createState() =>
      _SaloonRegistrationScreenState();
}

class _SaloonRegistrationScreenState extends State<SaloonRegistrationScreen> {
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

    // Add listeners to sync with Bloc state
    nameController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
    });

    emailController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
    });

    phoneController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
    });

    passwordController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdatePersonalInfo(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
          ));
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

    saloonDescriptionController.addListener(() {
      context.read<SaloonRegistrationBloc>().add(UpdateSalonProfile(
            description: saloonDescriptionController.text,
            openHour: '', // Will be updated separately
            closingHour: '', // Will be updated separately
          ));
    });
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () async {
            // Dismiss keyboard before going back
            FocusScope.of(context).unfocus();
            await Future.delayed(const Duration(milliseconds: 100));
            // Navigate back to welcome screen with animation skipped
            context.read<WelcomeBloc>().add(SkipLogoAnimation());
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimaryColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return BlocBuilder<SaloonRegistrationBloc, SaloonRegistrationState>(
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
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Step Content
                              _buildStepContent(context, state),
                              // Add extra padding for keyboard
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Button
                      const SizedBox(height: 24),
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getString(context, 'personal_information'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: AppTranslations.getString(context, 'full_name'),
            placeholder:
                AppTranslations.getString(context, 'full_name_placeholder'),
            controller: nameController,
            validator: (value) => Validators.validateName(value, context),
            autovalidateMode: true,
            formFieldKey: nameFormKey,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'email'),
            placeholder:
                AppTranslations.getString(context, 'email_placeholder'),
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.validateEmail(value, context),
            autovalidateMode: true,
            formFieldKey: emailFormKey,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'phone'),
            placeholder:
                AppTranslations.getString(context, 'phone_placeholder'),
            controller: phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) => Validators.validatePhone(value, context),
            autovalidateMode: true,
            formFieldKey: phoneFormKey,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'password'),
            placeholder:
                AppTranslations.getString(context, 'password_placeholder'),
            controller: passwordController,
            isPassword: true,
            validator: (value) => Validators.validatePassword(value, context),
            autovalidateMode: true,
            formFieldKey: passwordFormKey,
            suffixIcon: const Icon(
              Icons.visibility_off,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          // Add extra space for keyboard
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationStep(
      BuildContext context, SaloonRegistrationState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getString(context, 'phone_verification'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
          Text(
            AppTranslations.getString(context, 'salon_information'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: AppTranslations.getString(context, 'name'),
            placeholder: AppTranslations.getString(context, 'name_placeholder'),
            controller: saloonNameController,
            validator: (value) => Validators.validateName(value, context),
            autovalidateMode: true,
            formFieldKey: saloonNameFormKey,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'salon_address'),
            placeholder:
                AppTranslations.getString(context, 'email_placeholder'),
            controller: saloonAddressController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => Validators.validateEmail(value, context),
            autovalidateMode: true,
            formFieldKey: saloonAddressFormKey,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: AppTranslations.getString(context, 'salon_domain_activity'),
            placeholder: '+33-XX-XX-XX-XX',
            controller: saloonDomainController,
            keyboardType: TextInputType.phone,
            validator: (value) => Validators.validatePhone(value, context),
            autovalidateMode: true,
            formFieldKey: saloonDomainFormKey,
          ),
          // Add extra space for keyboard
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSaloonProfileStep(
      BuildContext context, SaloonRegistrationState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getString(context, 'salon_profile'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.uploadedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                state.uploadedImages[index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: AppTheme.secondaryColor,
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  context
                                      .read<SaloonRegistrationBloc>()
                                      .add(RemoveImage(index));
                                },
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 16,
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
                  onChanged: (value) {
                    context
                        .read<SaloonRegistrationBloc>()
                        .add(UpdateOpenHour(value ?? ''));
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
                  onChanged: (value) {
                    context
                        .read<SaloonRegistrationBloc>()
                        .add(UpdateClosingHour(value ?? ''));
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Description Section
          CustomTextField(
            label: AppTranslations.getString(context, 'salon_description'),
            placeholder: AppTranslations.getString(
                context, 'describe_salon_placeholder'),
            controller: saloonDescriptionController,
            validator: (value) =>
                Validators.validateDescription(value, context),
            autovalidateMode: true,
            maxLines: 4,
            formFieldKey: saloonDescriptionFormKey,
          ),
          // Add extra space for keyboard
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
      BuildContext context, SaloonRegistrationState state) {
    switch (state.currentStep) {
      case 0:
        return CustomButton(
          text: AppTranslations.getString(context, 'continue'),
          onPressed: () {
            print('Continue button pressed for step 0');
            _validateCurrentStep(state);
            if (_canProceedToNextStep(state)) {
              print('Calling nextStep');
              context.read<SaloonRegistrationBloc>().add(NextStep());
            } else {
              print('Validation failed');
            }
          },
          leadingIcon: Icons.arrow_forward_ios,
        );
      case 1:
        return CustomButton(
          text: AppTranslations.getString(context, 'submit_continue'),
          onPressed: () {
            _validateCurrentStep(state);
            if (_canProceedToNextStep(state)) {
              context.read<SaloonRegistrationBloc>().add(SubmitOtp());
            }
          },
        );
      case 2:
        return CustomButton(
          text: AppTranslations.getString(context, 'continue'),
          onPressed: () {
            _validateCurrentStep(state);
            if (_canProceedToNextStep(state)) {
              context.read<SaloonRegistrationBloc>().add(NextStep());
            }
          },
        );
      case 3:
        return CustomButton(
          text: AppTranslations.getString(context, 'continue'),
          onPressed: () {
            _validateCurrentStep(state);
            if (_canProceedToNextStep(state)) {
              context.read<SaloonRegistrationBloc>().add(SubmitRegistration());
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
            saloonDomainController.text.isNotEmpty &&
            _isValidEmail(saloonAddressController.text);
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
