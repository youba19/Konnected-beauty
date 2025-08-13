import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api/salon_auth_service.dart';
import '../../services/storage/token_storage_service.dart';

// Events
abstract class SaloonRegistrationEvent {}

class UpdatePersonalInfo extends SaloonRegistrationEvent {
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

class UpdateOpenHour extends SaloonRegistrationEvent {
  final String openHour;
  UpdateOpenHour(this.openHour);
}

class UpdateClosingHour extends SaloonRegistrationEvent {
  final String closingHour;
  UpdateClosingHour(this.closingHour);
}

class UpdateOtp extends SaloonRegistrationEvent {
  final String otp;
  UpdateOtp(this.otp);
}

class UpdateSalonInfo extends SaloonRegistrationEvent {
  final String saloonName;
  final String saloonAddress;
  final String saloonDomain;
  UpdateSalonInfo({
    required this.saloonName,
    required this.saloonAddress,
    required this.saloonDomain,
  });
}

class UpdateSalonProfile extends SaloonRegistrationEvent {
  final String description;
  final String openHour;
  final String closingHour;
  UpdateSalonProfile({
    required this.description,
    required this.openHour,
    required this.closingHour,
  });
}

class UploadImage extends SaloonRegistrationEvent {
  final ImageSource source;
  UploadImage({this.source = ImageSource.gallery});
}

class RemoveImage extends SaloonRegistrationEvent {
  final int index;
  RemoveImage(this.index);
}

class NextStep extends SaloonRegistrationEvent {}

class PreviousStep extends SaloonRegistrationEvent {}

class GoToStep extends SaloonRegistrationEvent {
  final int step;
  GoToStep(this.step);
}

class SubmitOtp extends SaloonRegistrationEvent {}

class ResendOtp extends SaloonRegistrationEvent {}

class SubmitRegistration extends SaloonRegistrationEvent {}

class SubmitSignup extends SaloonRegistrationEvent {}

class SubmitSalonInfo extends SaloonRegistrationEvent {}

class SubmitSalonProfile extends SaloonRegistrationEvent {}

class ResetRegistration extends SaloonRegistrationEvent {}

// States
class SaloonRegistrationState {
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  final bool
      isDirectNavigation; // Flag to track if we came from direct navigation

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

  // Salon Info
  final String saloonName;
  final String saloonAddress;
  final String saloonDomain;
  final bool isSaloonNameValid;
  final bool isSaloonAddressValid;
  final bool isSaloonDomainValid;

  // Salon Profile
  final String description;
  final String openHour;
  final String closingHour;
  final List<File> uploadedImages;
  final List<String> timeOptions;

  const SaloonRegistrationState({
    required this.currentStep,
    required this.isLoading,
    this.errorMessage,
    this.isDirectNavigation = false, // Default to false
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
    required this.saloonName,
    required this.saloonAddress,
    required this.saloonDomain,
    required this.isSaloonNameValid,
    required this.isSaloonAddressValid,
    required this.isSaloonDomainValid,
    required this.description,
    required this.openHour,
    required this.closingHour,
    required this.uploadedImages,
    required this.timeOptions,
  });
}

class SaloonRegistrationSuccess extends SaloonRegistrationState {
  final String successMessage;

  SaloonRegistrationSuccess(SaloonRegistrationState state,
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        );
}

class SaloonRegistrationInitial extends SaloonRegistrationState {
  const SaloonRegistrationInitial()
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
          saloonName: '',
          saloonAddress: '',
          saloonDomain: '',
          isSaloonNameValid: false,
          isSaloonAddressValid: false,
          isSaloonDomainValid: false,
          description: '',
          openHour: '',
          closingHour: '',
          uploadedImages: const [],
          timeOptions: const [
            '08:00',
            '08:30',
            '09:00',
            '09:30',
            '10:00',
            '10:30',
            '11:00',
            '11:30',
            '12:00',
            '12:30',
            '13:00',
            '13:30',
            '14:00',
            '14:30',
            '15:00',
            '15:30',
            '16:00',
            '16:30',
            '17:00',
            '17:30',
            '18:00',
            '18:30',
            '19:00',
            '19:30',
            '20:00',
            '20:30',
            '21:00',
            '21:30',
            '22:00',
            '22:30',
            '23:00',
            '23:30',
          ],
        );
}

class SaloonRegistrationLoading extends SaloonRegistrationState {
  SaloonRegistrationLoading(SaloonRegistrationState state)
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        );
}

class SaloonRegistrationError extends SaloonRegistrationState {
  SaloonRegistrationError(SaloonRegistrationState state, String errorMessage)
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        );
}

// Bloc
class SaloonRegistrationBloc
    extends Bloc<SaloonRegistrationEvent, SaloonRegistrationState> {
  final ImagePicker _picker = ImagePicker();

  SaloonRegistrationBloc() : super(const SaloonRegistrationInitial()) {
    on<UpdatePersonalInfo>(_onUpdatePersonalInfo);
    on<UpdateOpenHour>(_onUpdateOpenHour);
    on<UpdateClosingHour>(_onUpdateClosingHour);
    on<UpdateOtp>(_onUpdateOtp);
    on<UpdateSalonInfo>(_onUpdateSalonInfo);
    on<UpdateSalonProfile>(_onUpdateSalonProfile);
    on<UploadImage>(_onUploadImage);
    on<RemoveImage>(_onRemoveImage);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<SubmitOtp>(_onSubmitOtp);
    on<ResendOtp>(_onResendOtp);
    on<SubmitRegistration>(_onSubmitRegistration);
    on<SubmitSignup>(_onSubmitSignup);
    on<SubmitSalonInfo>(_onSubmitSalonInfo);
    on<SubmitSalonProfile>(_onSubmitSalonProfile);
    on<ResetRegistration>(_onResetRegistration);
  }

  void _onUpdatePersonalInfo(
      UpdatePersonalInfo event, Emitter<SaloonRegistrationState> emit) {
    final isNameValid = event.name.trim().isNotEmpty;
    final isEmailValid = _isValidEmail(event.email);
    final isPhoneValid = event.phone.trim().isNotEmpty;
    final isPasswordValid = event.password.length >= 6;

    emit(SaloonRegistrationState(
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
      saloonName: state.saloonName,
      saloonAddress: state.saloonAddress,
      saloonDomain: state.saloonDomain,
      isSaloonNameValid: state.isSaloonNameValid,
      isSaloonAddressValid: state.isSaloonAddressValid,
      isSaloonDomainValid: state.isSaloonDomainValid,
      description: state.description,
      openHour: state.openHour,
      closingHour: state.closingHour,
      uploadedImages: state.uploadedImages,
      timeOptions: state.timeOptions,
    ));
  }

  void _onUpdateOpenHour(
      UpdateOpenHour event, Emitter<SaloonRegistrationState> emit) {
    emit(SaloonRegistrationState(
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
      saloonName: state.saloonName,
      saloonAddress: state.saloonAddress,
      saloonDomain: state.saloonDomain,
      isSaloonNameValid: state.isSaloonNameValid,
      isSaloonAddressValid: state.isSaloonAddressValid,
      isSaloonDomainValid: state.isSaloonDomainValid,
      description: state.description,
      openHour: event.openHour,
      closingHour: state.closingHour,
      uploadedImages: state.uploadedImages,
      timeOptions: state.timeOptions,
    ));
  }

  void _onUpdateClosingHour(
      UpdateClosingHour event, Emitter<SaloonRegistrationState> emit) {
    emit(SaloonRegistrationState(
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
      saloonName: state.saloonName,
      saloonAddress: state.saloonAddress,
      saloonDomain: state.saloonDomain,
      isSaloonNameValid: state.isSaloonNameValid,
      isSaloonAddressValid: state.isSaloonAddressValid,
      isSaloonDomainValid: state.isSaloonDomainValid,
      description: state.description,
      openHour: state.openHour,
      closingHour: event.closingHour,
      uploadedImages: state.uploadedImages,
      timeOptions: state.timeOptions,
    ));
  }

  void _onUpdateOtp(UpdateOtp event, Emitter<SaloonRegistrationState> emit) {
    final isOtpValid = event.otp.length == 6;

    emit(SaloonRegistrationState(
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
      isOtpError: state.isOtpError,
      saloonName: state.saloonName,
      saloonAddress: state.saloonAddress,
      saloonDomain: state.saloonDomain,
      isSaloonNameValid: state.isSaloonNameValid,
      isSaloonAddressValid: state.isSaloonAddressValid,
      isSaloonDomainValid: state.isSaloonDomainValid,
      description: state.description,
      openHour: state.openHour,
      closingHour: state.closingHour,
      uploadedImages: state.uploadedImages,
      timeOptions: state.timeOptions,
    ));
  }

  void _onUpdateSalonInfo(
      UpdateSalonInfo event, Emitter<SaloonRegistrationState> emit) {
    final isSaloonNameValid = event.saloonName.trim().isNotEmpty;
    final isSaloonAddressValid = event.saloonAddress.trim().isNotEmpty;
    final isSaloonDomainValid = event.saloonDomain.trim().isNotEmpty;

    emit(SaloonRegistrationState(
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
      saloonName: event.saloonName,
      saloonAddress: event.saloonAddress,
      saloonDomain: event.saloonDomain,
      isSaloonNameValid: isSaloonNameValid,
      isSaloonAddressValid: isSaloonAddressValid,
      isSaloonDomainValid: isSaloonDomainValid,
      description: state.description,
      openHour: state.openHour,
      closingHour: state.closingHour,
      uploadedImages: state.uploadedImages,
      timeOptions: state.timeOptions,
    ));
  }

  void _onUpdateSalonProfile(
      UpdateSalonProfile event, Emitter<SaloonRegistrationState> emit) {
    print('🔄 BLoC: UpdateSalonProfile called');
    print('📝 Description: "${event.description}"');
    print('🕐 OpenHour: "${event.openHour}"');
    print('🕐 ClosingHour: "${event.closingHour}"');
    emit(SaloonRegistrationState(
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
      saloonName: state.saloonName,
      saloonAddress: state.saloonAddress,
      saloonDomain: state.saloonDomain,
      isSaloonNameValid: state.isSaloonNameValid,
      isSaloonAddressValid: state.isSaloonAddressValid,
      isSaloonDomainValid: state.isSaloonDomainValid,
      description: event.description,
      openHour: event.openHour,
      closingHour: event.closingHour,
      uploadedImages: state.uploadedImages,
      timeOptions: state.timeOptions,
    ));
  }

  Future<void> _onUploadImage(
      UploadImage event, Emitter<SaloonRegistrationState> emit) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: event.source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final file = File(image.path);
        final filename = image.path.split('/').last;

        print('📸 Selected image: $filename');
        print('📁 File path: ${image.path}');
        print('📏 File size: ${await file.length()} bytes');
        print('🔍 File exists: ${await file.exists()}');

        // Validate file type
        final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
        final fileExtension = filename.toLowerCase();
        final isValidImage =
            validExtensions.any((ext) => fileExtension.endsWith(ext));

        if (!isValidImage) {
          emit(SaloonRegistrationError(state,
              'Invalid file type: $filename. Only JPG, PNG, GIF, WEBP are allowed.'));
          return;
        }

        final newImages = List<File>.from(state.uploadedImages)..add(file);

        emit(SaloonRegistrationState(
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: newImages,
          timeOptions: state.timeOptions,
        ));
      }
    } catch (e) {
      emit(SaloonRegistrationError(state, 'Failed to upload image: $e'));
    }
  }

  void _onRemoveImage(
      RemoveImage event, Emitter<SaloonRegistrationState> emit) {
    final newImages = List<File>.from(state.uploadedImages);
    if (event.index < newImages.length) {
      newImages.removeAt(event.index);
    }

    emit(SaloonRegistrationState(
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
      saloonName: state.saloonName,
      saloonAddress: state.saloonAddress,
      saloonDomain: state.saloonDomain,
      isSaloonNameValid: state.isSaloonNameValid,
      isSaloonAddressValid: state.isSaloonAddressValid,
      isSaloonDomainValid: state.isSaloonDomainValid,
      description: state.description,
      openHour: state.openHour,
      closingHour: state.closingHour,
      uploadedImages: newImages,
      timeOptions: state.timeOptions,
    ));
  }

  void _onNextStep(
      NextStep event, Emitter<SaloonRegistrationState> emit) async {
    if (_canProceedToNextStep()) {
      // If moving from personal information to OTP verification, call signup API
      if (state.currentStep == 0) {
        emit(SaloonRegistrationLoading(state));

        try {
          final result = await SalonAuthService.signup(
            name: state.name,
            phoneNumber: state.phone,
            email: state.email,
            password: state.password,
          );

          if (result['success']) {
            // Signup successful, proceed to OTP verification
            final nextStep = state.currentStep + 1;
            emit(SaloonRegistrationState(
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
              saloonName: state.saloonName,
              saloonAddress: state.saloonAddress,
              saloonDomain: state.saloonDomain,
              isSaloonNameValid: state.isSaloonNameValid,
              isSaloonAddressValid: state.isSaloonAddressValid,
              isSaloonDomainValid: state.isSaloonDomainValid,
              description: state.description,
              openHour: state.openHour,
              closingHour: state.closingHour,
              uploadedImages: state.uploadedImages,
              timeOptions: state.timeOptions,
            ));
          } else {
            // Signup failed
            emit(SaloonRegistrationError(
                state, result['message'] ?? 'Signup failed'));
          }
        } catch (e) {
          emit(
              SaloonRegistrationError(state, 'Network error: ${e.toString()}'));
        }
      } else {
        // For other steps, just proceed normally
        final nextStep = state.currentStep + 1;
        emit(SaloonRegistrationState(
          currentStep: nextStep,
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        ));
      }
    }
  }

  void _onPreviousStep(
      PreviousStep event, Emitter<SaloonRegistrationState> emit) {
    if (state.currentStep > 0) {
      final previousStep = state.currentStep - 1;
      emit(SaloonRegistrationState(
        currentStep: previousStep,
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
        saloonName: state.saloonName,
        saloonAddress: state.saloonAddress,
        saloonDomain: state.saloonDomain,
        isSaloonNameValid: state.isSaloonNameValid,
        isSaloonAddressValid: state.isSaloonAddressValid,
        isSaloonDomainValid: state.isSaloonDomainValid,
        description: state.description,
        openHour: state.openHour,
        closingHour: state.closingHour,
        uploadedImages: state.uploadedImages,
        timeOptions: state.timeOptions,
      ));
    }
  }

  void _onGoToStep(GoToStep event, Emitter<SaloonRegistrationState> emit) {
    emit(SaloonRegistrationState(
      currentStep: event.step,
      isLoading: state.isLoading,
      isDirectNavigation: true, // Set flag to true for direct navigation
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
      saloonName: state.saloonName,
      saloonAddress: state.saloonAddress,
      saloonDomain: state.saloonDomain,
      isSaloonNameValid: state.isSaloonNameValid,
      isSaloonAddressValid: state.isSaloonAddressValid,
      isSaloonDomainValid: state.isSaloonDomainValid,
      description: state.description,
      openHour: state.openHour,
      closingHour: state.closingHour,
      uploadedImages: state.uploadedImages,
      timeOptions: state.timeOptions,
    ));
  }

  void _onSubmitOtp(
      SubmitOtp event, Emitter<SaloonRegistrationState> emit) async {
    emit(SaloonRegistrationLoading(state));

    print('🔄 === SUBMIT OTP EVENT ===');
    print('📧 Email: ${state.email}');
    print('🔢 OTP: ${state.otp}');

    try {
      final result = await SalonAuthService.validateOtp(
        email: state.email,
        otp: state.otp,
      );

      print('📊 OTP Validation Result: $result');

      if (result['success']) {
        // OTP validation successful, save access token and proceed to Salon Information step
        final data = result['data'] as Map<String, dynamic>?;
        print('📊 OTP Validation Data: $data');

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
          } else {
            print('⚠️ No refresh token in OTP validation response');
          }
        } else {
          print('⚠️ No data in OTP validation response');
        }

        emit(SaloonRegistrationState(
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
          isOtpValid: state.isOtpValid,
          isOtpError: false,
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        ));
      } else {
        // OTP validation failed
        emit(SaloonRegistrationError(
            state, result['message'] ?? 'OTP validation failed'));
      }
    } catch (e) {
      emit(SaloonRegistrationError(state, 'Network error: ${e.toString()}'));
    }
  }

  void _onResendOtp(
      ResendOtp event, Emitter<SaloonRegistrationState> emit) async {
    emit(SaloonRegistrationLoading(state));

    try {
      final result = await SalonAuthService.resendOtp(
        email: state.email,
      );

      if (result['success']) {
        // OTP resent successfully - emit with success message
        emit(SaloonRegistrationError(
            state, 'OTP resent successfully! Please check your email.'));

        // Clear the success message after a short delay
        await Future.delayed(const Duration(seconds: 3));
        emit(SaloonRegistrationState(
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        ));
      } else {
        // OTP resend failed
        emit(SaloonRegistrationError(
            state, result['message'] ?? 'Failed to resend OTP'));
      }
    } catch (e) {
      emit(SaloonRegistrationError(state, 'Network error: ${e.toString()}'));
    }
  }

  void _onSubmitSignup(
      SubmitSignup event, Emitter<SaloonRegistrationState> emit) async {
    emit(SaloonRegistrationLoading(state));

    try {
      final result = await SalonAuthService.signup(
        name: state.name,
        phoneNumber: state.phone,
        email: state.email,
        password: state.password,
      );

      if (result['success']) {
        // Signup successful, proceed to OTP step
        emit(SaloonRegistrationState(
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        ));
      } else {
        // Signup failed
        emit(SaloonRegistrationError(
            state, result['message'] ?? 'Signup failed'));
      }
    } catch (e) {
      emit(SaloonRegistrationError(state, 'Network error: ${e.toString()}'));
    }
  }

  void _onSubmitRegistration(
      SubmitRegistration event, Emitter<SaloonRegistrationState> emit) {
    emit(SaloonRegistrationLoading(state));
    // TODO: Implement registration submission logic
  }

  void _onSubmitSalonInfo(
      SubmitSalonInfo event, Emitter<SaloonRegistrationState> emit) async {
    emit(SaloonRegistrationLoading(state));

    print('🏢 === SUBMIT SALON INFO ===');
    print('📧 Name: ${state.saloonName}');
    print('📍 Address: ${state.saloonAddress}');
    print('🏷️ Domain: ${state.saloonDomain}');

    // Validate required fields
    if (state.saloonName.isEmpty ||
        state.saloonAddress.isEmpty ||
        state.saloonDomain.isEmpty) {
      print('❌ Missing required fields');
      emit(
          SaloonRegistrationError(state, 'Please fill in all required fields'));
      return;
    }

    try {
      print('🚀 Calling SalonAuthService.addSalonInfo...');
      // Get access token from storage
      final accessToken = await TokenStorageService.getAccessToken();
      print(
          '🔑 Retrieved Access Token: ${accessToken != null ? "Present" : "Missing"}');

      if (accessToken == null) {
        print('❌ No access token available for addSalonInfo');
        emit(SaloonRegistrationError(
            state, 'No access token available. Please login again.'));
        return;
      }

      final result = await SalonAuthService.addSalonInfo(
        name: state.saloonName,
        address: state.saloonAddress,
        domain: state.saloonDomain,
        accessToken: accessToken,
      );

      print('📊 Add Salon Info Result: $result');
      print('📊 Success: ${result['success']}');
      print('📊 Message: ${result['message']}');
      print('📊 Status Code: ${result['statusCode']}');

      if (result['success']) {
        // Salon info added successfully, proceed to Salon Profile step
        emit(SaloonRegistrationState(
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
          saloonName: state.saloonName,
          saloonAddress: state.saloonAddress,
          saloonDomain: state.saloonDomain,
          isSaloonNameValid: state.isSaloonNameValid,
          isSaloonAddressValid: state.isSaloonAddressValid,
          isSaloonDomainValid: state.isSaloonDomainValid,
          description: state.description,
          openHour: state.openHour,
          closingHour: state.closingHour,
          uploadedImages: state.uploadedImages,
          timeOptions: state.timeOptions,
        ));
      } else {
        // Salon info addition failed
        emit(SaloonRegistrationError(
            state, result['message'] ?? 'Failed to add salon information'));
      }
    } catch (e) {
      emit(SaloonRegistrationError(state, 'Network error: ${e.toString()}'));
    }
  }

  void _onSubmitSalonProfile(
      SubmitSalonProfile event, Emitter<SaloonRegistrationState> emit) async {
    emit(SaloonRegistrationLoading(state));

    print('🏢 === SUBMIT SALON PROFILE ===');
    print('🕐 Opening Hour: ${state.openHour}');
    print('🕐 Closing Hour: ${state.closingHour}');
    print('📝 Description: ${state.description}');
    print('🖼️ Images Count: ${state.uploadedImages.length}');

    // Validate image count (min 3, max 10)
    if (state.uploadedImages.length < 3) {
      emit(SaloonRegistrationError(
          state, 'Please upload at least 3 images (minimum required)'));
      return;
    }

    if (state.uploadedImages.length > 10) {
      emit(SaloonRegistrationError(state, 'Please upload maximum 10 images'));
      return;
    }

    try {
      // Convert File objects to file paths (you might need to adjust this based on your file handling)
      final List<String> picturePaths =
          state.uploadedImages.map((file) => file.path).toList();

      final result = await SalonAuthService.addSalonProfile(
        openingHour: state.openHour,
        closingHour: state.closingHour,
        description: state.description,
        pictures: picturePaths,
      );

      print('📊 Add Salon Profile Result: $result');

      if (result['success']) {
        // Salon profile added successfully. If API returns tokens, save them like login.
        try {
          final data = result['data'] as Map<String, dynamic>?;
          final accessToken = data?['access_token'] as String?;
          final refreshToken = data?['refresh_token'] as String?;
          if (accessToken != null && accessToken.isNotEmpty) {
            await TokenStorageService.saveAccessToken(accessToken);
          }
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await TokenStorageService.saveRefreshToken(refreshToken);
          }
        } catch (_) {}

        emit(SaloonRegistrationSuccess(
          state,
          successMessage: result['message'] ?? 'Account created successfully',
        ));
      } else {
        // Salon profile addition failed
        emit(SaloonRegistrationError(
            state, result['message'] ?? 'Failed to add salon profile'));
      }
    } catch (e) {
      emit(SaloonRegistrationError(state, 'Network error: ${e.toString()}'));
    }
  }

  void _onResetRegistration(
      ResetRegistration event, Emitter<SaloonRegistrationState> emit) {
    emit(const SaloonRegistrationInitial());
  }

  bool _canProceedToNextStep() {
    switch (state.currentStep) {
      case 0: // Personal Information
        return state.isNameValid &&
            state.isEmailValid &&
            state.isPhoneValid &&
            state.isPasswordValid;
      case 1: // OTP
        return state.isOtpValid;
      case 2: // Salon Information
        return true; // Allow skipping
      case 3: // Salon Profile
        return true;
      default:
        return false;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  List<String> get timeOptions => [
        '08:00',
        '08:30',
        '09:00',
        '09:30',
        '10:00',
        '10:30',
        '11:00',
        '11:30',
        '12:00',
        '12:30',
        '13:00',
        '13:30',
        '14:00',
        '14:30',
        '15:00',
        '15:30',
        '16:00',
        '16:30',
        '17:00',
        '17:30',
        '18:00',
        '18:30',
        '19:00',
        '19:30',
        '20:00',
        '20:30',
        '21:00',
        '21:30',
        '22:00',
        '22:30',
        '23:00',
        '23:30',
      ];
}
