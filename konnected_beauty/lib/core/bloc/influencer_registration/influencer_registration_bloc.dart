import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencer_auth_service.dart';
import '../../services/storage/token_storage_service.dart';

// Events
abstract class InfluencerRegistrationEvent {}

class UpdatePersonalInfo extends InfluencerRegistrationEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  UpdatePersonalInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
}

class UpdateOtp extends InfluencerRegistrationEvent {
  final String otp;
  UpdateOtp(this.otp);
}

class UpdateProfileInfo extends InfluencerRegistrationEvent {
  final String pseudo;
  final String bio;
  final String zone;
  final File? profilePicture;
  UpdateProfileInfo({
    required this.pseudo,
    required this.bio,
    required this.zone,
    this.profilePicture,
  });
}

class UpdateSocials extends InfluencerRegistrationEvent {
  final String instagram;
  final String tiktok;
  final String youtube;
  UpdateSocials({
    required this.instagram,
    required this.tiktok,
    required this.youtube,
  });
}

class NextStep extends InfluencerRegistrationEvent {}

class PreviousStep extends InfluencerRegistrationEvent {}

class GoToStep extends InfluencerRegistrationEvent {
  final int step;
  GoToStep(this.step);
}

class SubmitOtp extends InfluencerRegistrationEvent {}

class ResendOtp extends InfluencerRegistrationEvent {}

class SubmitRegistration extends InfluencerRegistrationEvent {}

class SubmitSignup extends InfluencerRegistrationEvent {}

class SubmitProfileInfo extends InfluencerRegistrationEvent {}

class SubmitSocials extends InfluencerRegistrationEvent {}

class ResetRegistration extends InfluencerRegistrationEvent {}

// States
class InfluencerRegistrationState {
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  final bool isDirectNavigation;

  // Personal Info
  final String name;
  final String email;
  final String phone;
  final String password;
  final bool isNameValid;
  final bool isEmailValid;
  final bool isPhoneValid;
  final bool isPasswordValid;

  // OTP
  final String otp;
  final bool isOtpValid;
  final bool isOtpError;

  // Profile Info
  final String pseudo;
  final String bio;
  final String zone;
  final File? profilePicture;
  final bool isPseudoValid;
  final bool isBioValid;
  final bool isZoneValid;

  // Socials
  final String instagram;
  final String tiktok;
  final String youtube;

  const InfluencerRegistrationState({
    required this.currentStep,
    required this.isLoading,
    this.errorMessage,
    this.isDirectNavigation = false,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.isNameValid,
    required this.isEmailValid,
    required this.isPhoneValid,
    required this.isPasswordValid,
    required this.otp,
    required this.isOtpValid,
    required this.isOtpError,
    required this.pseudo,
    required this.bio,
    required this.zone,
    this.profilePicture,
    required this.isPseudoValid,
    required this.isBioValid,
    required this.isZoneValid,
    required this.instagram,
    required this.tiktok,
    required this.youtube,
  });
}

class InfluencerRegistrationSuccess extends InfluencerRegistrationState {
  final String successMessage;

  InfluencerRegistrationSuccess(InfluencerRegistrationState state,
      {required this.successMessage})
      : super(
          currentStep: state.currentStep,
          isLoading: false,
          errorMessage: null,
          isDirectNavigation: state.isDirectNavigation,
          name: state.name,
          email: state.email,
          phone: state.phone,
          password: state.password,
          isNameValid: state.isNameValid,
          isEmailValid: state.isEmailValid,
          isPhoneValid: state.isPhoneValid,
          isPasswordValid: state.isPasswordValid,
          otp: state.otp,
          isOtpValid: state.isOtpValid,
          isOtpError: state.isOtpError,
          pseudo: state.pseudo,
          bio: state.bio,
          zone: state.zone,
          profilePicture: state.profilePicture,
          isPseudoValid: state.isPseudoValid,
          isBioValid: state.isBioValid,
          isZoneValid: state.isZoneValid,
          instagram: state.instagram,
          tiktok: state.tiktok,
          youtube: state.youtube,
        );
}

class InfluencerRegistrationInitial extends InfluencerRegistrationState {
  const InfluencerRegistrationInitial()
      : super(
          currentStep: 0,
          isLoading: false,
          name: '',
          email: '',
          phone: '',
          password: '',
          isNameValid: false,
          isEmailValid: false,
          isPhoneValid: false,
          isPasswordValid: false,
          otp: '',
          isOtpValid: false,
          isOtpError: false,
          pseudo: '',
          bio: '',
          zone: '',
          profilePicture: null,
          isPseudoValid: false,
          isBioValid: false,
          isZoneValid: false,
          instagram: '',
          tiktok: '',
          youtube: '',
        );
}

class InfluencerRegistrationLoading extends InfluencerRegistrationState {
  InfluencerRegistrationLoading(InfluencerRegistrationState state)
      : super(
          currentStep: state.currentStep,
          isLoading: true,
          name: state.name,
          email: state.email,
          phone: state.phone,
          password: state.password,
          isNameValid: state.isNameValid,
          isEmailValid: state.isEmailValid,
          isPhoneValid: state.isPhoneValid,
          isPasswordValid: state.isPasswordValid,
          otp: state.otp,
          isOtpValid: state.isOtpValid,
          isOtpError: state.isOtpError,
          pseudo: state.pseudo,
          bio: state.bio,
          zone: state.zone,
          profilePicture: state.profilePicture,
          isPseudoValid: state.isPseudoValid,
          isBioValid: state.isBioValid,
          isZoneValid: state.isZoneValid,
          instagram: state.instagram,
          tiktok: state.tiktok,
          youtube: state.youtube,
        );
}

class InfluencerRegistrationError extends InfluencerRegistrationState {
  InfluencerRegistrationError(
      InfluencerRegistrationState state, String errorMessage)
      : super(
          currentStep: state.currentStep,
          isLoading: false,
          errorMessage: errorMessage,
          name: state.name,
          email: state.email,
          phone: state.phone,
          password: state.password,
          isNameValid: state.isNameValid,
          isEmailValid: state.isEmailValid,
          isPhoneValid: state.isPhoneValid,
          isPasswordValid: state.isPasswordValid,
          otp: state.otp,
          isOtpValid: state.isOtpValid,
          isOtpError: state.isOtpError,
          pseudo: state.pseudo,
          bio: state.bio,
          zone: state.zone,
          profilePicture: state.profilePicture,
          isPseudoValid: state.isPseudoValid,
          isBioValid: state.isBioValid,
          isZoneValid: state.isZoneValid,
          instagram: state.instagram,
          tiktok: state.tiktok,
          youtube: state.youtube,
        );
}

// Bloc
class InfluencerRegistrationBloc
    extends Bloc<InfluencerRegistrationEvent, InfluencerRegistrationState> {
  // Track the last known profile picture to handle state transitions
  File? _lastKnownProfilePicture;

  InfluencerRegistrationBloc({int? initialStep})
      : super(InfluencerRegistrationState(
          currentStep: initialStep ?? 0,
          isLoading: false,
          name: '',
          email: '',
          phone: '',
          password: '',
          isNameValid: false,
          isEmailValid: false,
          isPhoneValid: false,
          isPasswordValid: false,
          otp: '',
          isOtpValid: false,
          isOtpError: false,
          pseudo: '',
          bio: '',
          zone: '',
          profilePicture: null,
          isPseudoValid: false,
          isBioValid: false,
          isZoneValid: false,
          instagram: '',
          tiktok: '',
          youtube: '',
        )) {
    on<UpdatePersonalInfo>(_onUpdatePersonalInfo);
    on<UpdateOtp>(_onUpdateOtp);
    on<UpdateProfileInfo>(_onUpdateProfileInfo);
    on<UpdateSocials>(_onUpdateSocials);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<SubmitOtp>(_onSubmitOtp);
    on<ResendOtp>(_onResendOtp);
    on<SubmitRegistration>(_onSubmitRegistration);
    on<SubmitSignup>(_onSubmitSignup);
    on<SubmitProfileInfo>(_onSubmitProfileInfo);
    on<SubmitSocials>(_onSubmitSocials);
    on<ResetRegistration>(_onResetRegistration);
  }

  void _onUpdatePersonalInfo(
      UpdatePersonalInfo event, Emitter<InfluencerRegistrationState> emit) {
    print('=== UPDATE PERSONAL INFO DEBUG ===');
    print('Name: "${event.name}"');
    print('Email: "${event.email}"');
    print('Phone: "${event.phone}"');
    print('Password: "${event.password}"');
    print('==================================');

    final isNameValid = event.name.trim().isNotEmpty;
    final isEmailValid = _isValidEmail(event.email);
    final isPhoneValid = event.phone.trim().isNotEmpty;
    final isPasswordValid = event.password.length >= 6;

    emit(InfluencerRegistrationState(
      currentStep: state.currentStep,
      isLoading: state.isLoading,
      name: event.name,
      email: event.email,
      phone: event.phone,
      password: event.password,
      isNameValid: isNameValid,
      isEmailValid: isEmailValid,
      isPhoneValid: isPhoneValid,
      isPasswordValid: isPasswordValid,
      otp: state.otp,
      isOtpValid: state.isOtpValid,
      isOtpError: state.isOtpError,
      pseudo: state.pseudo,
      bio: state.bio,
      zone: state.zone,
      isPseudoValid: state.isPseudoValid,
      isBioValid: state.isBioValid,
      isZoneValid: state.isZoneValid,
      instagram: state.instagram,
      tiktok: state.tiktok,
      youtube: state.youtube,
    ));
  }

  void _onUpdateOtp(
      UpdateOtp event, Emitter<InfluencerRegistrationState> emit) {
    // Debug logging
    print('=== UPDATE OTP DEBUG ===');
    print('Event OTP: "${event.otp}"');
    print('Event OTP length: ${event.otp.length}');
    print('Previous state OTP: "${state.otp}"');
    print('========================');

    final isOtpValid = event.otp.length == 6;
    emit(InfluencerRegistrationState(
      currentStep: state.currentStep,
      isLoading: state.isLoading,
      name: state.name,
      email: state.email,
      phone: state.phone,
      password: state.password,
      isNameValid: state.isNameValid,
      isEmailValid: state.isEmailValid,
      isPhoneValid: state.isPhoneValid,
      isPasswordValid: state.isPasswordValid,
      otp: event.otp,
      isOtpValid: isOtpValid,
      isOtpError: false,
      pseudo: state.pseudo,
      bio: state.bio,
      zone: state.zone,
      isPseudoValid: state.isPseudoValid,
      isBioValid: state.isBioValid,
      isZoneValid: state.isZoneValid,
      instagram: state.instagram,
      tiktok: state.tiktok,
      youtube: state.youtube,
    ));
  }

  void _onUpdateProfileInfo(
      UpdateProfileInfo event, Emitter<InfluencerRegistrationState> emit) {
    print('🔄 === UPDATE PROFILE INFO EVENT ===');
    print('👤 Pseudo: ${event.pseudo}');
    print('📝 Bio: ${event.bio}');
    print('📍 Zone: ${event.zone}');
    print('🖼️ Profile Picture: ${event.profilePicture}');
    print('🖼️ Profile Picture path: ${event.profilePicture?.path}');
    print(
        '🖼️ Profile Picture exists: ${event.profilePicture != null ? 'File object' : 'null'}');

    final isPseudoValid = event.pseudo.trim().isNotEmpty;
    final isBioValid = event.bio.trim().isNotEmpty;
    final isZoneValid = event.zone.trim().isNotEmpty;

    // IMPORTANT: Preserve existing profile picture if new one is null
    // Also check if we're in a state transition where profilePicture might be temporarily null
    final profilePictureToKeep = event.profilePicture ??
        (state.profilePicture ?? _lastKnownProfilePicture);

    // Update our last known profile picture for state transitions
    if (event.profilePicture != null) {
      _lastKnownProfilePicture = event.profilePicture;
      print(
          '🖼️ Updated _lastKnownProfilePicture with new file: ${event.profilePicture?.path}');
    } else if (state.profilePicture != null) {
      _lastKnownProfilePicture = state.profilePicture;
      print(
          '🖼️ Updated _lastKnownProfilePicture with state file: ${state.profilePicture?.path}');
    } else if (_lastKnownProfilePicture != null) {
      print(
          '🖼️ Keeping existing _lastKnownProfilePicture: ${_lastKnownProfilePicture?.path}');
    } else {
      print('🖼️ No profile picture available anywhere');
    }

    print(
        '🖼️ Preserving profile picture: ${profilePictureToKeep?.path ?? 'null'}');
    print(
        '🖼️ Last known profile picture: ${_lastKnownProfilePicture?.path ?? 'null'}');
    print(
        '🖼️ Final profilePictureToKeep: ${profilePictureToKeep?.path ?? 'null'}');

    emit(InfluencerRegistrationState(
      currentStep: state.currentStep,
      isLoading: state.isLoading,
      name: state.name,
      email: state.email,
      phone: state.phone,
      password: state.password,
      isNameValid: state.isNameValid,
      isEmailValid: state.isEmailValid,
      isPhoneValid: state.isPhoneValid,
      isPasswordValid: state.isPasswordValid,
      otp: state.otp,
      isOtpValid: state.isOtpValid,
      isOtpError: state.isOtpError,
      pseudo: event.pseudo,
      bio: event.bio,
      zone: event.zone,
      profilePicture: profilePictureToKeep, // Use preserved picture
      isPseudoValid: isPseudoValid,
      isBioValid: isBioValid,
      isZoneValid: isZoneValid,
      instagram: state.instagram,
      tiktok: state.tiktok,
      youtube: state.youtube,
    ));

    print('✅ Profile info updated in state');
    print('🖼️ New state profilePicture: ${profilePictureToKeep}');
    print('🖼️ New state profilePicture path: ${profilePictureToKeep?.path}');
  }

  void _onUpdateSocials(
      UpdateSocials event, Emitter<InfluencerRegistrationState> emit) {
    print('🔄 === UPDATE SOCIALS EVENT ===');
    print(
        '📱 Event Instagram: "${event.instagram}" (length: ${event.instagram.length})');
    print(
        '📱 Event TikTok: "${event.tiktok}" (length: ${event.tiktok.length})');
    print(
        '📱 Event YouTube: "${event.youtube}" (length: ${event.youtube.length})');
    print(
        '📱 Current State Instagram: "${state.instagram}" (length: ${state.instagram.length})');
    print(
        '📱 Current State TikTok: "${state.tiktok}" (length: ${state.tiktok.length})');
    print(
        '📱 Current State YouTube: "${state.youtube}" (length: ${state.youtube.length})');

    emit(InfluencerRegistrationState(
      currentStep: state.currentStep,
      isLoading: state.isLoading,
      name: state.name,
      email: state.email,
      phone: state.phone,
      password: state.password,
      isNameValid: state.isNameValid,
      isEmailValid: state.isEmailValid,
      isPhoneValid: state.isPhoneValid,
      isPasswordValid: state.isPasswordValid,
      otp: state.otp,
      isOtpValid: state.isOtpValid,
      isOtpError: state.isOtpError,
      pseudo: state.pseudo,
      bio: state.bio,
      zone: state.zone,
      profilePicture: state.profilePicture,
      isPseudoValid: state.isPseudoValid,
      isBioValid: state.isBioValid,
      isZoneValid: state.isZoneValid,
      instagram: event.instagram,
      tiktok: event.tiktok,
      youtube: event.youtube,
    ));
  }

  void _onNextStep(NextStep event, Emitter<InfluencerRegistrationState> emit) {
    if (state.currentStep < 3) {
      emit(InfluencerRegistrationState(
        currentStep: state.currentStep + 1,
        isLoading: state.isLoading,
        name: state.name,
        email: state.email,
        phone: state.phone,
        password: state.password,
        isNameValid: state.isNameValid,
        isEmailValid: state.isEmailValid,
        isPhoneValid: state.isPhoneValid,
        isPasswordValid: state.isPasswordValid,
        otp: state.otp,
        isOtpValid: state.isOtpValid,
        isOtpError: state.isOtpError,
        pseudo: state.pseudo,
        bio: state.bio,
        zone: state.zone,
        profilePicture: state.profilePicture,
        isPseudoValid: state.isPseudoValid,
        isBioValid: state.isBioValid,
        isZoneValid: state.isZoneValid,
        instagram: state.instagram,
        tiktok: state.tiktok,
        youtube: state.youtube,
      ));
    }
  }

  void _onPreviousStep(
      PreviousStep event, Emitter<InfluencerRegistrationState> emit) {
    if (state.currentStep > 0) {
      emit(InfluencerRegistrationState(
        currentStep: state.currentStep - 1,
        isLoading: state.isLoading,
        name: state.name,
        email: state.email,
        phone: state.phone,
        password: state.password,
        isNameValid: state.isNameValid,
        isEmailValid: state.isEmailValid,
        isPhoneValid: state.isPhoneValid,
        isPasswordValid: state.isPasswordValid,
        otp: state.otp,
        isOtpValid: state.isOtpValid,
        isOtpError: state.isOtpError,
        pseudo: state.pseudo,
        bio: state.bio,
        zone: state.zone,
        isPseudoValid: state.isPseudoValid,
        isBioValid: state.isBioValid,
        isZoneValid: state.isZoneValid,
        instagram: state.instagram,
        tiktok: state.tiktok,
        youtube: state.youtube,
      ));
    }
  }

  void _onGoToStep(GoToStep event, Emitter<InfluencerRegistrationState> emit) {
    emit(InfluencerRegistrationState(
      currentStep: event.step,
      isLoading: state.isLoading,
      name: state.name,
      email: state.email,
      phone: state.phone,
      password: state.password,
      isNameValid: state.isNameValid,
      isEmailValid: state.isEmailValid,
      isPhoneValid: state.isPhoneValid,
      isPasswordValid: state.isPasswordValid,
      otp: state.otp,
      isOtpValid: state.isOtpValid,
      isOtpError: state.isOtpError,
      pseudo: state.pseudo,
      bio: state.bio,
      zone: state.zone,
      profilePicture: state.profilePicture,
      isPseudoValid: state.isPseudoValid,
      isBioValid: state.isBioValid,
      isZoneValid: state.isZoneValid,
      instagram: state.instagram,
      tiktok: state.tiktok,
      youtube: state.youtube,
    ));
  }

  Future<void> _onSubmitSignup(
      SubmitSignup event, Emitter<InfluencerRegistrationState> emit) async {
    print('=== SUBMIT SIGNUP DEBUG ===');
    print('State Name: "${state.name}"');
    print('State Email: "${state.email}"');
    print('State Phone: "${state.phone}"');
    print('State Password: "${state.password}"');
    print('============================');

    emit(InfluencerRegistrationLoading(state));

    try {
      final response = await InfluencerAuthService.signup(
        name: state.name,
        email: state.email,
        phone: state.phone,
        password: state.password,
      );

      print('=== API RESPONSE DEBUG ===');
      print('Response: $response');
      print('Response type: ${response.runtimeType}');
      print('Success key exists: ${response.containsKey('success')}');
      print('Success value: ${response['success']}');
      print('Success == true: ${response['success'] == true}');
      print('==========================');

      // Check if response has success field, or if it's a successful response without it
      final isSuccess = response['success'] == true ||
          (response['success'] == null && response['message'] == null) ||
          response.containsKey('id') ||
          response.containsKey('token') ||
          response.containsKey('user');

      if (isSuccess) {
        print('Emitting SUCCESS state - moving to OTP step');
        // Signup successful, proceed to OTP step (like salon registration)
        emit(InfluencerRegistrationState(
          currentStep: 1,
          isLoading: false,
          name: state.name,
          email: state.email,
          phone: state.phone,
          password: state.password,
          isNameValid: state.isNameValid,
          isEmailValid: state.isEmailValid,
          isPhoneValid: state.isPhoneValid,
          isPasswordValid: state.isPasswordValid,
          otp: state.otp,
          isOtpValid: state.isOtpValid,
          isOtpError: false,
          pseudo: state.pseudo,
          bio: state.bio,
          zone: state.zone,
          profilePicture: state.profilePicture,
          isPseudoValid: state.isPseudoValid,
          isBioValid: state.isBioValid,
          isZoneValid: state.isZoneValid,
          instagram: state.instagram,
          tiktok: state.tiktok,
          youtube: state.youtube,
        ));
      } else {
        print('Emitting ERROR state');
        // Signup failed - handle both string and list error messages
        String errorMessage = 'Signup failed';
        if (response['message'] != null) {
          if (response['message'] is List) {
            // If message is a list, join the messages
            errorMessage = (response['message'] as List).join(', ');
          } else if (response['message'] is String) {
            errorMessage = response['message'];
          }
        }
        emit(InfluencerRegistrationError(state, errorMessage));
      }
    } catch (e) {
      emit(InfluencerRegistrationError(state, 'Signup error: $e'));
    }
  }

  Future<void> _onSubmitOtp(
      SubmitOtp event, Emitter<InfluencerRegistrationState> emit) async {
    emit(InfluencerRegistrationLoading(state));

    // Debug logging to see what's in the state
    print('=== OTP SUBMISSION DEBUG ===');
    print('Email: "${state.email}"');
    print('OTP: "${state.otp}"');
    print('Email length: ${state.email.length}');
    print('OTP length: ${state.otp.length}');
    print('============================');

    try {
      final response = await InfluencerAuthService.validateOtp(
        email: state.email,
        otp: state.otp,
      );

      print('🔐 === OTP VALIDATION RESPONSE ===');
      print('Response: $response');
      print('Response type: ${response.runtimeType}');
      print('Success key exists: ${response.containsKey('success')}');
      print('Success value: ${response['success']}');
      print('Message: ${response['message']}');
      print('Status code: ${response['statusCode']}');
      print('=====================================');

      // Check if response indicates success (either success: true or statusCode: 200)
      final isSuccess =
          response['success'] == true || response['statusCode'] == 200;

      if (isSuccess) {
        // OTP verification successful - save tokens and move to profile step
        print('🔐 === OTP VERIFIED - SAVING TOKENS ===');

        // Extract and save tokens from response
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          final accessToken = data['access_token'] as String?;
          final refreshToken = data['refresh_token'] as String?;

          print(
              '🔑 Access Token: ${accessToken != null ? "Present" : "Missing"}');
          print(
              '🔄 Refresh Token: ${refreshToken != null ? "Present" : "Missing"}');

          if (accessToken != null) {
            await TokenStorageService.saveAccessToken(accessToken);
            print('💾 Access token saved after OTP validation');
          } else {
            print('⚠️ No access token in OTP validation response');
          }

          if (refreshToken != null) {
            await TokenStorageService.saveRefreshToken(refreshToken);
            print('💾 Refresh token saved after OTP validation');

            // Verify the token was saved
            final savedRefreshToken =
                await TokenStorageService.getRefreshToken();
            print(
                '🔍 Verification - Saved refresh token: ${savedRefreshToken != null ? "Present" : "Missing"}');
            if (savedRefreshToken != null) {
              print(
                  '🔍 Token preview: ${savedRefreshToken.substring(0, 20)}...');
            }
          } else {
            print('⚠️ No refresh token in OTP validation response');
          }

          // Save user role as 'influencer' for profile submission
          await TokenStorageService.saveUserRole('influencer');
          print('👤 User role saved as: influencer');
        } else {
          print('⚠️ No data in OTP validation response');
        }

        // Move to profile step
        print('🔐 === OTP VERIFIED - MOVING TO STEP 2 ===');
        emit(InfluencerRegistrationState(
          currentStep: 2,
          isLoading: false,
          name: state.name,
          email: state.email,
          phone: state.phone,
          password: state.password,
          isNameValid: state.isNameValid,
          isEmailValid: state.isEmailValid,
          isPhoneValid: state.isPhoneValid,
          isPasswordValid: state.isPasswordValid,
          otp: state.otp,
          isOtpValid: true,
          isOtpError: false,
          pseudo: state.pseudo,
          bio: state.bio,
          zone: state.zone,
          profilePicture: state.profilePicture,
          isPseudoValid: state.isPseudoValid,
          isBioValid: state.isBioValid,
          isZoneValid: state.isZoneValid,
          instagram: state.instagram,
          tiktok: state.tiktok,
          youtube: state.youtube,
        ));

        // Show success notification
        print('🎉 === EMITTING SUCCESS NOTIFICATION ===');
        emit(InfluencerRegistrationSuccess(
          InfluencerRegistrationState(
            currentStep: 2,
            isLoading: false,
            name: state.name,
            email: state.email,
            phone: state.phone,
            password: state.password,
            isNameValid: state.isNameValid,
            isEmailValid: state.isEmailValid,
            isPhoneValid: state.isPhoneValid,
            isPasswordValid: state.isPasswordValid,
            otp: state.otp,
            isOtpValid: true,
            isOtpError: false,
            pseudo: state.pseudo,
            bio: state.bio,
            zone: state.zone,
            profilePicture: state.profilePicture,
            isPseudoValid: state.isPseudoValid,
            isBioValid: state.isBioValid,
            isZoneValid: state.isZoneValid,
            instagram: state.instagram,
            tiktok: state.tiktok,
            youtube: state.youtube,
          ),
          successMessage: 'otp_verified_success',
        ));
      } else {
        // OTP validation failed - show simple error message
        final errorMessage = response['message'] ?? 'invalid_verification_code';
        print('❌ OTP validation failed: $errorMessage');
        emit(InfluencerRegistrationError(state, errorMessage));
      }
    } catch (e) {
      // Show simple error message for network/API issues
      String errorMessage = 'verification_failed';
      if (e.toString().contains('Failed to validate OTP')) {
        errorMessage = 'invalid_verification_code';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'network_error_try_again';
      }
      emit(InfluencerRegistrationError(state, errorMessage));
    }
  }

  Future<void> _onSubmitProfileInfo(SubmitProfileInfo event,
      Emitter<InfluencerRegistrationState> emit) async {
    emit(InfluencerRegistrationLoading(state));

    try {
      print('🔐 === SUBMITTING PROFILE ===');
      print('👤 Pseudo: ${state.pseudo}');
      print('📝 Bio: ${state.bio}');
      print('📍 Zone: ${state.zone}');
      print('🖼️ Profile Picture: ${state.profilePicture}');
      print('🖼️ Profile Picture path: ${state.profilePicture?.path}');
      print('🖼️ _lastKnownProfilePicture: ${_lastKnownProfilePicture?.path}');

      // IMPORTANT: Use preserved profile picture if state.profilePicture is null
      final profilePictureToSend =
          state.profilePicture ?? _lastKnownProfilePicture;
      print(
          '🖼️ Final profile picture to send: ${profilePictureToSend?.path ?? 'null'}');

      final response = await InfluencerAuthService.addProfile(
        pseudo: state.pseudo,
        bio: state.bio,
        zone: state.zone,
        profilePicture: profilePictureToSend,
      );

      print('📊 === PROFILE SUBMISSION RESPONSE ===');
      print('📄 Full response: $response');
      print('🔍 Success field: ${response['success']}');
      print('🔍 Success type: ${response['success'].runtimeType}');
      print('🔍 Success == true: ${response['success'] == true}');

      if (response['success'] == true) {
        // Profile created successfully - always navigate to socials step
        final profileStatus = response['profileStatus'];
        final shouldNavigateToSocials =
            true; // Always navigate to socials after profile creation

        print('📊 Profile submission response:');
        print('   - Success: ${response['success']}');
        print('   - Status: $profileStatus');
        print('   - Should navigate to socials: $shouldNavigateToSocials');

        // Always move to socials step (step 3)
        final nextStep = 3;

        print('🎯 Navigation decision:');
        print('   - Current step: ${state.currentStep}');
        print('   - Next step: $nextStep');
        print('   - Will navigate: $shouldNavigateToSocials');

        // Create the new state with the updated step
        final newState = InfluencerRegistrationState(
          currentStep: nextStep,
          isLoading: false,
          name: state.name,
          email: state.email,
          phone: state.phone,
          password: state.password,
          isNameValid: state.isNameValid,
          isEmailValid: state.isEmailValid,
          isPhoneValid: state.isPhoneValid,
          isPasswordValid: state.isPasswordValid,
          otp: state.otp,
          isOtpValid: state.isOtpValid,
          isOtpError: state.isOtpError,
          pseudo: state.pseudo,
          bio: state.bio,
          zone: state.zone,
          profilePicture: state.profilePicture,
          isPseudoValid: state.isPseudoValid,
          isBioValid: state.isBioValid,
          isZoneValid: state.isZoneValid,
          instagram: state.instagram,
          tiktok: state.tiktok,
          youtube: state.youtube,
        );

        // Show success notification with appropriate message
        final successMessage =
            'Profile added successfully! Please add your social media links.';

        // First emit the state change to update the step
        print('🔄 === EMITTING STATE CHANGE ===');
        print('   - Next step: $nextStep');
        print('   - State type: InfluencerRegistrationState');

        emit(newState);

        // Add a small delay to ensure the UI rebuilds before showing success
        await Future.delayed(const Duration(milliseconds: 100));

        // Then emit the success notification
        print('🎉 === EMITTING SUCCESS NOTIFICATION ===');
        print('   - Success message: $successMessage');
        print('   - State type: InfluencerRegistrationSuccess');

        emit(InfluencerRegistrationSuccess(newState,
            successMessage: successMessage));

        print('✅ Both states emitted successfully');
      } else {
        // Profile submission failed
        emit(InfluencerRegistrationError(
            state, response['message'] ?? 'Profile submission failed'));
      }
    } catch (e) {
      emit(InfluencerRegistrationError(state, 'Profile submission error: $e'));
    }
  }

  // Helper method to validate URLs
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _onSubmitSocials(
      SubmitSocials event, Emitter<InfluencerRegistrationState> emit) async {
    emit(InfluencerRegistrationLoading(state));

    try {
      // Validate that at least one social media link is provided
      print('🔍 === SOCIAL MEDIA VALIDATION IN BLOC ===');
      print(
          '📱 State Instagram: "${state.instagram}" (length: ${state.instagram.length})');
      print(
          '📱 State TikTok: "${state.tiktok}" (length: ${state.tiktok.length})');
      print(
          '📱 State YouTube: "${state.youtube}" (length: ${state.youtube.length})');
      print(
          '🔍 All empty: ${state.instagram.isEmpty && state.tiktok.isEmpty && state.youtube.isEmpty}');

      // Instagram is required, TikTok and YouTube are optional
      if (state.instagram.isEmpty) {
        print('❌ Instagram link is required');
        emit(InfluencerRegistrationError(state, 'Instagram link is required'));
        return;
      }

      // Validate URL format for provided links
      final List<String> validationErrors = [];
      if (state.instagram.isNotEmpty && !_isValidUrl(state.instagram)) {
        validationErrors.add('Instagram URL is not valid');
      }
      if (state.tiktok.isNotEmpty && !_isValidUrl(state.tiktok)) {
        validationErrors.add('TikTok URL is not valid');
      }
      if (state.youtube.isNotEmpty && !_isValidUrl(state.youtube)) {
        validationErrors.add('YouTube URL is not valid');
      }

      if (validationErrors.isNotEmpty) {
        print('❌ URL validation errors: $validationErrors');
        emit(InfluencerRegistrationError(state, validationErrors.join(', ')));
        return;
      }

      final socials = [
        if (state.instagram.isNotEmpty)
          {"name": "instagram", "link": state.instagram},
        if (state.tiktok.isNotEmpty) {"name": "tiktok", "link": state.tiktok},
        if (state.youtube.isNotEmpty)
          {"name": "youtube", "link": state.youtube},
      ];

      print('📱 === SUBMITTING SOCIALS ===');
      print('📱 Instagram: ${state.instagram}');
      print('📱 TikTok: ${state.tiktok}');
      print('📱 YouTube: ${state.youtube}');
      print('📱 Final socials array: $socials');
      print('📱 JSON payload: ${jsonEncode({"socials": socials})}');
      print('📱 Socials count: ${socials.length}');

      final response = await InfluencerAuthService.addSocials(socials: socials);

      print('📱 === SOCIALS API RESPONSE ===');
      print('📱 Response: $response');
      print('📱 Success: ${response['success']}');
      print('📱 Message: ${response['message']}');
      print('📱 Status Code: ${response['statusCode']}');

      // Check for success based on status code and message
      if (response['statusCode'] == 200 &&
          response['message']
                  ?.toString()
                  .toLowerCase()
                  .contains('successfully') ==
              true) {
        // Socials submission successful, registration complete
        print('✅ Socials added successfully!');
        emit(InfluencerRegistrationSuccess(state,
            successMessage: 'socials_added_success'));
      } else {
        // Socials submission failed
        print('❌ Socials submission failed: ${response['message']}');
        emit(InfluencerRegistrationError(
            state, response['message'] ?? 'Socials submission failed'));
      }
    } catch (e) {
      emit(InfluencerRegistrationError(state, 'Socials submission error: $e'));
    }
  }

  Future<void> _onResendOtp(
      ResendOtp event, Emitter<InfluencerRegistrationState> emit) async {
    try {
      final response =
          await InfluencerAuthService.resendOtp(email: state.email);

      // Check for success based on status code and message
      if (response['statusCode'] == 200 &&
          response['message']
                  ?.toString()
                  .toLowerCase()
                  .contains('successfully') ==
              true) {
        // OTP resent successfully
        emit(InfluencerRegistrationState(
          currentStep: state.currentStep,
          isLoading: false,
          name: state.name,
          email: state.email,
          phone: state.phone,
          password: state.password,
          isNameValid: state.isNameValid,
          isEmailValid: state.isEmailValid,
          isPhoneValid: state.isPhoneValid,
          isPasswordValid: state.isPasswordValid,
          otp: state.otp,
          isOtpValid: state.isOtpValid,
          isOtpError: false,
          pseudo: state.pseudo,
          bio: state.bio,
          zone: state.zone,
          profilePicture: state.profilePicture,
          isPseudoValid: state.isPseudoValid,
          isBioValid: state.isBioValid,
          isZoneValid: state.isZoneValid,
          instagram: state.instagram,
          tiktok: state.tiktok,
          youtube: state.youtube,
        ));

        // Show success notification for OTP resend
        emit(InfluencerRegistrationSuccess(
          InfluencerRegistrationState(
            currentStep: state.currentStep,
            isLoading: false,
            name: state.name,
            email: state.email,
            phone: state.phone,
            password: state.password,
            isNameValid: state.isNameValid,
            isEmailValid: state.isEmailValid,
            isPhoneValid: state.isPhoneValid,
            isPasswordValid: state.isPasswordValid,
            otp: state.otp,
            isOtpValid: state.isOtpValid,
            isOtpError: false,
            pseudo: state.pseudo,
            bio: state.bio,
            zone: state.zone,
            profilePicture: state.profilePicture,
            isPseudoValid: state.isPseudoValid,
            isBioValid: state.isBioValid,
            isZoneValid: state.isZoneValid,
            instagram: state.instagram,
            tiktok: state.tiktok,
            youtube: state.youtube,
          ),
          successMessage: 'otp_resent_success',
        ));
      } else {
        // OTP resend failed
        emit(InfluencerRegistrationError(
            state, response['message'] ?? 'Failed to resend OTP'));
      }
    } catch (e) {
      emit(InfluencerRegistrationError(state, 'OTP resend error: $e'));
    }
  }

  void _onSubmitRegistration(
      SubmitRegistration event, Emitter<InfluencerRegistrationState> emit) {
    // TODO: Implement final registration submission
  }

  void _onResetRegistration(
      ResetRegistration event, Emitter<InfluencerRegistrationState> emit) {
    emit(const InfluencerRegistrationInitial());
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
