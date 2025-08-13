import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_services_service.dart';
import '../../services/api/salon_auth_service.dart';
import '../../services/storage/token_storage_service.dart';

// Events
abstract class SalonServicesEvent {}

class LoadSalonServices extends SalonServicesEvent {}

class RefreshSalonServices extends SalonServicesEvent {}

class FilterSalonServices extends SalonServicesEvent {
  final int? minPrice;
  final int? maxPrice;
  final String? searchQuery;

  FilterSalonServices({
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
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
  final String serviceName;

  DeleteSalonService({
    required this.serviceId,
    required this.serviceName,
  });
}

class LoadMoreSalonServices extends SalonServicesEvent {
  final int page;
  final String? searchQuery;
  final int? minPrice;
  final int? maxPrice;

  LoadMoreSalonServices({
    required this.page,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
  });
}

class ResetSalonServices extends SalonServicesEvent {}

// States
abstract class SalonServicesState {}

class SalonServicesInitial extends SalonServicesState {}

class SalonServicesLoading extends SalonServicesState {}

class SalonServicesLoadingMore extends SalonServicesState {}

class SalonServicesLoaded extends SalonServicesState {
  final List<dynamic> services;
  final String message;
  final int currentPage;
  final bool hasMoreData;
  final String? currentSearch;
  final int? currentMinPrice;
  final int? currentMaxPrice;

  SalonServicesLoaded({
    required this.services,
    required this.message,
    this.currentPage = 1,
    this.hasMoreData = true,
    this.currentSearch,
    this.currentMinPrice,
    this.currentMaxPrice,
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
    on<LoadMoreSalonServices>(_onLoadMoreSalonServices);
    on<CreateSalonService>(_onCreateSalonService);
    on<UpdateSalonService>(_onUpdateSalonService);
    on<DeleteSalonService>(_onDeleteSalonService);
    on<ResetSalonServices>(_onResetSalonServices);
  }

  Future<void> _onLoadSalonServices(
    LoadSalonServices event,
    Emitter<SalonServicesState> emit,
  ) async {
    print('📄 === BLOC: LOAD SALON SERVICES ===');
    emit(SalonServicesLoading());

    try {
      // Check if access token is expired and refresh if needed
      final isTokenExpired = await TokenStorageService.isAccessTokenExpired();
      if (isTokenExpired) {
        print(
            '⚠️ Access token is expired, attempting to refresh before API call...');
        final refreshToken = await TokenStorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshResult =
              await SalonAuthService.refreshToken(refreshToken: refreshToken);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await TokenStorageService.saveAccessToken(newAccessToken);
              print('💾 Token refreshed before API call');
            }
          }
        }
      }

      final result = await SalonServicesService.getServices();

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final int detectedCurrentPage =
            (pagination?['currentPage'] ?? pagination?['page'] ?? 1) as int;
        final int? detectedTotalPages = (pagination?['totalPages'] ??
            pagination?['pages'] ??
            pagination?['pageCount']) as int?;
        // Always assume more data if we received a full page (10 items)
        // This ensures infinite scroll works even if API pagination metadata is incorrect
        final bool hasMoreData = services.length >= 10;

        print('📄 === INITIAL LOAD RESULT ===');
        print('📄 Services Count: ${services.length}');
        print('📄 Pagination: $pagination');
        print('📄 Current Page: $detectedCurrentPage');
        print('📄 Has More Data: $hasMoreData');

        emit(SalonServicesLoaded(
          services: services,
          message: message,
          currentPage: detectedCurrentPage,
          hasMoreData: hasMoreData,
          currentSearch: null,
          currentMinPrice: null,
          currentMaxPrice: null,
        ));
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            print('🔄 Attempting token refresh with stored refresh token...');

            final refreshResult =
                await SalonAuthService.refreshToken(refreshToken: refreshToken);

            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved successfully');
              } else {
                print('❌ Failed to get new access token from refresh response');
                emit(SalonServicesError(
                  message: 'Token refresh failed - no access token received',
                  error: 'TokenRefreshError',
                ));
                return;
              }

              print(
                  '🔄 Token refreshed successfully, retrying service load...');

              // Retry the service load
              final retryResult = await SalonServicesService.getServices();

              if (retryResult['success']) {
                final services = retryResult['data'] as List<dynamic>;
                final message = retryResult['message'] as String;
                final pagination =
                    retryResult['pagination'] as Map<String, dynamic>?;
                final currentPage = pagination?['currentPage'] ?? 1;
                final hasMoreData = pagination != null &&
                    (pagination['currentPage'] ?? 0) <
                        (pagination['totalPages'] ?? 0);

                emit(SalonServicesLoaded(
                  services: services,
                  message: message,
                  currentPage: currentPage,
                  hasMoreData: hasMoreData,
                  currentSearch: null,
                  currentMinPrice: null,
                  currentMaxPrice: null,
                ));
                return;
              } else {
                print('❌ Token refresh failed: ${refreshResult['message']}');
                emit(SalonServicesError(
                  message: 'Token refresh failed - please login again',
                  error: 'TokenRefreshFailed',
                ));
                return;
              }
            } else {
              print('❌ No valid refresh token available');
              emit(SalonServicesError(
                message: 'No refresh token available - please login again',
                error: 'NoRefreshToken',
              ));
              return;
            }
          } else {
            print('❌ Non-401 error: ${result['message']}');
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
    print('📄 === BLOC: REFRESH SALON SERVICES ===');
    emit(SalonServicesLoading());

    try {
      // Check if access token is expired and refresh if needed
      final isTokenExpired = await TokenStorageService.isAccessTokenExpired();
      if (isTokenExpired) {
        print(
            '⚠️ Access token is expired, attempting to refresh before refresh API call...');
        final refreshToken = await TokenStorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshResult =
              await SalonAuthService.refreshToken(refreshToken: refreshToken);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await TokenStorageService.saveAccessToken(newAccessToken);
              print('💾 Token refreshed before refresh API call');
            }
          }
        }
      }

      // Get current state to preserve filters during refresh
      final currentState = state;
      String? currentSearch;
      int? currentMinPrice;
      int? currentMaxPrice;

      if (currentState is SalonServicesLoaded) {
        currentSearch = currentState.currentSearch;
        currentMinPrice = currentState.currentMinPrice;
        currentMaxPrice = currentState.currentMaxPrice;
        print('📄 === PRESERVING FILTERS DURING REFRESH ===');
        print('📄 Current Search: $currentSearch');
        print('📄 Current Min Price: $currentMinPrice');
        print('📄 Current Max Price: $currentMaxPrice');
      }

      final result = await SalonServicesService.getServices(
        minPrice: currentMinPrice?.toDouble(),
        maxPrice: currentMaxPrice?.toDouble(),
        search: currentSearch,
        page: 1, // Always start from page 1 on refresh
      );

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final int detectedCurrentPage =
            (pagination?['currentPage'] ?? pagination?['page'] ?? 1) as int;
        final int? detectedTotalPages = (pagination?['totalPages'] ??
            pagination?['pages'] ??
            pagination?['pageCount']) as int?;
        // Always assume more data if we received a full page (10 items)
        // This ensures infinite scroll works even if API pagination metadata is incorrect
        final bool hasMoreData = services.length >= 10;

        print('📄 === REFRESH RESULT ===');
        print('📄 Services Count: ${services.length}');
        print('📄 Pagination: $pagination');
        print('📄 Current Page: $detectedCurrentPage');
        print('📄 Has More Data: $hasMoreData');

        emit(SalonServicesLoaded(
          services: services,
          message: message,
          currentPage: detectedCurrentPage,
          hasMoreData: hasMoreData,
          currentSearch: currentSearch,
          currentMinPrice: currentMinPrice,
          currentMaxPrice: currentMaxPrice,
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
        search: event.searchQuery,
        page: 1, // Reset to first page when filtering
      );

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final int detectedCurrentPage =
            (pagination?['currentPage'] ?? pagination?['page'] ?? 1) as int;
        final int? detectedTotalPages = (pagination?['totalPages'] ??
            pagination?['pages'] ??
            pagination?['pageCount']) as int?;
        // Always assume more data if we received a full page (10 items)
        // This ensures infinite scroll works even if API pagination metadata is incorrect
        final bool hasMoreData = services.length >= 10;

        print('📄 === FILTER RESULT ===');
        print('📄 Services Count: ${services.length}');
        print('📄 Pagination: $pagination');
        print('📄 Current Page: $detectedCurrentPage');
        print('📄 Has More Data: $hasMoreData');

        emit(SalonServicesLoaded(
          services: services,
          message: message,
          currentPage: detectedCurrentPage,
          hasMoreData: hasMoreData,
          currentSearch: event.searchQuery,
          currentMinPrice: event.minPrice,
          currentMaxPrice: event.maxPrice,
        ));
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected during filter, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult =
                await SalonAuthService.refreshToken(refreshToken: refreshToken);
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
                search: event.searchQuery,
                page: 1, // Reset to first page when filtering
              );

              if (retryResult['success']) {
                final services = retryResult['data'] as List<dynamic>;
                final message = retryResult['message'] as String;
                final pagination =
                    retryResult['pagination'] as Map<String, dynamic>?;
                final int detectedCurrentPage = (pagination?['currentPage'] ??
                    pagination?['page'] ??
                    1) as int;
                // Always assume more data if we received a full page (10 items)
                final bool hasMoreData = services.length >= 10;

                emit(SalonServicesLoaded(
                  services: services,
                  message: message,
                  currentPage: detectedCurrentPage,
                  hasMoreData: hasMoreData,
                  currentSearch: event.searchQuery,
                  currentMinPrice: event.minPrice,
                  currentMaxPrice: event.maxPrice,
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
        page: 1, // Reset to first page when searching
      );

      print('🔍 === SEARCH RESULT ===');
      print('✅ Success: ${result['success']}');
      print('📊 Services Count: ${result['data']?.length ?? 0}');

      if (result['success']) {
        final services = result['data'] as List<dynamic>;
        final message = result['message'] as String;
        final pagination = result['pagination'] as Map<String, dynamic>?;
        final int detectedCurrentPage =
            (pagination?['currentPage'] ?? pagination?['page'] ?? 1) as int;
        final int? detectedTotalPages = (pagination?['totalPages'] ??
            pagination?['pages'] ??
            pagination?['pageCount']) as int?;
        // Always assume more data if we received a full page (10 items)
        final bool hasMoreData = services.length >= 10;

        print('📄 === SEARCH RESULT ===');
        print('📄 Services Count: ${services.length}');
        print('📄 Pagination: $pagination');
        print('📄 Current Page: $detectedCurrentPage');
        print('📄 Has More Data: $hasMoreData');

        emit(SalonServicesLoaded(
          services: services,
          message: message,
          currentPage: detectedCurrentPage,
          hasMoreData: hasMoreData,
          currentSearch: event.searchQuery,
          currentMinPrice: null,
          currentMaxPrice: null,
        ));
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected during search, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult =
                await SalonAuthService.refreshToken(refreshToken: refreshToken);
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
                page: 1, // Reset to first page when searching
              );

              if (retryResult['success']) {
                final services = retryResult['data'] as List<dynamic>;
                final message = retryResult['message'] as String;
                final pagination =
                    retryResult['pagination'] as Map<String, dynamic>?;
                final int detectedCurrentPage = (pagination?['currentPage'] ??
                    pagination?['page'] ??
                    1) as int;
                // Always assume more data if we received a full page (10 items)
                final bool hasMoreData = services.length >= 10;

                emit(SalonServicesLoaded(
                  services: services,
                  message: message,
                  currentPage: detectedCurrentPage,
                  hasMoreData: hasMoreData,
                  currentSearch: event.searchQuery,
                  currentMinPrice: null,
                  currentMaxPrice: null,
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
          message: 'Service "${event.name}" created successfully!',
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
            final refreshResult =
                await SalonAuthService.refreshToken(refreshToken: refreshToken);
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
                  message: 'Service "${event.name}" created successfully!',
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
          message: 'Service "${event.name ?? 'Unknown'}" updated successfully!',
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
            final refreshResult =
                await SalonAuthService.refreshToken(refreshToken: refreshToken);
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
                  message:
                      'Service "${event.name ?? 'Unknown'}" updated successfully!',
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
          message: 'Service "${event.serviceName}" deleted successfully!',
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
            final refreshResult =
                await SalonAuthService.refreshToken(refreshToken: refreshToken);
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
                  message:
                      'Service "${event.serviceName}" deleted successfully!',
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

  Future<void> _onLoadMoreSalonServices(
    LoadMoreSalonServices event,
    Emitter<SalonServicesState> emit,
  ) async {
    print('📄 === BLOC: LOAD MORE SALON SERVICES ===');
    print('📄 Requested Page: ${event.page}');
    print('📄 Search Query: ${event.searchQuery}');
    print('📄 Min Price: ${event.minPrice}');
    print('📄 Max Price: ${event.maxPrice}');

    // Capture the current state BEFORE emitting any intermediate loading state
    final SalonServicesState previousStateSnapshot = state;

    try {
      // Check if access token is expired and refresh if needed
      final isTokenExpired = await TokenStorageService.isAccessTokenExpired();
      if (isTokenExpired) {
        print(
            '⚠️ Access token is expired, attempting to refresh before load more API call...');
        final refreshToken = await TokenStorageService.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshResult =
              await SalonAuthService.refreshToken(refreshToken: refreshToken);
          if (refreshResult['success']) {
            final newAccessToken = refreshResult['data']['access_token'];
            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await TokenStorageService.saveAccessToken(newAccessToken);
              print('💾 Token refreshed before load more API call');
            }
          }
        }
      }

      final result = await SalonServicesService.getServices(
        page: event.page,
        search: event.searchQuery,
        minPrice: event.minPrice?.toDouble(),
        maxPrice: event.maxPrice?.toDouble(),
      );

      print('📄 === LOAD MORE RESULT ===');
      print('📄 Success: ${result['success']}');
      print('📄 New Services Count: ${result['data']?.length ?? 0}');
      print('📄 Pagination: ${result['pagination']}');

      if (result['success']) {
        final newServices = result['data'] as List<dynamic>;
        final message = result['message'] as String;
        final pagination = result['pagination'] as Map<String, dynamic>?;

        // Always assume more data if we received a full page (10 items)
        // This ensures infinite scroll works even if API pagination metadata is incorrect
        final bool hasMoreData = newServices.length >= 10;

        // Use the previous loaded state snapshot to append new services
        if (previousStateSnapshot is SalonServicesLoaded) {
          final currentState = previousStateSnapshot as SalonServicesLoaded;
          final allServices = [...currentState.services, ...newServices];

          print('📄 === UPDATING STATE ===');
          print('📄 Previous Services Count: ${currentState.services.length}');
          print('📄 New Services Count: ${newServices.length}');
          print('📄 Total Services Count: ${allServices.length}');
          print('📄 New Current Page: ${event.page}');
          print('📄 New Has More Data: $hasMoreData');

          emit(SalonServicesLoaded(
            services: allServices,
            message: message,
            currentPage: event.page,
            hasMoreData: hasMoreData,
            currentSearch: currentState.currentSearch,
            currentMinPrice: currentState.currentMinPrice,
            currentMaxPrice: currentState.currentMaxPrice,
          ));
        } else {
          print(
              '📄 ❌ Previous state is not SalonServicesLoaded: ${previousStateSnapshot.runtimeType}');
        }
      } else {
        // Check if it's an authentication error
        if (result['statusCode'] == 401) {
          print(
              '🔐 Authentication error detected during load more, triggering token refresh...');

          // Try to refresh token and retry
          final refreshToken = await TokenStorageService.getRefreshToken();
          if (refreshToken != null) {
            final refreshResult =
                await SalonAuthService.refreshToken(refreshToken: refreshToken);
            if (refreshResult['success']) {
              // Save the new access token
              final newAccessToken = refreshResult['data']['access_token'];
              if (newAccessToken != null) {
                await TokenStorageService.saveAccessToken(newAccessToken);
                print('💾 New access token saved');
              }
              print('🔄 Token refreshed, retrying load more...');

              // Retry the load more
              final retryResult = await SalonServicesService.getServices(
                page: event.page,
                search: event.searchQuery,
                minPrice: event.minPrice?.toDouble(),
                maxPrice: event.maxPrice?.toDouble(),
              );

              if (retryResult['success']) {
                final newServices = retryResult['data'] as List<dynamic>;
                final message = retryResult['message'] as String;
                final pagination =
                    retryResult['pagination'] as Map<String, dynamic>?;

                final hasMoreData = pagination != null &&
                    (pagination['currentPage'] ?? 0) <
                        (pagination['totalPages'] ?? 0);

                if (state is SalonServicesLoaded) {
                  final currentState = state as SalonServicesLoaded;
                  final allServices = [
                    ...currentState.services,
                    ...newServices
                  ];

                  emit(SalonServicesLoaded(
                    services: allServices,
                    message: message,
                    currentPage: event.page,
                    hasMoreData: hasMoreData,
                  ));
                }
                return;
              }
            }
          }
        }

        emit(SalonServicesError(
          message: result['message'] ?? 'Failed to load more services',
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

  void _onResetSalonServices(
    ResetSalonServices event,
    Emitter<SalonServicesState> emit,
  ) {
    print('🔄 === RESETTING SALON SERVICES ===');
    print('🔄 Clearing all services data to prevent cross-user contamination');

    // Reset to initial state
    emit(SalonServicesInitial());

    print('🔄 Salon services reset completed');
  }
}
