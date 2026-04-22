import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_info_service.dart';

// Events
abstract class SalonInfoEvent {
  const SalonInfoEvent();
}

class LoadSalonInfo extends SalonInfoEvent {}

class LoadSalonProfile extends SalonInfoEvent {}

class LoadAllSalonData extends SalonInfoEvent {}

class UpdateSalonInfo extends SalonInfoEvent {
  final String? name;
  final String? address;
  final String? domain;
  final String? website;

  const UpdateSalonInfo({
    this.name,
    this.address,
    this.domain,
    this.website,
  });
}

class UpdateSalonProfile extends SalonInfoEvent {
  final String? openingHour;
  final String? closingHour;
  final String? description;
  final List<File>? pictureFiles;

  const UpdateSalonProfile({
    this.openingHour,
    this.closingHour,
    this.description,
    this.pictureFiles,
  });
}

// States
abstract class SalonInfoState {
  const SalonInfoState();
}

class SalonInfoInitial extends SalonInfoState {}

class SalonInfoLoading extends SalonInfoState {}

class SalonInfoLoaded extends SalonInfoState {
  final Map<String, dynamic> salonInfo;
  final Map<String, dynamic>? salonProfile;

  const SalonInfoLoaded({
    required this.salonInfo,
    this.salonProfile,
  });
}

class SalonInfoError extends SalonInfoState {
  final String error;

  const SalonInfoError({required this.error});
}

class SalonInfoUpdating extends SalonInfoState {}

class SalonInfoUpdated extends SalonInfoState {
  final String message;

  const SalonInfoUpdated({required this.message});
}

class SalonProfileUpdating extends SalonInfoState {}

class SalonProfileUpdated extends SalonInfoState {
  final String message;

  const SalonProfileUpdated({required this.message});
}

// BLoC
class SalonInfoBloc extends Bloc<SalonInfoEvent, SalonInfoState> {
  final SalonInfoService _salonInfoService;

  SalonInfoBloc({required SalonInfoService salonInfoService})
      : _salonInfoService = salonInfoService,
        super(SalonInfoInitial()) {
    on<LoadSalonInfo>(_onLoadSalonInfo);
    on<LoadSalonProfile>(_onLoadSalonProfile);
    on<LoadAllSalonData>(_onLoadAllSalonData);
    on<UpdateSalonInfo>(_onUpdateSalonInfo);
    on<UpdateSalonProfile>(_onUpdateSalonProfile);
  }

  Future<void> _onLoadSalonInfo(
    LoadSalonInfo event,
    Emitter<SalonInfoState> emit,
  ) async {
    try {
      emit(SalonInfoLoading());

      final result = await _salonInfoService.getSalonInfo();

      if (result['success'] == true) {
        final data = result['data'] ?? <String, dynamic>{};

        // Log the loaded data
        print('📱 === BLOC: SALON INFO LOADED ===');
        print('🏷️  Name: ${data['name'] ?? 'N/A'}');
        print('📍 Address: ${data['address'] ?? 'N/A'}');
        print('🏢 Domain: ${data['domain'] ?? 'N/A'}');
        print('🌐 Website: ${data['website'] ?? 'N/A'}');
        print('📱 === END BLOC LOG ===');

        emit(SalonInfoLoaded(
          salonInfo: data,
          salonProfile: null,
        ));
      } else {
        print('❌ Failed to load salon info: ${result['message']}');
        emit(SalonInfoError(
            error: result['message'] ?? 'Failed to load salon info'));
      }
    } catch (e) {
      print('❌ Error loading salon info: $e');
      emit(SalonInfoError(error: e.toString()));
    }
  }

  Future<void> _onLoadSalonProfile(
    LoadSalonProfile event,
    Emitter<SalonInfoState> emit,
  ) async {
    try {
      emit(SalonInfoLoading());

      final result = await _salonInfoService.getSalonProfile();

      if (result['success'] == true) {
        // If we already have salon info, keep it
        final data = result['data'] ?? <String, dynamic>{};
        if (state is SalonInfoLoaded) {
          final currentState = state as SalonInfoLoaded;
          emit(SalonInfoLoaded(
            salonInfo: currentState.salonInfo,
            salonProfile: data,
          ));
        } else {
          emit(SalonInfoLoaded(
            salonInfo: <String, dynamic>{},
            salonProfile: data,
          ));
        }
      } else {
        emit(SalonInfoError(
            error: result['message'] ?? 'Failed to load salon profile'));
      }
    } catch (e) {
      emit(SalonInfoError(error: e.toString()));
    }
  }

  Future<void> _onLoadAllSalonData(
    LoadAllSalonData event,
    Emitter<SalonInfoState> emit,
  ) async {
    try {
      emit(SalonInfoLoading());

      // Load both salon info and profile
      final infoResult = await _salonInfoService.getSalonInfo();
      final profileResult = await _salonInfoService.getSalonProfile();

      // Check if both requests were successful
      if (infoResult['success'] == true && profileResult['success'] == true) {
        // Handle case where salon info might be null (new salon)
        final salonInfo = infoResult['data'] ?? <String, dynamic>{};
        final salonProfile = profileResult['data'];

        emit(SalonInfoLoaded(
          salonInfo: salonInfo,
          salonProfile: salonProfile,
        ));
      } else {
        // If either request failed, show the error
        final errorMessage = infoResult['success'] == false
            ? infoResult['message']
            : profileResult['message'];
        emit(
            SalonInfoError(error: errorMessage ?? 'Failed to load salon data'));
      }
    } catch (e) {
      emit(SalonInfoError(error: e.toString()));
    }
  }

  Future<void> _onUpdateSalonInfo(
    UpdateSalonInfo event,
    Emitter<SalonInfoState> emit,
  ) async {
    try {
      emit(SalonInfoUpdating());

      final result = await _salonInfoService.updateSalonInfo(
        name: event.name,
        address: event.address,
        domain: event.domain,
        website: event.website,
      );

      if (result['success'] == true) {
        emit(SalonInfoUpdated(message: result['message']));
      } else {
        emit(SalonInfoError(
            error: result['message'] ?? 'Failed to update salon info'));
      }

      // Always reload data after any update attempt to see current server state
      print('🔄 🔄 Reloading salon data after salon info update attempt');
      add(LoadAllSalonData());
    } catch (e) {
      emit(SalonInfoError(error: e.toString()));
    }
  }

  Future<void> _onUpdateSalonProfile(
    UpdateSalonProfile event,
    Emitter<SalonInfoState> emit,
  ) async {
    try {
      print('🔄 === BLOC: UPDATING SALON PROFILE ===');
      print('🔄 Event received:');
      print('🔄 - openingHour: ${event.openingHour}');
      print('🔄 - closingHour: ${event.closingHour}');
      print('🔄 - description: ${event.description}');
      print('🔄 - pictureFiles count: ${event.pictureFiles?.length ?? 0}');
      print(
          '🔄 - pictureFiles: ${event.pictureFiles?.map((f) => f.path).toList()}');

      emit(SalonProfileUpdating());

      final result = await _salonInfoService.updateSalonProfile(
        openingHour: event.openingHour,
        closingHour: event.closingHour,
        description: event.description,
        pictureFiles: event.pictureFiles,
      );

      print('🔄 Service result: $result');

      if (result['success'] == true) {
        print('🔄 ✅ Profile update successful, emitting SalonProfileUpdated');
        emit(SalonProfileUpdated(message: result['message']));
      } else {
        print('🔄 ❌ Profile update failed: ${result['message']}');
        emit(SalonInfoError(
            error: result['message'] ?? 'Failed to update salon profile'));
      }

      // Always reload data after any update attempt to see current server state
      print('🔄 🔄 Reloading salon data after update attempt');

      // Add delay for server to process uploaded images
      if (event.pictureFiles != null && event.pictureFiles!.isNotEmpty) {
        print('🔄 ⏰ Adding delay for image processing...');

        // Try multiple times with increasing delays to ensure images are processed
        for (int attempt = 1; attempt <= 3; attempt++) {
          print('🔄 ⏰ Attempt $attempt: Waiting ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));

          print('🔄 🔍 Checking if images are processed (attempt $attempt)...');
          final checkResult = await _salonInfoService.getSalonProfile();

          if (checkResult['success'] == true) {
            final pictures = checkResult['data']?['pictures'] ?? [];
            print(
                '🔄 📸 Found ${pictures.length} pictures on attempt $attempt');

            if (pictures.isNotEmpty) {
              print('🔄 ✅ Images processed successfully! Breaking loop.');
              break;
            }
          }

          if (attempt < 3) {
            print('🔄 ⏰ Images not ready yet, trying again...');
          } else {
            print('🔄 ⚠️ Images still not loaded after 3 attempts');
          }
        }

        print('🔄 ⏰ Delay complete, fetching final data...');
      }

      add(LoadAllSalonData());
    } catch (e) {
      print('🔄 ❌ Error in _onUpdateSalonProfile: $e');
      print('🔄 ❌ Stack trace: ${StackTrace.current}');
      emit(SalonInfoError(error: e.toString()));
    }
  }

  // Upload images and get server URLs
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    try {
      print('📤 === BLOC: UPLOADING IMAGES ===');
      print('📤 Images to upload: ${imageFiles.length}');

      final uploadedUrls = await _salonInfoService.uploadImages(imageFiles);

      print('📤 === BLOC: UPLOAD COMPLETE ===');
      print(
          '📤 Successfully uploaded: ${uploadedUrls.length}/${imageFiles.length} images');

      return uploadedUrls;
    } catch (e) {
      print('📤 ❌ Error in BLOC uploadImages: $e');
      return [];
    }
  }
}
