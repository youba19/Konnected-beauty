import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

class UploadImage extends SaloonRegistrationEvent {}

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

class ResetRegistration extends SaloonRegistrationEvent {}

// States
class SaloonRegistrationState {
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;

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
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final newImages = List<File>.from(state.uploadedImages)
          ..add(File(image.path));

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

  void _onNextStep(NextStep event, Emitter<SaloonRegistrationState> emit) {
    if (_canProceedToNextStep()) {
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

  void _onSubmitOtp(SubmitOtp event, Emitter<SaloonRegistrationState> emit) {
    // Go to Salon Information (step 2) after OTP verification
    emit(SaloonRegistrationState(
      currentStep: 2,
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
  }

  void _onResendOtp(ResendOtp event, Emitter<SaloonRegistrationState> emit) {
    // TODO: Implement OTP resend logic
  }

  void _onSubmitRegistration(
      SubmitRegistration event, Emitter<SaloonRegistrationState> emit) {
    emit(SaloonRegistrationLoading(state));
    // TODO: Implement registration submission logic
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
