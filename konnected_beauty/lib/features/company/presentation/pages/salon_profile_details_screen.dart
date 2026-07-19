import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/salon_profile/salon_profile_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../widgets/common/top_notification_banner.dart';

abstract final class _SalonProfileDetailsUi {
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

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
    _nameController.text = profileData['name'] ?? '';
    _emailController.text = profileData['email'] ?? '';
    _phoneController.text = (profileData['phoneNumber'] ?? '').isEmpty
        ? '+33'
        : (profileData['phoneNumber'] ?? '');
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();

    String finalPhoneNumber = phoneNumber;
    if (phoneNumber.isNotEmpty) {
      if (phoneNumber.startsWith('06') || phoneNumber.startsWith('07')) {
        String digits = phoneNumber.substring(1);
        if (digits.length > 9) {
          digits = digits.substring(0, 9);
        }
        finalPhoneNumber = '+33$digits';
      }
    }

    context.read<SalonProfileBloc>().add(UpdateSalonProfile(
          name: name.isNotEmpty ? name : null,
          email: null,
          phoneNumber: finalPhoneNumber.isNotEmpty ? finalPhoneNumber : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final topInset = MediaQuery.paddingOf(context).top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ui.systemOverlay,
          child: Scaffold(
            backgroundColor: ui.bg,
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + 220,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: ui.fullSheetGradient,
                        stops: ui.fullSheetStops,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
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
                          return Center(
                            child: CircularProgressIndicator(
                              color: SalonUiTheme.accentBlue,
                            ),
                          );
                        }

                        return BlocBuilder<LanguageBloc, LanguageState>(
                          builder: (context, languageState) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.only(
                                left: 20,
                                top: 8,
                                right: 20,
                                bottom:
                                    MediaQuery.viewInsetsOf(context).bottom + 28,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBackButton(ui),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Icon(
                                          LucideIcons.user,
                                          color: ui.textPrimary,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppTranslations.getString(
                                            context,
                                            'profile_details',
                                          ),
                                          style: TextStyle(
                                            color: ui.textPrimary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    _buildFormField(
                                      ui: ui,
                                      label: AppTranslations.getString(
                                        context,
                                        'full_name',
                                      ),
                                      controller: _nameController,
                                      placeholder: AppTranslations.getString(
                                        context,
                                        'full_name_placeholder',
                                      ),
                                      icon: LucideIcons.user,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return AppTranslations.getString(
                                            context,
                                            'full_name_required',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    _buildReadOnlyField(
                                      ui: ui,
                                      label: AppTranslations.getString(
                                        context,
                                        'email',
                                      ),
                                      controller: _emailController,
                                      placeholder: AppTranslations.getString(
                                        context,
                                        'enter_your_email',
                                      ),
                                      icon: LucideIcons.mail,
                                    ),
                                    const SizedBox(height: 18),
                                    _buildFormField(
                                      ui: ui,
                                      label: AppTranslations.getString(
                                        context,
                                        'phone',
                                      ),
                                      controller: _phoneController,
                                      placeholder: '+33-XX-XX-XX-XX',
                                      icon: LucideIcons.phone,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return AppTranslations.getString(
                                            context,
                                            'phone_required',
                                          );
                                        }
                                        final phone = value.trim();
                                        if (phone.startsWith('06') ||
                                            phone.startsWith('07')) {
                                          if (phone.length < 10) return null;
                                          if ((phone.length == 10 ||
                                                  phone.length == 11) &&
                                              RegExp(r'^0[67]\\d{8,9}$')
                                                  .hasMatch(phone)) {
                                            return null;
                                          }
                                          return AppTranslations.getString(
                                            context,
                                            'please_enter_valid_phone',
                                          );
                                        }
                                        if (phone.startsWith('0')) return null;
                                        if (!phone.startsWith('+33')) {
                                          if (phone.isEmpty ||
                                              phone.startsWith('+')) {
                                            return null;
                                          }
                                          return AppTranslations.getString(
                                            context,
                                            'please_enter_valid_phone',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 26),
                                    _buildSaveButton(ui),
                                    const SizedBox(height: 18),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(SalonUiTheme ui) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: _SalonProfileDetailsUi.buttonSize,
        height: _SalonProfileDetailsUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ui.buttonFillTop,
              ui.buttonFillBottom,
            ],
          ),
          borderRadius: BorderRadius.circular(
            _SalonProfileDetailsUi.buttonRadius,
          ),
          border: ui.isDark
              ? null
              : Border.all(color: ui.cardBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.arrowLeft,
          color: ui.buttonIcon,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required SalonUiTheme ui,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ui.card,
            borderRadius: BorderRadius.circular(_SalonProfileDetailsUi.radius),
            border: Border.all(color: ui.cardBorder, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: ui.textMuted,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: ui.textSecondary,
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

  Widget _buildReadOnlyField({
    required SalonUiTheme ui,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ui.card,
            borderRadius: BorderRadius.circular(_SalonProfileDetailsUi.radius),
            border: Border.all(color: ui.cardBorder, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            enabled: false,
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: ui.textMuted,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: ui.textMuted,
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

  Widget _buildSaveButton(SalonUiTheme ui) {
    return BlocBuilder<SalonProfileBloc, SalonProfileState>(
      builder: (context, state) {
        final isLoading = state is SalonProfileUpdating;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: ui.primaryButtonBg,
              disabledBackgroundColor: ui.primaryButtonBg.withValues(alpha: 0.7),
              foregroundColor: ui.primaryButtonFg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(_SalonProfileDetailsUi.radius),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ui.primaryButtonFg,
                    ),
                  )
                : Text(
                    AppTranslations.getString(context, 'save_changes'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
