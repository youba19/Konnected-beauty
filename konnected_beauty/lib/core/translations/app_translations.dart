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
    'influencer_home': 'Accueil Influenceur',
    'welcome_influencer': 'Bienvenue, Influenceur !',
    'influencer_home_description':
        'Votre inscription est terminée et vous faites maintenant partie de la communauté Konnected Beauty.',
    'registration_complete': 'Inscription Terminée !',
    'registration_complete_message':
        'Félicitations ! Vous avez terminé avec succès votre inscription d\'influenceur. Vous pouvez maintenant commencer à collaborer avec des marques de beauté et développer votre audience.',
    'socials_added_success':
        'Liens de réseaux sociaux ajoutés avec succès ! Inscription terminée. Redirection vers la page d\'accueil...',
    'account_created_successfully': 'Votre compte a été créé avec succès',
    'otp_resent_success':
        'Code OTP renvoyé avec succès ! Vérifiez votre email.',

    // Influencer Home Screen
    'good_morning': 'Bonjour,',
    'total_revenue': 'Revenus totaux',
    'total_orders': 'Commandes totales',
    'received_invitations': 'Invitations reçues',
    'no_requests_yet':
        'Vous n\'avez encore reçu aucune demande,\ncontinuez à grandir et les opportunités viendront à vous',
    'saloons': 'Salons',
    'campaign': 'Campagne',
    'wallet': 'Portefeuille',
    'profile': 'Profil',
    'social_information': 'Informations sociales',
    'security': 'Sécurité',
    'current_password': 'Mot de passe actuel',
    'new_password': 'Nouveau mot de passe',
    'confirm_new_password': 'Confirmer le nouveau mot de passe',
    'enter_current_password': 'Entrer le mot de passe actuel',
    'set_new_password': 'Définir le nouveau mot de passe',
    'current_password_required': 'Le mot de passe actuel est requis',
    'new_password_required': 'Le nouveau mot de passe est requis',
    'confirm_password_required':
        'Veuillez confirmer votre nouveau mot de passe',
    'passwords_not_match': 'Les nouveaux mots de passe ne correspondent pas',
    'password_too_short': 'Le mot de passe doit contenir au moins 6 caractères',
    'new_password_too_short':
        'Le nouveau mot de passe doit contenir au moins 6 caractères',
    'password_changed_successfully': 'Mot de passe modifié avec succès',
    'password_change_failed': 'Échec de la modification du mot de passe',
    'notifications': 'Notifications',
    'logout': 'Déconnexion',

    // Settings Screen
    'saloon_name': 'Nom du Salon',
    'profile_details': 'Détails du profil',
    'enter_your_name': 'Entrez votre nom',
    'enter_your_email': 'Entrez votre email',
    'set_your_password': 'Définissez votre mot de passe',
    'save_changes': 'Sauvegarder les modifications',
    'profile_updated_successfully': 'Profil mis à jour avec succès',
    'profile_update_failed': 'Échec de la mise à jour du profil',
    'name_required': 'Le nom est requis',
    'email_required': 'L\'email est requis',
    'invalid_email': 'Veuillez entrer un email valide',
    'phone_required': 'Le téléphone est requis',
    'password_required': 'Le mot de passe est requis',
    'saloon_information': 'Informations du salon',

    // Reset Password Screen
    'reset_password': 'Réinitialiser le mot de passe',
    'reset_password_subtitle':
        'Entrez votre email pour réinitialiser votre mot de passe',
    'reset_password_button': 'Réinitialiser le mot de passe',
    'otp_verification_title': 'Vérification du code OTP',
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
    'join_konnected_beauty':
        'Terminez votre inscription pour créer votre compte et commencer à vendre.',
    'personal_information': 'Informations personnelles',
    'full_name': 'Nom complet',
    'full_name_placeholder': 'Entrez votre nom complet',
    'full_name_required': 'Le nom complet est requis',
    'phone': 'Téléphone',
    'phone_placeholder': '+33-XX-XX-XX-XX',
    'continue': 'Continuer',
    'phone_verification': 'Vérification du votre e-mail',
    'verification_code': 'Code de vérification',
    'verify_code': 'Vérifier le code',
    'otp_placeholder': 'Entrez le code à 6 chiffres',
    'resend_code': 'Renvoyer le code',
    'submit_continue': 'Continuer',
    'wrong_code': 'Code incorrect',
    'otp_verified_success':
        'Code OTP vérifié avec succès ! Veuillez compléter votre profil.',
    'invalid_verification_code': 'Code de vérification invalide',
    'verification_failed': 'Échec de la vérification',
    'network_error_try_again': 'Erreur réseau. Veuillez réessayer',
    'account_created_check_email':
        'Compte créé avec succès ! Veuillez vérifier votre e-mail pour le code de vérification.',

    // Salon Information
    'salon_information': 'Informations du salon',
    'salon_name': 'Nom du salon',
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
    'salon_address_required': 'L\'adresse du salon est requise',
    'activity_domain_required': 'Le domaine d\'activité est requis',
    'salon_information_updated_successfully':
        'Informations du salon mises à jour avec succès',
    'salon_information_update_failed':
        'Échec de la mise à jour des informations du salon',
    'notifications_empty_state': 'Il n\'y a pas encore de notifications !',

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
    'total_campaigns': 'Total des campagnes',
    'total_clicks': 'Total des clics',
    'clicks': 'Clics',
    'no_campaigns_yet': 'Il n\'y a pas encore de campagnes !',
    'go_to_influencers_message':
        'Allez chez les Influenceurs et invitez-les pour des campagnes.',
    'go_to_influencers': 'Aller chez les Influenceurs',
    'filter_coming_soon': 'Fonctionnalité de filtre bientôt disponible',
    'campaign_with': 'Campagne avec',
    'created_at': 'Créé le',
    'promotion_type': 'Type de promotion',
    'value': 'Valeur',
    'completed_orders': 'Commandes terminées',
    'finish_campaign': 'Terminer la campagne',
    'copy_link': 'Copier le lien',
    'delete_campaign': 'Supprimer la campagne',
    'delete_campaign_confirm':
        'Êtes-vous sûr de vouloir supprimer cette campagne ?',
    'campaign_finished_success': 'Campagne terminée avec succès !',
    'campaign_link_copied': 'Lien de campagne copié dans le presse-papiers !',
    'campaign_deleted_success': 'Campagne supprimée avec succès !',
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

    // Campaign Invite Dialog
    'campaign_invite_title':
        'Êtes-vous sûr de vouloir inviter cet influenceur et créer une campagne pour lui ?',
    'campaign_invite_instructions':
        'Si oui, donnez-nous les détails nécessaires si vous avez des promotions ci-dessous.',
    'select_type': 'Sélectionner le type',
    'promotion_value': 'Valeur de la promotion',
    'please_select_promotion_type':
        'Veuillez sélectionner le type de promotion',
    'please_enter_promotion_value': 'Veuillez entrer la valeur de la promotion',
    'create_campaign_invite': 'Créer une campagne et inviter',
    'campaign_created_successfully': 'Campagne créée avec succès !',

    // Influencer Registration
    'create_influencer_account': 'Créer un compte',
    'complete_influencer_registration':
        'Complétez l\'inscription pour créer votre compte et commencer à faire des affaires.',
    'your_information': 'Vos informations',
    'profile_picture': 'Photo de profil',
    'upload_profile_picture': 'Télécharger votre photo de profil',
    'upload_your_profile_picture': 'Télécharger votre photo de profil',
    'pseudo': 'Pseudo',
    'enter_pseudo': 'Entrez votre nom spécial',
    'enter_your_special_name': 'Entrez votre nom spécial',
    'bio': 'Bio',
    'enter_bio': 'Décrivez-vous rapidement',
    'describe_yourself_quickly': 'Décrivez-vous rapidement',
    'zone': 'Zone',
    'select_zone': 'Sélectionnez votre zone',
    'select_your_zone': 'Sélectionnez votre zone',
    'your_socials': 'Vos réseaux sociaux',
    'instagram': 'Instagram',
    'snapchat': 'Snapchat',
    'tiktok': 'TikTok',
    'youtube': 'YouTube',
    'enter_instagram_link': 'Entrez le lien Instagram',
    'enter_tiktok_link': 'Entrez le lien TikTok',
    'enter_youtube_link': 'Entrez le lien YouTube',
    'add_more_later': 'Vous pouvez en ajouter plus plus tard !',
    'account_created_success_message':
        'Compte créé avec succès ! Veuillez vérifier votre email pour le code de vérification.',
    'social_media': 'Réseaux sociaux',
    'select_image_source': 'Sélectionner la source d\'image',
    'camera': 'Caméra',
    'gallery': 'Galerie',
    'tap_to_change': 'Appuyez pour changer',
    'tap_to_select': 'Appuyez pour sélectionner',
    'remove_image': 'Supprimer l\'image',
    'add_link': 'Ajouter un lien',
    'link_name': 'Nom du lien',
    'link': 'Lien',
    'link_name_placeholder': 'Nom du lien',
    'link_placeholder': 'www.....',

    // Influencer Campaign
    'accept_campaign': 'Accepter la campagne',
    'refuse_campaign': 'Refuser la campagne',
    'refuse_campaign_confirmation':
        'Êtes-vous sûr de vouloir refuser cette campagne ? Cette action ne peut pas être annulée.',
    'refuse': 'Refuser',
    'waiting_for_you': 'En attente de vous',
    'on_going': 'En cours',
    'finished': 'Terminé',
    'orders': 'Commandes',
    'campaigns_will_appear_here':
        'Les invitations de campagne et les collaborations apparaîtront ici',
    'refresh': 'Actualiser',
    'try_again': 'Réessayer',
    'total': 'Total',
    'message': 'Message',
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
    'influencer_home': 'Influencer Home',
    'welcome_influencer': 'Welcome, Influencer!',
    'influencer_home_description':
        'Your registration is complete and you are now part of the Konnected Beauty community.',
    'registration_complete': 'Registration Complete!',
    'registration_complete_message':
        'Congratulations! You have successfully completed your influencer registration. You can now start collaborating with beauty brands and growing your audience.',
    'socials_added_success':
        'Social media links added successfully! Registration complete. Redirecting to home page...',
    'account_created_successfully': 'Your account is created successfully',
    'otp_resent_success':
        'OTP code resent successfully! Please check your email.',

    // Influencer Home Screen
    'good_morning': 'Good morning,',
    'total_revenue': 'Total Revenue',
    'total_orders': 'Total Orders',
    'received_invitations': 'Received invitations',
    'no_requests_yet':
        'You\'ve received no requests yet,\nkeep growing and opportunities will come for you',
    'home': 'Home',
    'saloons': 'Saloons',
    'campaign': 'Campaign',
    'wallet': 'Wallet',
    'profile': 'Profile',
    'social_information': 'Social Information',
    'security': 'Security',
    'current_password': 'Current password',
    'new_password': 'New password',
    'confirm_new_password': 'Confirm new password',
    'enter_current_password': 'Enter Current password',
    'set_new_password': 'Set New password',
    'current_password_required': 'Current password is required',
    'new_password_required': 'New password is required',
    'confirm_password_required': 'Please confirm your new password',
    'passwords_not_match': 'New passwords do not match',
    'new_password_too_short': 'New password must be at least 6 characters',
    'password_changed_successfully': 'Password changed successfully',
    'password_change_failed': 'Failed to change password',
    'notifications': 'Notifications',
    'logout': 'Logout',

    // Reset Password Screen
    'reset_password': 'Reset Password',
    'reset_password_subtitle': 'Enter your email to reset your password',
    'reset_password_button': 'Reset Password',
    'otp_verification_title': 'OTP Verification',
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
    'join_konnected_beauty':
        'Complete registration to create your account and start selling.',
    'personal_information': 'Personal Information',
    'full_name': 'Full Name',
    'full_name_placeholder': 'Enter your full name',
    'full_name_required': 'Full name is required',
    'phone': 'Phone',
    'phone_placeholder': '+33-XX-XX-XX-XX',
    'continue': 'Continue',
    'phone_verification': 'Email Verification',
    'verification_code': 'OTP Verification',
    'verify_code': 'Verify Code',
    'otp_placeholder': 'Enter the 6-digit code',
    'resend_code': 'Resend Code',
    'submit_continue': 'Continue',
    'wrong_code': 'Wrong Code',
    'otp_verified_success':
        'OTP verified successfully! Please complete your profile.',
    'invalid_verification_code': 'Invalid verification code',
    'verification_failed': 'Verification failed',
    'network_error_try_again': 'Network error. Please try again',
    'account_created_check_email':
        'Account created successfully! Please check your email for the verification code.',

    // Salon Information
    'salon_information': 'Saloon Information',
    'salon_name': 'Name',
    'salon_name_placeholder': 'Enter your name',
    'salon_address': 'Salon address',
    'salon_address_placeholder': 'Enter your saloon address',
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
    'describe_salon_placeholder': 'Describe your saloon...',
    'salon_address_required': 'Salon address is required',
    'activity_domain_required': 'Activity domain is required',
    'salon_information_updated_successfully':
        'Salon information updated successfully',
    'salon_information_update_failed': 'Failed to update salon information',
    'notifications_empty_state': 'There are no notifications yet!',

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
    'total_campaigns': 'Total campaigns',
    'total_clicks': 'Total clicks',
    'clicks': 'Clicks',
    'no_campaigns_yet': 'There are no campaigns yet!',
    'go_to_influencers_message':
        'Go to Influencers and invite them for campaigns.',
    'go_to_influencers': 'Go to Influencers',
    'filter_coming_soon': 'Filter functionality coming soon',
    'campaign_with': 'Campaign with',
    'created_at': 'Created at',
    'value': 'Value',
    'completed_orders': 'Completed orders',
    'finish_campaign': 'Finish campaign',
    'copy_link': 'Copy link',
    'delete_campaign': 'Delete campaign',
    'delete_campaign_confirm': 'Are you sure you want to delete this campaign?',
    'campaign_finished_success': 'Campaign finished successfully!',
    'campaign_link_copied': 'Campaign link copied to clipboard!',
    'campaign_deleted_success': 'Campaign deleted successfully!',
    'influencers': 'Influencers',
    'settings': 'Settings',

    // Settings Screen
    'name': 'Name',
    'saloon_name': 'Salon Name',
    'profile_details': 'Profile Details',
    'enter_your_name': 'Enter your name',
    'enter_your_email': 'Enter your email',
    'set_your_password': 'Set your password',
    'profile_updated_successfully': 'Profile updated successfully',
    'profile_update_failed': 'Failed to update profile',
    'name_required': 'Name is required',
    'email_required': 'Email is required',
    'invalid_email': 'Please enter a valid email',
    'phone_required': 'Phone is required',
    'password_required': 'Password is required',
    'password_too_short': 'Password must be at least 6 characters',
    'saloon_information': 'Salon Information',

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
    'please_enter_salon_name': 'Please enter the saloon name',
    'salon_name_min_length': 'Salon name must contain at least 3 characters',
    'please_enter_salon_address': 'Please enter the saloon address',
    'salon_address_min_length': 'Address must contain at least 10 characters',
    'please_enter_salon_domain': 'Please enter the saloon domain',
    'salon_domain_min_length': 'Domain must contain at least 3 characters',
    'please_enter_description': 'Please enter a description',
    'description_min_length': 'Description must contain at least 10 characters',
    'description_max_length': 'Description must not exceed 500 characters',
    'please_enter_field': 'Please enter {field}',
    'please_enter_number': 'Please enter a number',
    'please_enter_valid_number': 'Please enter a valid number',
    'number_must_be_positive': 'Number must be positive',

    // Campaign Invite Dialog
    'campaign_invite_title':
        'Are you sure you want to invite this influencer and create a campaign for it?',
    'campaign_invite_instructions':
        'If yes, give us the details needed if you have promotions below.',
    'promotion_type': 'Promotion type',
    'select_type': 'Select type',
    'promotion_value': 'Promotion value',
    'please_select_promotion_type': 'Please select promotion type',
    'please_enter_promotion_value': 'Please enter promotion value',
    'create_campaign_invite': 'Create campaign & invite',
    'campaign_created_successfully': 'Campaign created successfully!',

    // Influencer Registration
    'create_influencer_account': 'Create Account',
    'complete_influencer_registration':
        'Complete registration to create your account and start making deals.',
    'your_information': 'Your information',
    'profile_picture': 'Profile picture',
    'upload_profile_picture': 'Upload your profile picture',
    'upload_your_profile_picture': 'Upload your profile picture',
    'pseudo': 'Pseudo',
    'enter_pseudo': 'Enter your special name',
    'enter_your_special_name': 'Enter your special name',
    'bio': 'Bio',
    'enter_bio': 'Describe yourself quickly',
    'describe_yourself_quickly': 'Describe yourself quickly',
    'zone': 'Zone',
    'select_zone': 'Select your zone',
    'select_your_zone': 'Select your zone',
    'your_socials': 'Your socials',
    'instagram': 'Instagram',
    'snapchat': 'Snapchat',
    'tiktok': 'TikTok',
    'youtube': 'YouTube',
    'enter_instagram_link': 'Enter Instagram link',
    'enter_tiktok_link': 'Enter TikTok link',
    'enter_youtube_link': 'Enter YouTube link',
    'add_more_later': 'You can add more later!',
    'account_created_success_message':
        'Account created successfully! Please check your email for the verification code.',
    'social_media': 'Social Media',
    'select_image_source': 'Select Image Source',
    'camera': 'Camera',
    'gallery': 'Gallery',
    'tap_to_change': 'Tap to change',
    'tap_to_select': 'Tap to select',
    'remove_image': 'Remove image',
    'add_link': 'Add link',
    'link_name': 'Link name',
    'link': 'Link',
    'link_name_placeholder': 'Link name',
    'link_placeholder': 'www.....',

    // Influencer Campaign
    'accept_campaign': 'Accept campaign',
    'refuse_campaign': 'Refuse campaign',
    'refuse_campaign_confirmation':
        'Are you sure you want to refuse this campaign? This action cannot be undone.',
    'refuse': 'Refuse',
    'waiting_for_you': 'Waiting for you',
    'on_going': 'On going',
    'finished': 'Finished',
    'orders': 'Orders',
    'campaigns_will_appear_here':
        'Campaign invitations and collaborations will appear here',
    'refresh': 'Refresh',
    'try_again': 'Try again',
    'total': 'Total',
    'message': 'Message',
  };
}
