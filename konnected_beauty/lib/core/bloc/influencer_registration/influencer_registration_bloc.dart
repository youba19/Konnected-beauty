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
  final String? profilePicture;
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
  final String? profilePicture;
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
    final isPseudoValid = event.pseudo.trim().isNotEmpty;
    final isBioValid = event.bio.trim().isNotEmpty;
    final isZoneValid = event.zone.trim().isNotEmpty;

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
      profilePicture: event.profilePicture,
      isPseudoValid: isPseudoValid,
      isBioValid: isBioValid,
      isZoneValid: isZoneValid,
      instagram: state.instagram,
      tiktok: state.tiktok,
      youtube: state.youtube,
    ));
  }

  void _onUpdateSocials(
      UpdateSocials event, Emitter<InfluencerRegistrationState> emit) {
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

      if (response['success'] == true) {
        // OTP validation successful, move to profile step
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
          successMessage:
              'OTP verified successfully! Please complete your profile.',
        ));
      } else {
        // OTP validation failed
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
          isOtpValid: false,
          isOtpError: true,
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
    } catch (e) {
      emit(InfluencerRegistrationError(state, 'OTP validation error: $e'));
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

      final response = await InfluencerAuthService.addProfile(
        pseudo: state.pseudo,
        bio: state.bio,
        zone: state.zone,
        profilePicture: state.profilePicture,
      );

      if (response['success'] == true) {
        // Profile submission successful, move to socials step
        emit(InfluencerRegistrationState(
          currentStep: 3,
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
        ));

        // Show success notification
        emit(InfluencerRegistrationSuccess(
          InfluencerRegistrationState(
            currentStep: 3,
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
          ),
          successMessage:
              'Profile added successfully! Please add your social media links.',
        ));
      } else {
        // Profile submission failed
        emit(InfluencerRegistrationError(
            state, response['message'] ?? 'Profile submission failed'));
      }
    } catch (e) {
      emit(InfluencerRegistrationError(state, 'Profile submission error: $e'));
    }
  }

  Future<void> _onSubmitSocials(
      SubmitSocials event, Emitter<InfluencerRegistrationState> emit) async {
    emit(InfluencerRegistrationLoading(state));

    try {
      final socials = [
        if (state.instagram.isNotEmpty)
          {"name": "instagram", "link": state.instagram},
        if (state.tiktok.isNotEmpty) {"name": "tiktok", "link": state.tiktok},
        if (state.youtube.isNotEmpty)
          {"name": "youtube", "link": state.youtube},
      ];

      final response = await InfluencerAuthService.addSocials(socials: socials);

      if (response['success'] == true) {
        // Socials submission successful, registration complete
        emit(InfluencerRegistrationSuccess(state,
            successMessage: 'Registration completed successfully!'));
      } else {
        // Socials submission failed
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

      if (response['success'] == true) {
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
          successMessage: 'OTP resent successfully! Please check your email.',
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
