import 'package:flutter/material.dart';

class AppTranslations {
  static const Locale french = Locale('fr', 'FR');
  static const Locale english = Locale('en', 'US');

  static const List<Locale> supportedLocales = [french, english];

  static String getString(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    return _getTranslation(locale.languageCode, key);
  }

  static String _getTranslation(String languageCode, String key) {
    switch (languageCode) {
      case 'en':
        return _englishTranslations[key] ?? key;
      case 'fr':
      default:
        return _frenchTranslations[key] ?? key;
    }
  }

  // French translations
  static const Map<String, String> _frenchTranslations = {
    // Welcome Screen
    'welcome_title': 'Bienvenue sur Konnected Beauty',
    'welcome_subtitle':
        'Connectez-vous avec les meilleurs professionnels de beauté',
    'signup_saloon': 'S\'inscrire en tant que Salon',
    'signup_influencer': 'S\'inscrire en tant qu\'Influenceur',
    'already_have_account': 'Vous avez déjà un compte ?',
    'login': 'Se connecter',
    'login_to_account': 'Se connecter à votre compte',

    // Login Screen
    'welcome_back': 'Bon retour',
    'email': 'Email',
    'email_placeholder': 'Entrez votre email',
    'password': 'Mot de passe',
    'password_placeholder': 'Entrez votre mot de passe',
    'forget_password': 'Mot de passe oublié ?',
    'login_to_your_account': 'Se connecter à votre compte',
    'influencer': 'Influenceur',
    'saloon': 'Salon',
    'wrong_credentials':
        'Identifiants incorrects ! Entrez vos informations correctes',

    // Registration Screen
    'create_account': 'Créer un compte',
    'join_konnected_beauty': 'Rejoignez Konnected Beauty',
    'personal_information': 'Informations personnelles',
    'full_name': 'Nom complet',
    'full_name_placeholder': 'Entrez votre nom complet',
    'phone': 'Téléphone',
    'phone_placeholder': 'Entrez votre numéro de téléphone',
    'continue': 'Continuer',
    'phone_verification': 'Vérification du téléphone',
    'verification_code': 'Code de vérification',
    'otp_placeholder': 'Entrez le code à 6 chiffres',
    'resend_code': 'Renvoyer le code',
    'submit_continue': 'Continuer',
    'wrong_code': 'Code incorrect',

    // Salon Information
    'salon_information': 'Informations du salon',
    'salon_name': 'Nom',
    'salon_name_placeholder': 'Entrez votre nom',
    'salon_address': 'Adresse du salon',
    'salon_address_placeholder': 'Entrez l\'adresse de votre salon',
    'activity_domain': 'Domaine d\'activité du salon',
    'activity_domain_placeholder': '+33-XX-XX-XX-XX',

    // Salon Profile
    'salon_profile': 'Profil du salon',
    'salon_photos': 'Photos du salon',
    'upload_photos': 'Télécharger des photos',
    'opening_hour': 'Heure d\'ouverture',
    'closing_hour': 'Heure de fermeture',
    'select': 'Sélectionner',
    'salon_description': 'Description du salon',
    'describe_salon_placeholder': 'Décrivez votre salon...',

    // Language Selector
    'choose_language': 'Choisir la langue',
    'french': 'Français',
    'english': 'English',

    // Error Messages
    'something_went_wrong':
        'Quelque chose s\'est mal passé. Veuillez réessayer.',
    'validation_failed': 'Validation échouée',

    // Validation Messages
    'please_enter_name': 'Veuillez entrer votre nom',
    'name_min_length': 'Le nom doit contenir au moins 2 caractères',
    'name_letters_only': 'Le nom ne doit contenir que des lettres',
    'please_enter_email': 'Veuillez entrer votre email',
    'please_enter_valid_email': 'Veuillez entrer un email valide',
    'please_enter_phone': 'Veuillez entrer votre numéro de téléphone',
    'please_enter_valid_phone':
        'Veuillez entrer un numéro de téléphone valide (10 chiffres)',
    'please_enter_password': 'Veuillez entrer votre mot de passe',
    'password_min_length':
        'Le mot de passe doit contenir au moins 6 caractères',
    'password_requirements':
        'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre',
    'please_enter_otp': 'Veuillez entrer le code OTP',
    'otp_length': 'Le code OTP doit contenir 6 chiffres',
    'otp_numbers_only': 'Le code OTP ne doit contenir que des chiffres',
    'please_enter_salon_name': 'Veuillez entrer le nom du salon',
    'salon_name_min_length':
        'Le nom du salon doit contenir au moins 3 caractères',
    'please_enter_salon_address': 'Veuillez entrer l\'adresse du salon',
    'salon_address_min_length':
        'L\'adresse doit contenir au moins 10 caractères',
    'please_enter_salon_domain': 'Veuillez entrer le domaine du salon',
    'salon_domain_min_length': 'Le domaine doit contenir au moins 3 caractères',
    'please_enter_description': 'Veuillez entrer une description',
    'description_min_length':
        'La description doit contenir au moins 10 caractères',
    'description_max_length':
        'La description ne doit pas dépasser 500 caractères',
    'please_enter_field': 'Veuillez entrer {field}',
    'please_enter_number': 'Veuillez entrer un nombre',
    'please_enter_valid_number': 'Veuillez entrer un nombre valide',
    'number_must_be_positive': 'Le nombre doit être positif',
  };

  // English translations
  static const Map<String, String> _englishTranslations = {
    // Welcome Screen
    'welcome_title': 'Welcome to Konnected Beauty',
    'welcome_subtitle': 'Connect with the best beauty professionals',
    'signup_saloon': 'Sign up as Salon',
    'signup_influencer': 'Sign up as Influencer',
    'already_have_account': 'Already have an account?',
    'login': 'Login',
    'login_to_account': 'Login to your account',

    // Login Screen
    'welcome_back': 'Welcome back',
    'email': 'Email',
    'email_placeholder': 'Enter your email',
    'password': 'Password',
    'password_placeholder': 'Enter your password',
    'forget_password': 'Forgot password?',
    'login_to_your_account': 'Login to your account',
    'influencer': 'Influencer',
    'saloon': 'Salon',
    'wrong_credentials':
        'Wrong Credentials! Enter your correct information please',

    // Registration Screen
    'create_account': 'Create Account',
    'join_konnected_beauty': 'Join Konnected Beauty',
    'personal_information': 'Personal Information',
    'full_name': 'Full Name',
    'full_name_placeholder': 'Enter your full name',
    'phone': 'Phone',
    'phone_placeholder': 'Enter your phone number',
    'continue': 'Continue',
    'phone_verification': 'Phone Verification',
    'verification_code': 'Verification Code',
    'otp_placeholder': 'Enter the 6-digit code',
    'resend_code': 'Resend Code',
    'submit_continue': 'Continue',
    'wrong_code': 'Wrong Code',

    // Salon Information
    'salon_information': 'Salon Information',
    'salon_name': 'Name',
    'salon_name_placeholder': 'Enter your name',
    'salon_address': 'Salon address',
    'salon_address_placeholder': 'Enter your salon address',
    'activity_domain': 'Salon domain of activity',
    'activity_domain_placeholder': '+33-XX-XX-XX-XX',

    // Salon Profile
    'salon_profile': 'Salon Profile',
    'salon_photos': 'Salon Photos',
    'upload_photos': 'Upload Photos',
    'opening_hour': 'Opening Hour',
    'closing_hour': 'Closing Hour',
    'select': 'Select',
    'salon_description': 'Salon Description',
    'describe_salon_placeholder': 'Describe your salon...',

    // Language Selector
    'choose_language': 'Choose Language',
    'french': 'Français',
    'english': 'English',

    // Error Messages
    'something_went_wrong': 'Something went wrong. Please try again.',
    'validation_failed': 'Validation failed',

    // Validation Messages
    'please_enter_name': 'Please enter your name',
    'name_min_length': 'Name must contain at least 2 characters',
    'name_letters_only': 'Name must contain only letters',
    'please_enter_email': 'Please enter your email',
    'please_enter_valid_email': 'Please enter a valid email',
    'please_enter_phone': 'Please enter your phone number',
    'please_enter_valid_phone': 'Please enter a valid phone number (10 digits)',
    'please_enter_password': 'Please enter your password',
    'password_min_length': 'Password must contain at least 6 characters',
    'password_requirements':
        'Password must contain at least one uppercase, one lowercase and one number',
    'please_enter_otp': 'Please enter the OTP code',
    'otp_length': 'OTP code must contain 6 digits',
    'otp_numbers_only': 'OTP code must contain only numbers',
    'please_enter_salon_name': 'Please enter the salon name',
    'salon_name_min_length': 'Salon name must contain at least 3 characters',
    'please_enter_salon_address': 'Please enter the salon address',
    'salon_address_min_length': 'Address must contain at least 10 characters',
    'please_enter_salon_domain': 'Please enter the salon domain',
    'salon_domain_min_length': 'Domain must contain at least 3 characters',
    'please_enter_description': 'Please enter a description',
    'description_min_length': 'Description must contain at least 10 characters',
    'description_max_length': 'Description must not exceed 500 characters',
    'please_enter_field': 'Please enter {field}',
    'please_enter_number': 'Please enter a number',
    'please_enter_valid_number': 'Please enter a valid number',
    'number_must_be_positive': 'Number must be positive',
  };
}
