import 'package:flutter/material.dart';
import '../translations/app_translations.dart';

class Validators {
  // Name validation
  static String? validateName(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_name');
    }
    if (value.trim().length < 2) {
      return AppTranslations.getString(context, 'name_min_length');
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(value.trim())) {
      return AppTranslations.getString(context, 'name_letters_only');
    }
    return null;
  }

  // Email validation
  static String? validateEmail(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_email');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return AppTranslations.getString(context, 'please_enter_valid_email');
    }
    return null;
  }

// Phone validation
  static String? validatePhone(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_phone');
    }
    // Generic international phone number validation (E.164 format)
    // Starts with +, followed by country code (1-3 digits), then up to 12 digits
    if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value.trim())) {
      return AppTranslations.getString(context, 'please_enter_valid_phone');
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value, BuildContext context) {
    if (value == null || value.isEmpty) {
      return AppTranslations.getString(context, 'please_enter_password');
    }
    if (value.length < 8) {
      return AppTranslations.getString(context, 'password_min_length');
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])')
        .hasMatch(value)) {
      return AppTranslations.getString(context, 'password_requirements');
    }
    return null;
  }

  // OTP validation
  static String? validateOtp(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_otp');
    }
    if (value.trim().length != 6) {
      return AppTranslations.getString(context, 'otp_length');
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
      return AppTranslations.getString(context, 'otp_numbers_only');
    }
    return null;
  }

  // Salon name validation
  static String? validateSalonName(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_salon_name');
    }
    if (value.trim().length < 3) {
      return AppTranslations.getString(context, 'salon_name_min_length');
    }
    return null;
  }

  // Salon address validation
  static String? validateSalonAddress(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_salon_address');
    }
    if (value.trim().length < 0) {
      return AppTranslations.getString(context, 'salon_address_min_length');
    }
    return null;
  }

  // Salon domain validation
  static String? validateSalonDomain(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_salon_domain');
    }
    if (value.trim().length < 1) {
      return AppTranslations.getString(context, 'salon_domain_min_length');
    }
    return null;
  }

  // Description validation
  static String? validateDescription(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_description');
    }
    if (value.trim().length < 10) {
      return AppTranslations.getString(context, 'description_min_length');
    }
    if (value.trim().length > 500) {
      return AppTranslations.getString(context, 'description_max_length');
    }
    return null;
  }

  // Required field validation
  static String? validateRequired(
      String? value, String fieldName, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_field')
          .replaceAll('{field}', fieldName);
    }
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) {
      return AppTranslations.getString(context, 'please_enter_number');
    }
    if (double.tryParse(value.trim()) == null) {
      return AppTranslations.getString(context, 'please_enter_valid_number');
    }
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, BuildContext context) {
    final numberValidation = validateNumber(value, context);
    if (numberValidation != null) {
      return numberValidation;
    }
    if (double.parse(value!.trim()) <= 0) {
      return AppTranslations.getString(context, 'number_must_be_positive');
    }
    return null;
  }
}
