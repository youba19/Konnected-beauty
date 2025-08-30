import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/salon_profile/salon_profile_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class SalonProfileDetailsScreen extends StatefulWidget {
  const SalonProfileDetailsScreen({super.key});

  @override
  State<SalonProfileDetailsScreen> createState() =>
      _SalonProfileDetailsScreenState();
}

class _SalonProfileDetailsScreenState extends State<SalonProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing profile data from API
    context.read<SalonProfileBloc>().add(LoadSalonProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> profileData) {
    // Populate controllers with data from API
    _nameController.text = profileData['name'] ?? '';
    _emailController.text = profileData['email'] ?? '';
    _phoneController.text = profileData['phoneNumber'] ?? '';
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Only send fields that have values
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNumber = _phoneController.text.trim();

    // Use BLoC to update profile
    context.read<SalonProfileBloc>().add(UpdateSalonProfile(
          name: name.isNotEmpty ? name : null,
          email: email.isNotEmpty ? email : null,
          phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft,
                color: AppTheme.textPrimaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<SalonProfileBloc, SalonProfileState>(
            listener: (context, state) {
              if (state is SalonProfileLoaded) {
                _populateControllers(state.profileData);
              } else if (state is SalonProfileUpdated) {
                TopNotificationService.showSuccess(
                  context: context,
                  message: state.message,
                );
                Navigator.of(context).pop();
              } else if (state is SalonProfileError) {
                TopNotificationService.showError(
                  context: context,
                  message: state.error,
                );
              }
            },
            builder: (context, state) {
              if (state is SalonProfileLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.textPrimaryColor,
                  ),
                );
              }

              return BlocBuilder<LanguageBloc, LanguageState>(
                builder: (context, languageState) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.user,
                                color: AppTheme.textPrimaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppTranslations.getString(
                                    context, 'profile_details'),
                                style: AppTheme.headingStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Name Field
                          _buildFormField(
                            label:
                                AppTranslations.getString(context, 'full_name'),
                            controller: _nameController,
                            placeholder: AppTranslations.getString(
                                context, 'full_name_placeholder'),
                            icon: LucideIcons.user,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppTranslations.getString(
                                    context, 'full_name_required');
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Email Field
                          _buildFormField(
                            label: AppTranslations.getString(context, 'email'),
                            controller: _emailController,
                            placeholder: AppTranslations.getString(
                                context, 'enter_your_email'),
                            icon: LucideIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppTranslations.getString(
                                    context, 'email_required');
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return AppTranslations.getString(
                                    context, 'invalid_email');
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Phone Field
                          _buildFormField(
                            label: AppTranslations.getString(context, 'phone'),
                            controller: _phoneController,
                            placeholder: '+33-XX-XX-XX-XX',
                            icon: LucideIcons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppTranslations.getString(
                                    context, 'phone_required');
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),

                          // Save Changes Button
                          _buildSaveButton(),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textPrimaryColor,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: AppTheme.textSecondaryColor,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<SalonProfileBloc, SalonProfileState>(
        builder: (context, state) {
      final isLoading = state is SalonProfileUpdating;

      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.transparentBackground,
            foregroundColor: AppTheme.textSecondaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppTheme.secondaryColor,
                width: 1,
              ),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.border2),
                  ),
                )
              : Text(
                  AppTranslations.getString(context, 'save_changes'),
                  style: TextStyle(
                    color: AppTheme.border2,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    });
  }
}
