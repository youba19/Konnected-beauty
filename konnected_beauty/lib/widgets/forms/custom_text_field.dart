import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konnected_beauty/core/translations/app_translations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool isError;
  final String? errorMessage;
  final Widget? suffixIcon;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool autovalidateMode;
  final int? maxLines;
  final GlobalKey<FormFieldState>? formFieldKey;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool isPasswordVisible;

  const CustomTextField({
    super.key,
    required this.label,
    required this.placeholder,
    this.controller,
    this.keyboardType,
    this.isPassword = false,
    this.isError = false,
    this.errorMessage,
    this.suffixIcon,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode = false,
    this.maxLines,
    this.formFieldKey,
    this.enabled = true,
    this.onChanged,
    this.obscureText = false,
    this.isPasswordVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: formFieldKey,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? !isPasswordVisible : false,
          maxLength: maxLength,
          maxLines: isPassword ? 1 : maxLines,
          inputFormatters: inputFormatters,
          validator: validator,
          enabled: enabled,
          onChanged: onChanged,
          autovalidateMode: autovalidateMode
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          style: TextStyle(
            color: brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.textPrimaryColor,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: brightness == Brightness.light
                  ? AppTheme.lightTextSecondaryColor
                  : AppTheme.textSecondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: brightness == Brightness.light
                ? AppTheme.lightCardBackground
                : AppTheme.transparentBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isError
                    ? Colors.red
                    : brightness == Brightness.light
                        ? AppTheme.lightTextPrimaryColor
                        : AppTheme.borderColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isError
                    ? Colors.red
                    : brightness == Brightness.light
                        ? AppTheme.lightTextPrimaryColor
                        : AppTheme.borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: brightness == Brightness.light
                    ? AppTheme.lightTextPrimaryColor
                    : AppTheme.accentColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ),
        if (isError && errorMessage != null && validator == null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

class CustomImagePicker extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onTap;
  final bool isError;
  final String? errorMessage;

  const CustomImagePicker({
    super.key,
    required this.label,
    this.imagePath,
    required this.onTap,
    this.isError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (same as CustomTextField)
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Upload container
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isError ? Colors.red : AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imagePath == null) ...[
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
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.getString(context, 'tap_to_change'),
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Error text (same as CustomTextField)
        if (isError && errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}
