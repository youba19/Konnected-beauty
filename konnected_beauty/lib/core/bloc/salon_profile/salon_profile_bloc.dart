import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_profile_service.dart';

// Events
abstract class SalonProfileEvent {
  const SalonProfileEvent();
}

class LoadSalonProfile extends SalonProfileEvent {}

class UpdateSalonProfile extends SalonProfileEvent {
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? password;

  const UpdateSalonProfile({
    this.name,
    this.email,
    this.phoneNumber,
    this.password,
  });
}

// States
abstract class SalonProfileState {
  const SalonProfileState();
}

class SalonProfileInitial extends SalonProfileState {}

class SalonProfileLoading extends SalonProfileState {}

class SalonProfileLoaded extends SalonProfileState {
  final Map<String, dynamic> profileData;

  const SalonProfileLoaded({required this.profileData});
}

class SalonProfileUpdating extends SalonProfileState {}

class SalonProfileUpdated extends SalonProfileState {
  final String message;

  const SalonProfileUpdated({required this.message});
}

class SalonProfileError extends SalonProfileState {
  final String error;

  const SalonProfileError({required this.error});
}

// BLoC
class SalonProfileBloc extends Bloc<SalonProfileEvent, SalonProfileState> {
  final SalonProfileService _salonProfileService;

  SalonProfileBloc({required SalonProfileService salonProfileService})
      : _salonProfileService = salonProfileService,
        super(SalonProfileInitial()) {
    on<LoadSalonProfile>(_onLoadSalonProfile);
    on<UpdateSalonProfile>(_onUpdateSalonProfile);
  }

  Future<void> _onLoadSalonProfile(
    LoadSalonProfile event,
    Emitter<SalonProfileState> emit,
  ) async {
    try {
      emit(SalonProfileLoading());

      final result = await _salonProfileService.getSalonProfile();

      if (result['success'] == true) {
        emit(SalonProfileLoaded(profileData: result['data']));
      } else {
        emit(SalonProfileError(
            error: result['message'] ?? 'Failed to load profile'));
      }
    } catch (e) {
      emit(SalonProfileError(error: e.toString()));
    }
  }

  Future<void> _onUpdateSalonProfile(
    UpdateSalonProfile event,
    Emitter<SalonProfileState> emit,
  ) async {
    try {
      emit(SalonProfileUpdating());

      final result = await _salonProfileService.updateSalonProfile(
        name: event.name,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
      );

      if (result['success'] == true) {
        emit(SalonProfileUpdated(
          message: result['message'] ?? 'Profile updated successfully',
        ));

        // Reload profile data after successful update
        add(LoadSalonProfile());
      } else {
        emit(SalonProfileError(
            error: result['message'] ?? 'Failed to update profile'));
      }
    } catch (e) {
      emit(SalonProfileError(error: e.toString()));
    }
  }
}
