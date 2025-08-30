import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/forms/custom_text_field.dart';

import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../core/bloc/influencers/influencer_profile_bloc.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String _selectedZone = '';
  File? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();
  bool _controllersPopulated =
      false; // Track if controllers have been populated
  bool _zoneManuallyChanged = false; // Track if user manually changed the zone

  List<String> _zones = [
    // Île-de-France
    'Paris',
    'Boulogne-Billancourt',
    'Saint-Denis',
    'Argenteuil',
    'Montreuil',
    'Nanterre',
    'Vitry-sur-Seine',
    'Créteil',
    'Aulnay-sous-Bois',
    'Versailles',

    // Auvergne-Rhône-Alpes
    'Lyon',
    'Grenoble',
    'Saint-Étienne',
    'Annecy',
    'Chambéry',
    'Clermont-Ferrand',
    'Saint-Priest',
    'Vaulx-en-Velin',
    'Villeurbanne',
    'Le Puy-en-Velay',

    // Provence-Alpes-Côte d\'Azur
    'Marseille',
    'Nice',
    'Toulon',
    'Aix-en-Provence',
    'Avignon',
    'Cannes',
    'Antibes',
    'La Seyne-sur-Mer',
    'Hyères',
    'Fréjus',

    // Nouvelle-Aquitaine
    'Bordeaux',
    'Limoges',
    'Poitiers',
    'La Rochelle',
    'Angoulême',
    'Pau',
    'Bayonne',
    'Biarritz',
    'Périgueux',
    'Arcachon',

    // Occitanie
    'Toulouse',
    'Montpellier',
    'Nîmes',
    'Perpignan',
    'Béziers',
    'Narbonne',
    'Albi',
    'Carcassonne',
    'Tarbes',
    'Castres',

    // Pays de la Loire
    'Nantes',
    'Angers',
    'Le Mans',
    'Saint-Nazaire',
    'Cholet',
    'Saint-Herblain',
    'Saint-Sébastien-sur-Loire',
    'Rezé',
    'Saint-Avertin',
    'La Roche-sur-Yon',

    // Grand Est
    'Strasbourg',
    'Reims',
    'Metz',
    'Nancy',
    'Mulhouse',
    'Colmar',
    'Troyes',
    'Charleville-Mézières',
    'Châlons-en-Champagne',
    'Épinal',

    // Hauts-de-France
    'Lille',
    'Amiens',
    'Roubaix',
    'Tourcoing',
    'Dunkerque',
    'Valenciennes',
    'Villeneuve-d\'Ascq',
    'Saint-Quentin',
    'Beauvais',
    'Arras',

    // Bourgogne-Franche-Comté
    'Dijon',
    'Besançon',
    'Chalon-sur-Saône',
    'Nevers',
    'Auxerre',
    'Mâcon',
    'Sens',
    'Le Creusot',
    'Montceau-les-Mines',
    'Beaune',

    // Centre-Val de Loire
    'Tours',
    'Orléans',
    'Blois',
    'Bourges',
    'Chartres',
    'Châteauroux',
    'Joué-lès-Tours',
    'Vierzon',
    'Fleury-les-Aubrais',
    'Saint-Jean-de-Braye',

    // Normandie
    'Rouen',
    'Le Havre',
    'Caen',
    'Cherbourg-en-Cotentin',
    'Évreux',
    'Dieppe',
    'Saint-Étienne-du-Rouvray',
    'Sotteville-lès-Rouen',
    'Le Grand-Quevilly',
    'Petit-Quevilly',

    // Bretagne
    'Rennes',
    'Brest',
    'Quimper',
    'Vannes',
    'Saint-Malo',
    'Saint-Brieuc',
    'Lorient',
    'Lanester',
    'Fougères',
    'Concarneau',

    // Corse
    'Ajaccio',
    'Bastia',
    'Porto-Vecchio',
    'Calvi',
    'Corte',
    'Sartène',
    'Propriano',
    'L\'Île-Rousse',
    'Bonifacio',
    'Penta-di-Casinca'
  ];

  @override
  void initState() {
    super.initState();
    // Load profile data using BLoC
    context.read<InfluencerProfileBloc>().add(LoadInfluencerProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pseudoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Check if profile picture URL is valid
  bool _isValidProfilePictureUrl(String url) {
    if (url.isEmpty || url == 'null') return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Populate controllers with profile data
  void _populateControllers(InfluencerProfileLoaded profile) {
    // Only populate controllers if they haven't been populated yet
    if (_controllersPopulated) {
      // Check if the profile data has changed significantly
      final currentName = _nameController.text.trim();
      final currentPseudo = _pseudoController.text.trim();
      final currentPhone = _phoneController.text.trim();
      final currentBio = _bioController.text.trim();
      final currentZone = _selectedZone;

      // Only update if the profile data is significantly different
      if (currentName == profile.name &&
          currentPseudo == profile.pseudo &&
          currentPhone == profile.phoneNumber &&
          currentBio == profile.bio &&
          currentZone == profile.zone) {
        // Profile data unchanged, skip controller update
        return;
      }
    }

    // Update controllers with new profile data
    _nameController.text = profile.name;
    _pseudoController.text = profile.pseudo;
    _emailController.text = profile.email;
    _phoneController.text = profile.phoneNumber;
    _bioController.text = profile.bio;

    // Update zone from API only if user hasn't manually changed it
    if (!_zoneManuallyChanged) {
      _selectedZone = profile.zone.isNotEmpty ? profile.zone : 'Paris';
    }

    // Add the zone to the list if it's not already there
    if (_selectedZone.isNotEmpty && !_zones.contains(_selectedZone)) {
      _zones.add(_selectedZone);
    }

    // Force UI update to show the selected zone
    setState(() {});

    _controllersPopulated = true; // Mark as populated
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      TopNotificationService.showError(
        context: context,
        message: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageFile = null;
    });
  }

  /// Track user changes to form fields
  void _onFieldChanged() {
    // Field change detected
  }

  Future<void> _updateProfile() async {
    try {
      // Validate that all required fields are filled
      final name = _nameController.text.trim();
      final pseudo = _pseudoController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final bio = _bioController.text.trim();
      final zone = _selectedZone;

      // Check if any required field is empty
      if (name.isEmpty) {
        TopNotificationService.showError(
          context: context,
          message: 'Name is required',
        );
        return;
      }
      if (pseudo.isEmpty) {
        TopNotificationService.showError(
          context: context,
          message: 'Pseudo is required',
        );
        return;
      }
      if (phoneNumber.isEmpty) {
        TopNotificationService.showError(
          context: context,
          message: 'Phone number is required',
        );
        return;
      }
      if (bio.isEmpty) {
        TopNotificationService.showError(
          context: context,
          message: 'Bio is required',
        );
        return;
      }
      if (zone.isEmpty) {
        TopNotificationService.showError(
          context: context,
          message: 'Zone is required',
        );
        return;
      }

      // Check if there are any actual changes
      final currentState = context.read<InfluencerProfileBloc>().state;
      if (currentState is InfluencerProfileLoaded) {
        // Simple change detection
        final nameChanged = name != currentState.name.trim();
        final pseudoChanged = pseudo != currentState.pseudo.trim();
        final phoneChanged = phoneNumber != currentState.phoneNumber.trim();
        final bioChanged = bio != currentState.bio.trim();
        final zoneChanged = zone != currentState.zone;
        final imageChanged = _selectedImageFile != null;

        final hasChanges = nameChanged ||
            pseudoChanged ||
            phoneChanged ||
            bioChanged ||
            zoneChanged ||
            imageChanged;

        if (!hasChanges) {
          // No changes detected
          TopNotificationService.showInfo(
            context: context,
            message: 'No changes detected',
          );
          return;
        }
      }

      // Use BLoC to update profile directly
      context.read<InfluencerProfileBloc>().add(
            UpdateInfluencerProfile(
              name: name,
              pseudo: pseudo,
              phoneNumber: phoneNumber,
              bio: bio,
              zone: zone,
              profilePictureFile: _selectedImageFile,
            ),
          );

      // Clear selected image after dispatching update event
      if (_selectedImageFile != null) {
        setState(() {
          _selectedImageFile = null;
        });
      }
    } catch (e) {
      TopNotificationService.showError(
        context: context,
        message: 'Error updating profile: ${e.toString()}',
      );
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(height: 16),

          // Title with Icon
          Row(
            children: [
              const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.getString(context, 'personal_information') ??
                    'Personal information',
                style: AppTheme.headingStyle.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureField(String profilePicture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'profile_picture') ??
              'Profile picture',
          style: AppTheme.subtitleStyle.copyWith(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.transparentBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                // Show selected image preview, current profile picture, or default icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          ),
                        )
                      : _isValidProfilePictureUrl(profilePicture)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                profilePicture,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: const Color(0xFF22C55E),
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedImageFile != null
                        ? 'Image selected: ${_selectedImageFile!.path.split('/').last}'
                        : _isValidProfilePictureUrl(profilePicture)
                            ? 'Current: ${profilePicture.split('/').last}'
                            : 'Tap to upload profile picture',
                    style: AppTheme.subtitleStyle.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (_selectedImageFile != null)
                  GestureDetector(
                    onTap: _clearSelectedImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.upload,
                  color: Colors.white70,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.transparentBackground,
            border: Border.all(color: AppTheme.borderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedZone.isNotEmpty ? _selectedZone : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            isExpanded: true,
            dropdownColor: AppTheme.primaryColor,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.textPrimaryColor,
            ),
            hint: const Text(
              'Select Zone',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            items: _zones.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null && newValue != _selectedZone) {
                setState(() {
                  _selectedZone = newValue;
                  _zoneManuallyChanged =
                      true; // Mark that user manually changed the zone
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return BlocBuilder<InfluencerProfileBloc, InfluencerProfileState>(
      builder: (context, state) {
        final isUpdating = state is InfluencerProfileUpdating;
        final isValidating = state is InfluencerProfileValidating;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isUpdating || isValidating) ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isUpdating) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Updating...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (isValidating) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Validating...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error, String? details) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: AppTheme.headingStyle.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTheme.subtitleStyle.copyWith(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (details != null) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: AppTheme.subtitleStyle.copyWith(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context
                  .read<InfluencerProfileBloc>()
                  .add(RefreshInfluencerProfile());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: BlocConsumer<InfluencerProfileBloc, InfluencerProfileState>(
              listener: (context, state) {
                if (state is InfluencerProfileUpdating) {
                  // No notification needed during update
                } else if (state is InfluencerProfileValidating) {
                  // Show validation errors
                  for (final error in state.validationErrors.entries) {
                    TopNotificationService.showError(
                      context: context,
                      message: '${error.key}: ${error.value}',
                    );
                  }
                } else if (state is InfluencerProfileUpdated) {
                  // Show success message
                  TopNotificationService.showSuccess(
                    context: context,
                    message: state.message,
                  );

                  // Reset the zone change flag since update was successful
                  _zoneManuallyChanged = false;

                  // Navigate back to profile screen after successful update
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(context);
                  });
                } else if (state is InfluencerProfileError) {
                  // Show error message with details if available
                  String errorMessage = state.error;
                  if (state.details != null && state.details!.isNotEmpty) {
                    errorMessage += '\nDetails: ${state.details}';
                  }
                  TopNotificationService.showError(
                    context: context,
                    message: errorMessage,
                  );
                }
              },
              builder: (context, state) {
                if (state is InfluencerProfileLoading ||
                    state is InfluencerProfileUpdating) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER - Now scrollable
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Loading content
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF22C55E),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading profile...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                } else if (state is InfluencerProfileError) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER - Now scrollable
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Error content
                        _buildErrorWidget(state.error, state.details),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                } else if (state is InfluencerProfileLoaded ||
                    state is InfluencerProfileValidating) {
                  // Use the appropriate profile data
                  final profileData = state is InfluencerProfileValidating
                      ? state.currentProfile
                      : state as InfluencerProfileLoaded;

                  // Populate controllers when profile is loaded
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _populateControllers(profileData);
                  });

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER - Now scrollable
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Profile Picture
                        _buildProfilePictureField(profileData.profilePicture),
                        const SizedBox(height: 24),

                        // Name
                        CustomTextField(
                          label: AppTranslations.getString(context, 'name') ??
                              'Name',
                          placeholder: AppTranslations.getString(
                                  context, 'enter_name') ??
                              'Enter your name',
                          controller: _nameController,
                          onChanged: (value) => _onFieldChanged(),
                        ),
                        const SizedBox(height: 20),

                        // Pseudo
                        CustomTextField(
                          label: AppTranslations.getString(context, 'pseudo') ??
                              'Pseudo',
                          placeholder: AppTranslations.getString(
                                  context, 'enter_pseudo') ??
                              'Enter your pseudo',
                          controller: _pseudoController,
                          onChanged: (value) => _onFieldChanged(),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        CustomTextField(
                          label: AppTranslations.getString(context, 'email') ??
                              'Email',
                          placeholder: AppTranslations.getString(
                                  context, 'enter_email') ??
                              'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Phone
                        CustomTextField(
                          label: AppTranslations.getString(context, 'phone') ??
                              'Phone',
                          placeholder: AppTranslations.getString(
                                  context, 'enter_phone') ??
                              'Enter your phone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) => _onFieldChanged(),
                        ),
                        const SizedBox(height: 20),

                        // Bio
                        CustomTextField(
                          label: AppTranslations.getString(context, 'bio') ??
                              'Bio',
                          placeholder:
                              AppTranslations.getString(context, 'enter_bio') ??
                                  'Enter your bio',
                          controller: _bioController,
                          maxLines: 3,
                          onChanged: (value) => _onFieldChanged(),
                        ),
                        const SizedBox(height: 20),

                        // Zone
                        _buildZoneField(),
                        const SizedBox(height: 32),

                        // Edit Button
                        _buildEditButton(),
                        const SizedBox(height: 20),

                        // Extra padding at bottom for better scrolling
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                } else if (state is InfluencerProfileUpdated) {
                  // Show loading while navigating back
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Profile updated successfully!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Navigating back...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // This should never happen, but provide a fallback
                  return const Center(
                    child: Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
