import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/api/influencer_auth_service.dart';
import '../../services/api/http_interceptor.dart';
import '../../services/storage/token_storage_service.dart';

// Events
abstract class InfluencerProfileEvent {}

class LoadInfluencerProfile extends InfluencerProfileEvent {}

class UpdateInfluencerProfile extends InfluencerProfileEvent {
  final String? name;
  final String? pseudo;
  final String? phoneNumber;
  final String? bio;
  final String? zone;
  final File? profilePictureFile;

  UpdateInfluencerProfile({
    this.name,
    this.pseudo,
    this.phoneNumber,
    this.bio,
    this.zone,
    this.profilePictureFile,
  });
}

class ValidateProfileChanges extends InfluencerProfileEvent {
  final String? name;
  final String? pseudo;
  final String? phoneNumber;
  final String? bio;
  final String? zone;
  final File? profilePictureFile;

  ValidateProfileChanges({
    this.name,
    this.pseudo,
    this.phoneNumber,
    this.bio,
    this.zone,
    this.profilePictureFile,
  });
}

class ClearProfileUpdate extends InfluencerProfileEvent {}

class RefreshInfluencerProfile extends InfluencerProfileEvent {}

class ChangePassword extends InfluencerProfileEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePassword({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}

// States
abstract class InfluencerProfileState {}

class InfluencerProfileInitial extends InfluencerProfileState {}

class InfluencerProfileLoading extends InfluencerProfileState {}

class InfluencerProfileLoaded extends InfluencerProfileState {
  final Map<String, dynamic> profileData;
  final String name;
  final String pseudo;
  final String email;
  final String phoneNumber;
  final String bio;
  final String zone;
  final String profilePicture;
  final String status;

  InfluencerProfileLoaded({
    required this.profileData,
    required this.name,
    required this.pseudo,
    required this.email,
    required this.phoneNumber,
    required this.bio,
    required this.zone,
    required this.profilePicture,
    required this.status,
  });

  InfluencerProfileLoaded copyWith({
    Map<String, dynamic>? profileData,
    String? name,
    String? pseudo,
    String? email,
    String? phoneNumber,
    String? bio,
    String? zone,
    String? profilePicture,
    String? status,
  }) {
    return InfluencerProfileLoaded(
      profileData: profileData ?? this.profileData,
      name: name ?? this.name,
      pseudo: pseudo ?? this.pseudo,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      zone: zone ?? this.zone,
      profilePicture: profilePicture ?? this.profilePicture,
      status: status ?? this.status,
    );
  }
}

class InfluencerProfileValidating extends InfluencerProfileState {
  final InfluencerProfileLoaded currentProfile;
  final Map<String, String> validationErrors;

  InfluencerProfileValidating({
    required this.currentProfile,
    required this.validationErrors,
  });
}

class InfluencerProfileUpdating extends InfluencerProfileState {
  final InfluencerProfileLoaded currentProfile;
  final bool hasImageUpload;

  InfluencerProfileUpdating({
    required this.currentProfile,
    required this.hasImageUpload,
  });
}

class InfluencerProfileUpdated extends InfluencerProfileState {
  final InfluencerProfileLoaded updatedProfile;
  final String message;
  final bool hasImageChanged;

  InfluencerProfileUpdated({
    required this.updatedProfile,
    required this.message,
    required this.hasImageChanged,
  });
}

class InfluencerProfileError extends InfluencerProfileState {
  final String error;
  final String? details;
  final InfluencerProfileLoaded? lastKnownProfile;

  InfluencerProfileError({
    required this.error,
    this.details,
    this.lastKnownProfile,
  });
}

class PasswordChanging extends InfluencerProfileState {}

class PasswordChanged extends InfluencerProfileState {
  final String message;

  PasswordChanged({required this.message});
}

class PasswordChangeError extends InfluencerProfileState {
  final String error;
  final String? details;

  PasswordChangeError({
    required this.error,
    this.details,
  });
}

// BLoC
class InfluencerProfileBloc
    extends Bloc<InfluencerProfileEvent, InfluencerProfileState> {
  InfluencerProfileBloc() : super(InfluencerProfileInitial()) {
    on<LoadInfluencerProfile>(_onLoadInfluencerProfile);
    on<ValidateProfileChanges>(_onValidateProfileChanges);
    on<UpdateInfluencerProfile>(_onUpdateInfluencerProfile);
    on<ClearProfileUpdate>(_onClearProfileUpdate);
    on<RefreshInfluencerProfile>(_onRefreshInfluencerProfile);
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onValidateProfileChanges(
    ValidateProfileChanges event,
    Emitter<InfluencerProfileState> emit,
  ) async {
    if (state is InfluencerProfileLoaded) {
      final currentState = state as InfluencerProfileLoaded;
      final validationErrors = <String, String>{};

      // Validate pseudo
      if (event.pseudo != null && event.pseudo!.trim().isEmpty) {
        validationErrors['pseudo'] = 'Pseudo cannot be empty';
      }

      // Validate bio length
      if (event.bio != null && event.bio!.length > 500) {
        validationErrors['bio'] = 'Bio cannot exceed 500 characters';
      }

      // Validate zone
      if (event.zone != null && event.zone!.trim().isEmpty) {
        validationErrors['zone'] = 'Zone cannot be empty';
      }

      // Validate image file
      if (event.profilePictureFile != null) {
        final fileSize = await event.profilePictureFile!.length();
        if (fileSize > 5 * 1024 * 1024) {
          // 5MB limit
          validationErrors['profilePicture'] = 'Image size cannot exceed 5MB';
        }
      }

      if (validationErrors.isEmpty) {
        // No validation errors, proceed with update directly
        await _performProfileUpdateDirectly(event, emit, currentState);
      } else {
        // Show validation errors
        emit(InfluencerProfileValidating(
          currentProfile: currentState,
          validationErrors: validationErrors,
        ));
      }
    }
  }

  Future<void> _performProfileUpdateDirectly(
    ValidateProfileChanges event,
    Emitter<InfluencerProfileState> emit,
    InfluencerProfileLoaded currentState,
  ) async {
    try {
      emit(InfluencerProfileUpdating(
        currentProfile: currentState,
        hasImageUpload: event.profilePictureFile != null,
      ));

      // Perform the actual profile update
      final success = await _performProfileUpdate(
          UpdateInfluencerProfile(
            pseudo: event.pseudo,
            bio: event.bio,
            zone: event.zone,
            profilePictureFile: event.profilePictureFile,
          ),
          currentProfilePicture: currentState.profilePicture);

      if (success) {
        // Refresh profile data after successful update
        await _refreshProfileAfterUpdate(
          emit,
          currentState,
          event.profilePictureFile != null,
        );
      } else {
        // If update failed, revert to previous state
        emit(currentState);
      }
    } catch (e) {
      emit(InfluencerProfileError(
        error: 'Failed to update profile',
        details: e.toString(),
        lastKnownProfile: currentState,
      ));
    }
  }

  Future<void> _onLoadInfluencerProfile(
    LoadInfluencerProfile event,
    Emitter<InfluencerProfileState> emit,
  ) async {
    try {
      emit(InfluencerProfileLoading());

      final result = await InfluencerAuthService.getProfile();

      if (result['success'] == true && result['data'] != null) {
        final profileData = result['data'];

        final loadedProfile = InfluencerProfileLoaded(
          profileData: profileData,
          name: profileData['name'] ?? '',
          pseudo: profileData['profile']?['pseudo'] ?? '',
          email: profileData['email'] ?? '',
          phoneNumber: profileData['phoneNumber'] ?? '',
          bio: profileData['profile']?['bio'] ?? '',
          zone: profileData['profile']?['zone'] ?? 'Paris',
          profilePicture: profileData['profile']?['profilePicture'] ?? '',
          status: profileData['status'] ?? 'inactive',
        );

        emit(loadedProfile);
      } else {
        emit(InfluencerProfileError(
          error: result['message'] ?? 'Failed to load profile data',
        ));
      }
    } catch (e) {
      emit(InfluencerProfileError(
        error: 'Network error',
        details: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateInfluencerProfile(
    UpdateInfluencerProfile event,
    Emitter<InfluencerProfileState> emit,
  ) async {
    try {
      if (state is InfluencerProfileLoaded) {
        final currentState = state as InfluencerProfileLoaded;

        emit(InfluencerProfileUpdating(
          currentProfile: currentState,
          hasImageUpload: event.profilePictureFile != null,
        ));

        // Perform the actual profile update
        final success = await _performProfileUpdate(event,
            currentProfilePicture: currentState.profilePicture);

        if (success) {
          // Refresh profile data after successful update
          await _refreshProfileAfterUpdate(
              emit, currentState, event.profilePictureFile != null);
        } else {
          // If update failed, emit error state instead of reverting
          emit(InfluencerProfileError(
            error: 'Failed to update profile',
            details:
                'The API request failed. Please check that all required fields are filled correctly.',
            lastKnownProfile: currentState,
          ));
        }
      }
    } catch (e) {
      emit(InfluencerProfileError(
        error: 'Failed to update profile',
        details: e.toString(),
      ));
    }
  }

  Future<bool> _performProfileUpdate(UpdateInfluencerProfile event,
      {String? currentProfilePicture}) async {
    try {
      bool userUpdateSuccess = true;
      bool profileUpdateSuccess = true;

      // STEP 1: Update user information (name, phoneNumber)
      final userRequestBody = <String, dynamic>{};
      if (event.name != null && event.name!.isNotEmpty) {
        userRequestBody['name'] = event.name!;
      }
      if (event.phoneNumber != null && event.phoneNumber!.isNotEmpty) {
        userRequestBody['phoneNumber'] = event.phoneNumber!;
      }

      if (userRequestBody.isNotEmpty) {
        print('🔍 === USER UPDATE REQUEST ===');
        print('🔍 Request body: ${jsonEncode(userRequestBody)}');
        print('🔍 Request URL: ${InfluencerAuthService.baseUrl}/influencer');

        final userResponse = await HttpInterceptor.interceptRequest(() async {
          final accessToken = await TokenStorageService.getAccessToken();
          return await http.patch(
            Uri.parse('${InfluencerAuthService.baseUrl}/influencer'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(userRequestBody),
          );
        });

        if (userResponse.statusCode == 200 || userResponse.statusCode == 201) {
          print('✅ User information updated successfully');
        } else {
          print('❌ User update failed with status: ${userResponse.statusCode}');
          print('📄 Response body: ${userResponse.body}');
          userUpdateSuccess = false;
        }
      }

      // STEP 2: Update profile information (pseudo, bio, zone, profilePicture)
      final hasProfileChanges =
          (event.pseudo != null && event.pseudo!.isNotEmpty) ||
              (event.bio != null && event.bio!.isNotEmpty) ||
              (event.zone != null && event.zone!.isNotEmpty) ||
              event.profilePictureFile != null;

      if (hasProfileChanges) {
        if (event.profilePictureFile != null) {
          // Use multipart request for file upload
          final request = http.MultipartRequest(
            'PATCH',
            Uri.parse(
                '${InfluencerAuthService.baseUrl}/influencer/update-influencer-profile'),
          );

          // Add authorization header
          final accessToken = await TokenStorageService.getAccessToken();
          if (accessToken != null) {
            request.headers['Authorization'] = 'Bearer $accessToken';
          }

          // Add profile fields
          if (event.pseudo != null && event.pseudo!.isNotEmpty) {
            request.fields['pseudo'] = event.pseudo!;
          }
          if (event.bio != null && event.bio!.isNotEmpty) {
            request.fields['bio'] = event.bio!;
          }
          if (event.zone != null && event.zone!.isNotEmpty) {
            request.fields['zone'] = event.zone!;
          }

          // Note: We don't send profilePicture as a field because the backend expects it as a file
          // When uploading a new image, the backend will replace the existing one
          print(
              '🔍 === DEBUG: File upload - profile picture will be replaced ===');

          // Detect file type and set proper content type
          final fileName = event.profilePictureFile!.path.split('/').last;
          final fileExtension = fileName.split('.').last.toLowerCase();

          String contentType;
          switch (fileExtension) {
            case 'jpg':
            case 'jpeg':
              contentType = 'image/jpeg';
              break;
            case 'png':
              contentType = 'image/png';
              break;
            case 'gif':
              contentType = 'image/gif';
              break;
            case 'webp':
              contentType = 'image/webp';
              break;
            default:
              contentType = 'image/jpeg';
          }

          // Add the image file with proper content type
          final file = await http.MultipartFile.fromPath(
            'profilePicture',
            event.profilePictureFile!.path,
            contentType: MediaType.parse(contentType),
          );
          request.files.add(file);

          print('🔍 === PROFILE UPDATE REQUEST (WITH FILE) ===');
          print('🔍 Fields being sent: ${request.fields}');
          print('🔍 Files being sent: ${request.files.length}');
          print('🔍 Request URL: ${request.url}');

          // Send the multipart request through HTTP interceptor
          final profileResponse =
              await HttpInterceptor.interceptRequest(() async {
            final streamedResponse = await request.send();
            return await http.Response.fromStream(streamedResponse);
          });

          if (profileResponse.statusCode == 200 ||
              profileResponse.statusCode == 201) {
            print('✅ Profile information updated successfully');
          } else {
            print(
                '❌ Profile update failed with status: ${profileResponse.statusCode}');
            print('📄 Response body: ${profileResponse.body}');
            profileUpdateSuccess = false;
          }
        } else {
          // For text-only updates, we need to re-upload the existing profile picture
          // because the backend doesn't preserve it automatically
          if (currentProfilePicture != null &&
              currentProfilePicture.isNotEmpty) {
            print('🔍 === DEBUG: Re-uploading existing profile picture ===');
            print('🔍 Profile picture URL: $currentProfilePicture');

            try {
              // Download the existing profile picture
              final imageResponse =
                  await http.get(Uri.parse(currentProfilePicture));
              if (imageResponse.statusCode == 200) {
                // Create a temporary file from the downloaded image
                final tempDir = await getTemporaryDirectory();
                final tempFile =
                    File('${tempDir.path}/temp_profile_picture.jpg');
                await tempFile.writeAsBytes(imageResponse.bodyBytes);

                // Now use multipart request with the existing image
                final request = http.MultipartRequest(
                  'PATCH',
                  Uri.parse(
                      '${InfluencerAuthService.baseUrl}/influencer/update-influencer-profile'),
                );

                // Add authorization header
                final accessToken = await TokenStorageService.getAccessToken();
                if (accessToken != null) {
                  request.headers['Authorization'] = 'Bearer $accessToken';
                }

                // Add profile fields
                if (event.pseudo != null && event.pseudo!.isNotEmpty) {
                  request.fields['pseudo'] = event.pseudo!;
                }
                if (event.bio != null && event.bio!.isNotEmpty) {
                  request.fields['bio'] = event.bio!;
                }
                if (event.zone != null && event.zone!.isNotEmpty) {
                  request.fields['zone'] = event.zone!;
                }

                // Add the existing profile picture as a file
                final file = await http.MultipartFile.fromPath(
                  'profilePicture',
                  tempFile.path,
                  contentType: MediaType.parse('image/jpeg'),
                );
                request.files.add(file);

                print(
                    '🔍 === PROFILE UPDATE REQUEST (TEXT ONLY - WITH EXISTING IMAGE) ===');
                print('🔍 Fields being sent: ${request.fields}');
                print('🔍 Files being sent: ${request.files.length}');
                print('🔍 Request URL: ${request.url}');

                // Send the multipart request through HTTP interceptor
                final profileResponse =
                    await HttpInterceptor.interceptRequest(() async {
                  final streamedResponse = await request.send();
                  return await http.Response.fromStream(streamedResponse);
                });

                if (profileResponse.statusCode == 200 ||
                    profileResponse.statusCode == 201) {
                  print(
                      '✅ Profile information updated successfully with existing image preserved');
                } else {
                  print(
                      '❌ Profile update failed with status: ${profileResponse.statusCode}');
                  print('📄 Response body: ${profileResponse.body}');
                  profileUpdateSuccess = false;
                }

                // Clean up temporary file
                await tempFile.delete();
              } else {
                print(
                    '⚠️ Failed to download existing profile picture, proceeding without it');
                // Fall back to the original approach
                await _performTextOnlyUpdate(event, currentProfilePicture);
              }
            } catch (e) {
              print(
                  '⚠️ Error downloading existing profile picture: $e, proceeding without it');
              // Fall back to the original approach
              await _performTextOnlyUpdate(event, currentProfilePicture);
            }
          } else {
            print('🔍 === DEBUG: No existing profile picture to preserve ===');
            // No existing profile picture, use simple text update
            await _performTextOnlyUpdate(event, currentProfilePicture);
          }
        }
      }

      // Return true only if both updates succeeded (or if no updates were needed)
      final overallSuccess = userUpdateSuccess && profileUpdateSuccess;
      if (overallSuccess) {
        print('🎉 All updates completed successfully');
      } else {
        print(
            '⚠️ Some updates failed - User: $userUpdateSuccess, Profile: $profileUpdateSuccess');
      }

      return overallSuccess;
    } catch (e) {
      print('❌ Exception while updating profile: $e');
      return false;
    }
  }

  Future<void> _refreshProfileAfterUpdate(
    Emitter<InfluencerProfileState> emit,
    InfluencerProfileLoaded currentState,
    bool hasImageChanged,
  ) async {
    try {
      final result = await InfluencerAuthService.getProfile();

      if (result['success'] == true && result['data'] != null) {
        final profileData = result['data'];

        final updatedProfile = InfluencerProfileLoaded(
          profileData: profileData,
          name: profileData['name'] ?? '',
          pseudo: profileData['profile']?['pseudo'] ?? '',
          email: profileData['email'] ?? '',
          phoneNumber: profileData['phoneNumber'] ?? '',
          bio: profileData['profile']?['bio'] ?? '',
          zone: profileData['profile']?['zone'] ?? 'Paris',
          profilePicture: profileData['profile']?['profilePicture'] ??
              currentState.profilePicture,
          status: profileData['status'] ?? 'inactive',
        );

        // Emit the updated state for immediate feedback
        emit(InfluencerProfileUpdated(
          updatedProfile: updatedProfile,
          message: 'Profile updated successfully',
          hasImageChanged: hasImageChanged,
        ));
      } else {
        throw Exception('Failed to refresh profile data');
      }
    } catch (e) {
      emit(InfluencerProfileError(
        error: 'Failed to refresh profile data',
        details: e.toString(),
      ));
    }
  }

  void _onClearProfileUpdate(
    ClearProfileUpdate event,
    Emitter<InfluencerProfileState> emit,
  ) {
    if (state is InfluencerProfileUpdated) {
      final updatedState = state as InfluencerProfileUpdated;
      // Transition to the loaded state with the updated profile data
      emit(updatedState.updatedProfile);
    }
  }

  Future<void> _onRefreshInfluencerProfile(
    RefreshInfluencerProfile event,
    Emitter<InfluencerProfileState> emit,
  ) async {
    add(LoadInfluencerProfile());
  }

  Future<void> _onChangePassword(
    ChangePassword event,
    Emitter<InfluencerProfileState> emit,
  ) async {
    try {
      emit(PasswordChanging());

      final result = await InfluencerAuthService.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      if (result['success'] == true) {
        emit(PasswordChanged(
          message: result['message'] ?? 'Password changed successfully',
        ));

        // Refresh profile data after successful password change
        // This ensures the UI shows the correct profile information
        await _refreshProfileAfterPasswordChange(emit);
      } else {
        emit(PasswordChangeError(
          error: result['message'] ?? 'Failed to change password',
          details: result['details'],
        ));
      }
    } catch (e) {
      emit(PasswordChangeError(
        error: 'Network error',
        details: e.toString(),
      ));
    }
  }

  Future<void> _refreshProfileAfterPasswordChange(
    Emitter<InfluencerProfileState> emit,
  ) async {
    try {
      // Load fresh profile data from API
      final result = await InfluencerAuthService.getProfile();

      if (result['success'] == true && result['data'] != null) {
        final profileData = result['data'];

        final refreshedProfile = InfluencerProfileLoaded(
          profileData: profileData,
          name: profileData['name'] ?? '',
          pseudo: profileData['profile']?['pseudo'] ?? '',
          email: profileData['email'] ?? '',
          phoneNumber: profileData['phoneNumber'] ?? '',
          bio: profileData['profile']?['bio'] ?? '',
          zone: profileData['profile']?['zone'] ?? 'Paris',
          profilePicture: profileData['profile']?['profilePicture'] ?? '',
          status: profileData['status'] ?? 'inactive',
        );

        // Emit the refreshed profile data
        // This ensures the UI shows the correct profile information
        emit(refreshedProfile);
      } else {
        // If refresh fails, we don't want to break the password change success
        // The UI will still show the success message and navigate back
      }
    } catch (e) {
      // If refresh fails, we don't want to break the password change success
      // The UI will still show the success message and navigate back
    }
  }

  // Helper method for text-only profile updates
  Future<void> _performTextOnlyUpdate(
    UpdateInfluencerProfile event,
    String? currentProfilePicture,
  ) async {
    // Simple multipart request without profile picture
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(
          '${InfluencerAuthService.baseUrl}/influencer/update-influencer-profile'),
    );

    // Add authorization header
    final accessToken = await TokenStorageService.getAccessToken();
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Add profile fields
    if (event.pseudo != null && event.pseudo!.isNotEmpty) {
      request.fields['pseudo'] = event.pseudo!;
    }
    if (event.bio != null && event.bio!.isNotEmpty) {
      request.fields['bio'] = event.bio!;
    }
    if (event.zone != null && event.zone!.isNotEmpty) {
      request.fields['zone'] = event.zone!;
    }

    print('🔍 === PROFILE UPDATE REQUEST (TEXT ONLY - SIMPLE) ===');
    print('🔍 Fields being sent: ${request.fields}');
    print('🔍 Files being sent: ${request.files.length}');
    print('🔍 Request URL: ${request.url}');

    // Send the multipart request through HTTP interceptor
    final profileResponse = await HttpInterceptor.interceptRequest(() async {
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    });

    if (profileResponse.statusCode == 200 ||
        profileResponse.statusCode == 201) {
      print('✅ Profile information updated successfully (simple update)');
    } else {
      print(
          '❌ Profile update failed with status: ${profileResponse.statusCode}');
      print('📄 Response body: ${profileResponse.body}');
      // Note: We don't set profileUpdateSuccess to false here as this is a fallback
    }
  }
}
