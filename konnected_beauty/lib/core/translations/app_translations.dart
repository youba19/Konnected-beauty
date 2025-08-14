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
    'welcome_title': 'Bienvenue sur KBeauty',
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
    'enter_email': 'Entrez votre email',
    'email_placeholder': 'Entrez votre email',
    'password': 'Mot de passe',
    'enter_password': 'Entrez votre mot de passe',
    'password_placeholder': 'Entrez votre mot de passe',
    'forgot_password': 'Mot de passe oublié ?',
    'login_to_your_account': 'Se connecter à votre compte',
    'influencer': 'Influenceur',
    'saloon': 'Salon',
    'wrong_credentials':
        'Identifiants incorrects ! Entrez vos informations correctes',
    'login_success': 'Connexion réussie',
    'login_failed': 'Échec de la connexion',
    'influencer_home_not_implemented':
        'Écran d\'accueil influenceur pas encore implémenté',

    // Reset Password Screen
    'reset_password': 'Réinitialiser le mot de passe',
    'reset_password_subtitle':
        'Entrez votre email pour réinitialiser votre mot de passe',
    'reset_password_button': 'Réinitialiser le mot de passe',
    'otp_verification_title': 'Vérification du code',
    'otp_verification_subtitle':
        'Nous avons envoyé un code de vérification à votre email',
    'otp_verification': 'Vérification OTP',
    'submit_and_continue': 'Soumettre et continuer',
    'new_password_title': 'Nouveau mot de passe',
    'new_password_subtitle': 'Créez un nouveau mot de passe sécurisé',
    'confirm_password': 'Confirmer le mot de passe',
    'confirm_password_placeholder': 'Confirmez votre nouveau mot de passe',
    'password_reset_success': 'Mot de passe réinitialisé avec succès',
    'password_reset_error':
        'Erreur lors de la réinitialisation du mot de passe',
    'email_verification': 'Vérification de l\'email',
    'email_verified': 'Email vérifié',

    // Registration Screen
    'create_account': 'Créer un compte',
    'join_konnected_beauty': 'Rejoignez Konnected Beauty',
    'personal_information': 'Informations personnelles',
    'full_name': 'Nom complet',
    'full_name_placeholder': 'Entrez votre nom complet',
    'phone': 'Téléphone',
    'phone_placeholder': '+33-XX-XX-XX-XX',
    'continue': 'Continuer',
    'phone_verification': 'Vérification du téléphone',
    'verification_code': 'Code de vérification',
    'otp_placeholder': 'Entrez le code à 6 chiffres',
    'resend_code': 'Renvoyer le code',
    'submit_continue': 'Continuer',
    'wrong_code': 'Code incorrect',
    'account_created_check_email':
        'Compte créé avec succès ! Veuillez vérifier votre e-mail pour le code de vérification.',

    // Salon Information
    'salon_information': 'Informations du salon',
    'salon_name': 'Nom',
    'salon_name_placeholder': 'Entrez votre nom',
    'salon_address': 'Adresse du salon',
    'salon_address_placeholder': 'Entrez l\'adresse de votre salon',
    'activity_domain': 'Domaine d\'activité du salon',
    'activity_domain_placeholder': 'Domaine d\'activité',

    // Salon Profile
    'salon_profile': 'Profil du salon',
    'salon_photos': 'Photos du salon',
    'upload_photos': 'Télécharger des photos',
    'opening_hour': 'Heure d\'ouverture',
    'closing_hour': 'Heure de fermeture',
    'select': 'Sélectionner',
    'salon_description': 'Description du salon',
    'describe_salon_placeholder': 'Décrivez votre salon...',

    // Service Management
    'service_name': 'Nom du service',
    'enter_service_name': 'Entrez le nom de votre service',
    'service_price': 'Prix du service (EURO)',
    'enter_service_price': 'Entrez le prix de votre service',
    'service_description': 'Description du service',
    'describe_service': 'Décrivez votre service',
    'service_details': 'Détails du service',
    'service_created_successfully': 'Le service a été créé avec succès',
    'delete_service': 'Supprimer le service',
    'delete_service_confirmation':
        'Êtes-vous sûr de vouloir supprimer ce service ? Cette action ne peut pas être annulée.',
    'service_deleted': 'Service supprimé avec succès',
    'edit_service': 'Modifier le service',
    'save_changes': 'Enregistrer les modifications',
    'service_updated': 'Service mis à jour avec succès',
    'service_created': 'Service créé avec succès',
    'update_service': 'Mettre à jour le service',
    'create_service': 'Créer le service',
    'service_information': 'Informations du service',
    'service_price_euro': 'Prix du service (€)',
    'describe_service_details': 'Décrivez les détails de votre service',
    'back_to_services': 'Retour aux services',
    'service_management': 'Gestion des services',
    'no_services_found': 'Aucun service trouvé',
    'loading_services': 'Chargement des services...',
    'refresh_services': 'Actualiser les services',
    'filter_services': 'Filtrer les services',
    'clear_filters': 'Effacer les filtres',
    'price_range': 'Fourchette de prix',
    'search_services': 'Rechercher des services',
    'all_services': 'Tous les services',
    'my_services': 'Mes services',
    'add_new_service': 'Ajouter un nouveau service',
    'edit_existing_service': 'Modifier le service existant',
    'delete_existing_service': 'Supprimer le service existant',
    'confirm_delete': 'Confirmer la suppression',
    'delete_warning': 'Cette action ne peut pas être annulée',
    'service_name_required': 'Le nom du service est requis',
    'service_price_required': 'Le prix du service est requis',
    'service_description_required': 'La description du service est requise',
    'invalid_price': 'Format de prix invalide',
    'price_must_be_positive': 'Le prix doit être positif',
    'service_saved': 'Service enregistré avec succès',
    'service_update_failed': 'Échec de la mise à jour du service',
    'service_creation_failed': 'Échec de la création du service',
    'service_deletion_failed': 'Échec de la suppression du service',
    'permission_denied': 'Permission refusée',
    'you_can_only_edit_your_services':
        'Vous ne pouvez modifier que vos propres services',
    'you_can_only_delete_your_services':
        'Vous ne pouvez supprimer que vos propres services',
    'qr_scanning_coming_soon': 'Fonctionnalité de scan QR bientôt disponible',
    'edit_functionality_coming_soon':
        'Fonctionnalité d\'édition bientôt disponible',
    'cancel': 'Annuler',
    'delete': 'Supprimer',

    // Salon Home Screen
    'services': 'Services',
    'search': 'Rechercher',
    'create_new_service': 'Créer un nouveau service',
    'see_more': 'Voir plus',
    'view_details': 'Voir les détails',
    'edit': 'Modifier',
    'campaigns': 'Campagnes',
    'wallet': 'Portefeuille',
    'influencers': 'Influenceurs',
    'settings': 'Paramètres',

    // Filter
    'filter': 'Filtrer',
    'min': 'Min',
    'max': 'Max',
    'apply_filter': 'Appliquer le filtre',

    // Language Selector
    'choose_language': 'Choisir la langue',
    'french': 'Français',
    'english': 'English',

    // Error Messages
    'something_went_wrong':
        'Quelque chose s\'est mal passé. Veuillez réessayer.',
    'validation_failed': 'Validation échouée',
    'error_occurred': 'Une erreur s\'est produite',
    'retry': 'Réessayer',

    // Validation Messages
    'please_enter_name': 'Veuillez entrer votre nom',
    'name_min_length': 'Le nom doit contenir au moins 2 caractères',
    'name_letters_only': 'Le nom ne doit contenir que des lettres',
    'please_enter_email': 'Veuillez entrer votre email',
    'please_enter_valid_email': 'Veuillez entrer un email valide',
    'please_enter_phone': 'Veuillez entrer votre numéro de téléphone',
    'please_enter_valid_phone':
        'Veuillez entrer un numéro de téléphone valide (+33-XX-XX-XX-XX)',
    'please_enter_password': 'Veuillez entrer votre mot de passe',
    'password_min_length':
        'Le mot de passe doit contenir au moins 8 caractères',
    'password_requirements':
        'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial',
    'please_enter_otp': 'Veuillez entrer le code OTP',
    'otp_length': 'Le code OTP doit contenir 6 chiffres',
    'otp_numbers_only': 'Le code OTP ne doit contenir que des chiffres',
    'please_confirm_password': 'Veuillez confirmer votre mot de passe',
    'passwords_do_not_match': 'Les mots de passe ne correspondent pas',
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
    'welcome_title': 'Welcome to KBeauty',
    'welcome_subtitle': 'Connect with the best beauty professionals',
    'signup_saloon': 'Sign up as Salon',
    'signup_influencer': 'Sign up as Influencer',
    'already_have_account': 'Already have an account?',
    'login': 'Login',
    'login_to_account': 'Login to your account',

    // Login Screen
    'welcome_back': 'Welcome back',
    'email': 'Email',
    'enter_email': 'Enter your email',
    'email_placeholder': 'Enter your email',
    'password': 'Password',
    'enter_password': 'Enter your password',
    'password_placeholder': 'Enter your password',
    'forgot_password': 'Forgot password?',
    'login_to_your_account': 'Login to your account',
    'influencer': 'Influencer',
    'saloon': 'Salon',
    'wrong_credentials':
        'Wrong Credentials! Enter your correct information please',
    'login_success': 'Logged in successfully',
    'login_failed': 'Login failed',
    'influencer_home_not_implemented':
        'Influencer home screen not implemented yet',

    // Reset Password Screen
    'reset_password': 'Reset Password',
    'reset_password_subtitle': 'Enter your email to reset your password',
    'reset_password_button': 'Reset Password',
    'otp_verification_title': 'Code Verification',
    'otp_verification_subtitle':
        'We have sent a verification code to your email',
    'otp_verification': 'OTP verification',
    'submit_and_continue': 'Submit & Continue',
    'new_password_title': 'New Password',
    'new_password_subtitle': 'Create a secure new password',
    'confirm_password': 'Confirm Password',
    'confirm_password_placeholder': 'Confirm your new password',
    'password_reset_success': 'Password reset successfully',
    'password_reset_error': 'Error resetting password',
    'email_verification': 'Email Verification',
    'email_verified': 'Email Verified',

    // Registration Screen
    'create_account': 'Create Account',
    'join_konnected_beauty': 'Join Konnected Beauty',
    'personal_information': 'Personal Information',
    'full_name': 'Full Name',
    'full_name_placeholder': 'Enter your full name',
    'phone': 'Phone',
    'phone_placeholder': '+33-XX-XX-XX-XX',
    'continue': 'Continue',
    'phone_verification': 'Phone Verification',
    'verification_code': 'Verification Code',
    'otp_placeholder': 'Enter the 6-digit code',
    'resend_code': 'Resend Code',
    'submit_continue': 'Continue',
    'wrong_code': 'Wrong Code',
    'account_created_check_email':
        'Account created successfully! Please check your email for the verification code.',

    // Salon Information
    'salon_information': 'Salon Information',
    'salon_name': 'Name',
    'salon_name_placeholder': 'Enter your name',
    'salon_address': 'Salon address',
    'salon_address_placeholder': 'Enter your salon address',
    'activity_domain': 'Salon domain of activity',
    'activity_domain_placeholder': 'Domain of activity',

    // Salon Profile
    'salon_profile': 'Salon Profile',
    'salon_photos': 'Salon Photos',
    'upload_photos': 'Upload Photos',
    'opening_hour': 'Opening Hour',
    'closing_hour': 'Closing Hour',
    'select': 'Select',
    'salon_description': 'Salon Description',
    'describe_salon_placeholder': 'Describe your salon...',

    // Service Management
    'service_name': 'Service name',
    'enter_service_name': 'Enter your service name',
    'service_price': 'Service price (EURO)',
    'enter_service_price': 'Enter your service price',
    'service_description': 'Service description',
    'describe_service': 'Describe your service',
    'service_details': 'Service details',
    'service_created_successfully': 'Service has been created successfully',
    'delete_service': 'Delete Service',
    'delete_service_confirmation':
        'Are you sure you want to delete this service? This action cannot be undone.',
    'service_deleted': 'Service deleted successfully',
    'edit_service': 'Edit Service',
    'save_changes': 'Save Changes',
    'service_updated': 'Service updated successfully',
    'service_created': 'Service created successfully',
    'update_service': 'Update Service',
    'create_service': 'Create Service',
    'service_information': 'Service Information',
    'service_price_euro': 'Service Price (€)',
    'describe_service_details': 'Describe your service details',
    'back_to_services': 'Back to Services',
    'service_management': 'Service Management',
    'no_services_found': 'No services found',
    'loading_services': 'Loading services...',
    'refresh_services': 'Refresh Services',
    'filter_services': 'Filter Services',
    'clear_filters': 'Clear Filters',
    'price_range': 'Price Range',
    'search_services': 'Search Services',
    'all_services': 'All Services',
    'my_services': 'My Services',
    'add_new_service': 'Add New Service',
    'edit_existing_service': 'Edit Existing Service',
    'delete_existing_service': 'Delete Existing Service',
    'confirm_delete': 'Confirm Delete',
    'delete_warning': 'This action cannot be undone',
    'service_name_required': 'Service name is required',
    'service_price_required': 'Service price is required',
    'service_description_required': 'Service description is required',
    'invalid_price': 'Invalid price format',
    'price_must_be_positive': 'Price must be positive',
    'service_saved': 'Service saved successfully',
    'service_update_failed': 'Failed to update service',
    'service_creation_failed': 'Failed to create service',
    'service_deletion_failed': 'Failed to delete service',
    'permission_denied': 'Permission denied',
    'you_can_only_edit_your_services': 'You can only edit your own services',
    'you_can_only_delete_your_services':
        'You can only delete your own services',
    'qr_scanning_coming_soon': 'QR scanning functionality coming soon',
    'edit_functionality_coming_soon': 'Edit functionality coming soon',
    'cancel': 'Cancel',
    'delete': 'Delete',

    // Salon Home Screen
    'services': 'Services',
    'search': 'Search',
    'create_new_service': 'Create new service',
    'see_more': 'See more',
    'view_details': 'View details',
    'edit': 'Edit',
    'campaigns': 'Campaigns',
    'wallet': 'Wallet',
    'influencers': 'Influencers',
    'settings': 'Settings',

    // Filter
    'filter': 'Filter',
    'min': 'Min',
    'max': 'Max',
    'apply_filter': 'Apply filter',

    // Language Selector
    'choose_language': 'Choose Language',
    'french': 'Français',
    'english': 'English',

    // Error Messages
    'something_went_wrong': 'Something went wrong. Please try again.',
    'validation_failed': 'Validation failed',
    'error_occurred': 'An error occurred',
    'retry': 'Retry',

    // Validation Messages
    'please_enter_name': 'Please enter your name',
    'name_min_length': 'Name must contain at least 2 characters',
    'name_letters_only': 'Name must contain only letters',
    'please_enter_email': 'Please enter your email',
    'please_enter_valid_email': 'Please enter a valid email',
    'please_enter_phone': 'Please enter your phone number',
    'please_enter_valid_phone':
        'Please enter a valid phone number (+33-XX-XX-XX-XX)',
    'please_enter_password': 'Please enter your password',
    'password_min_length': 'Password must contain at least 8 characters',
    'password_requirements':
        'Password must contain at least one uppercase, one lowercase, one number and one special character',
    'please_enter_otp': 'Please enter the OTP code',
    'otp_length': 'OTP code must contain 6 digits',
    'otp_numbers_only': 'OTP code must contain only numbers',
    'please_confirm_password': 'Please confirm your password',
    'passwords_do_not_match': 'Passwords do not match',
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
