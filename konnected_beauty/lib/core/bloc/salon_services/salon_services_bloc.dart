import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_services_service.dart';
import '../../services/storage/token_storage_service.dart';

// Events
abstract class SalonServicesEvent {}

class LoadSalonServices extends SalonServicesEvent {}

class RefreshSalonServices extends SalonServicesEvent {}

class FilterSalonServices extends SalonServicesEvent {
  final int? minPrice;
  final int? maxPrice;

  FilterSalonServices({
    this.minPrice,
    this.maxPrice,
  });
}

class SearchSalonServices extends SalonServicesEvent {
  final String searchQuery;

  SearchSalonServices({
    required this.searchQuery,
  });
}

class CreateSalonService extends SalonServicesEvent {
  final String name;
  final int price;
  final String description;

  CreateSalonService({
    required this.name,
    required this.price,
    required this.description,
  });
}

class UpdateSalonService extends SalonServicesEvent {
  final String serviceId;
  final String? name;
  final int? price;
  final String? description;

  UpdateSalonService({
    required this.serviceId,
    this.name,
    this.price,
    this.description,
  });
}

class DeleteSalonService extends SalonServicesEvent {
  final String serviceId;

  DeleteSalonService({
    required this.serviceId,
  });
}

// States
abstract class SalonServicesState {}

class SalonServicesInitial extends SalonServicesState {}

class SalonServicesLoading extends SalonServicesState {}

class SalonServicesLoaded extends SalonServicesState {
  final List<dynamic> services;
  final String message;

  SalonServicesLoaded({
    required this.services,
    required this.message,
  });
}

class SalonServicesError extends SalonServicesState {
  final String message;
  final String? error;

  SalonServicesError({
    required this.message,
    this.error,
  });
}

class SalonServiceCreating extends SalonServicesState {}

class SalonServiceCreated extends SalonServicesState {
  final String message;
  final Map<String, dynamic> serviceData;

  SalonServiceCreated({
    required this.message,
    required this.serviceData,
  });
}

class SalonServiceUpdating extends SalonServicesState {}

class SalonServiceUpdated extends SalonServicesState {
  final String message;
  final Map<String, dynamic> serviceData;

  SalonServiceUpdated({
    required this.message,
    required this.serviceData,
  });
}

class SalonServiceDeleting extends SalonServicesState {}

class SalonServiceDeleted extends SalonServicesState {
  final String message;
  final String serviceId;

  SalonServiceDeleted({
    required this.message,
    required this.serviceId,
  });
}

// BLoC
class SalonServicesBloc extends Bloc<SalonServicesEvent, SalonServicesState> {
  SalonServicesBloc() : super(SalonServicesInitial()) {
    on<LoadSalonServices>(_onLoadSalonServices);
    on<RefreshSalonServices>(_onRefreshSalonServices);
    on<FilterSalonServices>(_onFilterSalonServices);
    on<SearchSalonServices>(_onSearchSalonServices);
    on<CreateSalonService>(_onCreateSalonService);
    on<UpdateSalonService>(_onUpdateSalonService);
    on<DeleteSalonService>(_onDeleteSalonService);
  }

  Future<void> _onLoadSalonServices(
    LoadSalonServices event,
    Emitter<SalonServicesState> emit,
  ) async {
    emit(SalonServicesLoading());

    try {
      final result = await SalonServicesService.getServices();

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;

        emit(SalonServicesLoaded(
          services: services,
          message: message,
        ));
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult = await SalonServicesService.refreshToken(
                refreshToken: refreshToken);
            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved');
              }
              print('🔄 Token refreshed, retrying service load...');

              // Retry the service load
              final retryResult = await SalonServicesService.getServices();

              if (retryResult['success']) {
                final services = retryResult['data'] as List<dynamic>;
                final message = retryResult['message'] as String;

                emit(SalonServicesLoaded(
                  services: services,
                  message: message,
                ));
                return;
              }
            }
          }
        }

        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to load services',
          error: result['error'],
        ));
      }
    } catch (e) {
      emit(SalonServicesError(
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshSalonServices(
    RefreshSalonServices event,
    Emitter<SalonServicesState> emit,
  ) async {
    // Same logic as load, but could be optimized for refresh
    emit(SalonServicesLoading());

    try {
      final result = await SalonServicesService.getServices();

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;

        emit(SalonServicesLoaded(
          services: services,
          message: message,
        ));
      } else {
        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to load services',
          error: result['error'],
        ));
      }
    } catch (e) {
      emit(SalonServicesError(
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }

  Future<void> _onFilterSalonServices(
    FilterSalonServices event,
    Emitter<SalonServicesState> emit,
  ) async {
    emit(SalonServicesLoading());

    try {
      final result = await SalonServicesService.getServices(
        minPrice: event.minPrice?.toDouble(),
        maxPrice: event.maxPrice?.toDouble(),
      );

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;

        emit(SalonServicesLoaded(
          services: services,
          message: message,
        ));
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected during filter, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult = await SalonServicesService.refreshToken(
                refreshToken: refreshToken);
            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved');
              }
              print('🔄 Token refreshed, retrying filter...');

              // Retry the filter
              final retryResult = await SalonServicesService.getServices(
                minPrice: event.minPrice?.toDouble(),
                maxPrice: event.maxPrice?.toDouble(),
              );

              if (retryResult['success']) {
                final services = retryResult['data'] as List<dynamic>;
                final message = retryResult['message'] as String;

                emit(SalonServicesLoaded(
                  services: services,
                  message: message,
                ));
                return;
              }
            }
          }
        }

        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to filter services',
          error: result['error'],
        ));
      }
    } catch (e) {
      emit(SalonServicesError(
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSearchSalonServices(
    SearchSalonServices event,
    Emitter<SalonServicesState> emit,
  ) async {
    print('🔍 === BLOC: SEARCH SALON SERVICES ===');
    print('📝 Search Query: "${event.searchQuery}"');

    emit(SalonServicesLoading());

    try {
      final result = await SalonServicesService.getServices(
        search: event.searchQuery,
      );

      print('🔍 === SEARCH RESULT ===');
      print('✅ Success: ${result['success']}');
      print('📊 Services Count: ${result['data']?.length ?? 0}');

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;

        emit(SalonServicesLoaded(
          services: services,
          message: message,
        ));
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected during search, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult = await SalonServicesService.refreshToken(
                refreshToken: refreshToken);
            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved');
              }
              print('🔄 Token refreshed, retrying search...');

              // Retry the search
              final retryResult = await SalonServicesService.getServices(
                search: event.searchQuery,
              );

              if (retryResult['success']) {
                final services = retryResult['data'] as List<dynamic>;
                final message = retryResult['message'] as String;

                emit(SalonServicesLoaded(
                  services: services,
                  message: message,
                ));
                return;
              }
            }
          }
        }

        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to search services',
          error: result['error'],
        ));
      }
    } catch (e) {
      print('❌ Search Error: $e');
      emit(SalonServicesError(
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateSalonService(
    CreateSalonService event,
    Emitter<SalonServicesState> emit,
  ) async {
    emit(SalonServiceCreating());

    try {
      final result = await SalonServicesService.createSalonService(
        name: event.name,
        price: event.price,
        description: event.description,
      );

      if (result['success']) {
        final serviceData = result['data'] as Map<String, dynamic>? ?? {};
        final message = result['message'] as String;

        emit(SalonServiceCreated(
          message: message,
          serviceData: serviceData,
        ));

        // Automatically refresh the services list after creating
        await _onLoadSalonServices(LoadSalonServices(), emit);
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult = await SalonServicesService.refreshToken(
                refreshToken: refreshToken);
            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved');
              }
              print('🔄 Token refreshed, retrying service creation...');

              // Retry the service creation
              final retryResult = await SalonServicesService.createSalonService(
                name: event.name,
                price: event.price,
                description: event.description,
              );

              if (retryResult['success']) {
                final serviceData =
                    retryResult['data'] as Map<String, dynamic>? ?? {};
                final message = retryResult['message'] as String;

                emit(SalonServiceCreated(
                  message: message,
                  serviceData: serviceData,
                ));

                // Automatically refresh the services list after creating
                await _onLoadSalonServices(LoadSalonServices(), emit);
                return;
              }
            }
          }
        }

        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to create service',
          error: result['error'],
        ));
      }
    } catch (e) {
      emit(SalonServicesError(
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateSalonService(
    UpdateSalonService event,
    Emitter<SalonServicesState> emit,
  ) async {
    emit(SalonServiceUpdating());

    try {
      final result = await SalonServicesService.updateSalonService(
        serviceId: event.serviceId,
        name: event.name,
        price: event.price,
        description: event.description,
      );

      if (result['success']) {
        final serviceData = result['data'] as Map<String, dynamic>? ?? {};
        final message = result['message'] as String;

        emit(SalonServiceUpdated(
          message: message,
          serviceData: serviceData,
        ));

        // Automatically refresh the services list after updating
        await _onLoadSalonServices(LoadSalonServices(), emit);
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult = await SalonServicesService.refreshToken(
                refreshToken: refreshToken);
            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved');
              }
              print('🔄 Token refreshed, retrying service update...');

              // Retry the service update
              final retryResult = await SalonServicesService.updateSalonService(
                serviceId: event.serviceId,
                name: event.name,
                price: event.price,
                description: event.description,
              );

              if (retryResult['success']) {
                final serviceData =
                    retryResult['data'] as Map<String, dynamic>? ?? {};
                final message = retryResult['message'] as String;

                emit(SalonServiceUpdated(
                  message: message,
                  serviceData: serviceData,
                ));

                // Automatically refresh the services list after updating
                await _onLoadSalonServices(LoadSalonServices(), emit);
                return;
              }
            }
          }
        }

        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to update service',
          error: result['error'],
        ));
      }
    } catch (e) {
      emit(SalonServicesError(
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteSalonService(
    DeleteSalonService event,
    Emitter<SalonServicesState> emit,
  ) async {
    emit(SalonServiceDeleting());

    try {
      final result = await SalonServicesService.deleteSalonService(
        serviceId: event.serviceId,
      );

      if (result['success']) {
        final message = result['message'] as String;

        emit(SalonServiceDeleted(
          message: message,
          serviceId: event.serviceId,
        ));

        // Automatically refresh the services list after deleting
        await _onLoadSalonServices(LoadSalonServices(), emit);
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult = await SalonServicesService.refreshToken(
                refreshToken: refreshToken);
            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved');
              }
              print('🔄 Token refreshed, retrying service deletion...');

              // Retry the service deletion
              final retryResult = await SalonServicesService.deleteSalonService(
                serviceId: event.serviceId,
              );

              if (retryResult['success']) {
                final message = retryResult['message'] as String;

                emit(SalonServiceDeleted(
                  message: message,
                  serviceId: event.serviceId,
                ));

                // Automatically refresh the services list after deleting
                await _onLoadSalonServices(LoadSalonServices(), emit);
                return;
              }
            }
          }
        }

        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to delete service',
          error: result['error'],
        ));
      }
    } catch (e) {
      emit(SalonServicesError(
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }
}
