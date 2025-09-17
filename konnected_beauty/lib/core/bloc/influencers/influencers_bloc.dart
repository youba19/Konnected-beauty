import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';
import '../../models/filter_model.dart';

// Events
abstract class InfluencersEvent {}

class LoadInfluencers extends InfluencersEvent {
  final int page;
  final int limit;
  final String? search;
  final String? zone;
  final String? sortOrder;

  LoadInfluencers({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.zone,
    this.sortOrder,
  });
}

class LoadMoreInfluencers extends InfluencersEvent {
  final int page;
  final int limit;
  final String? search;
  final String? zone;
  final String? sortOrder;

  LoadMoreInfluencers({
    required this.page,
    this.limit = 10,
    this.search,
    this.zone,
    this.sortOrder,
  });
}

class SearchInfluencers extends InfluencersEvent {
  final String search;
  final int page;
  final int limit;
  final String? zone;
  final String? sortOrder;

  SearchInfluencers({
    required this.search,
    this.page = 1,
    this.limit = 10,
    this.zone,
    this.sortOrder,
  });
}

class RefreshInfluencers extends InfluencersEvent {
  final String? search;
  final int limit;
  final String? zone;
  final String? sortOrder;

  RefreshInfluencers({
    this.search,
    this.limit = 10,
    this.zone,
    this.sortOrder,
  });
}

class FilterInfluencers extends InfluencersEvent {
  final List<FilterModel> filters;

  FilterInfluencers({
    required this.filters,
  });
}

// States
abstract class InfluencersState {}

class InfluencersInitial extends InfluencersState {}

class InfluencersLoading extends InfluencersState {}

class InfluencersLoaded extends InfluencersState {
  final List<Map<String, dynamic>> influencers;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMoreData;
  final String? currentSearch;
  final String? currentZone;
  final String? currentSortOrder;
  final List<FilterModel> currentFilters;

  InfluencersLoaded({
    required this.influencers,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.hasMoreData,
    this.currentSearch,
    this.currentZone,
    this.currentSortOrder,
    this.currentFilters = const [],
  });
}

class InfluencersError extends InfluencersState {
  final String error;
  final String? details;

  InfluencersError({
    required this.error,
    this.details,
  });
}

// BLoC
class InfluencersBloc extends Bloc<InfluencersEvent, InfluencersState> {
  InfluencersBloc() : super(InfluencersInitial()) {
    on<LoadInfluencers>(_onLoadInfluencers);
    on<LoadMoreInfluencers>(_onLoadMoreInfluencers);
    on<SearchInfluencers>(_onSearchInfluencers);
    on<RefreshInfluencers>(_onRefreshInfluencers);
    on<FilterInfluencers>(_onFilterInfluencers);
  }

  Future<void> _onLoadInfluencers(
    LoadInfluencers event,
    Emitter<InfluencersState> emit,
  ) async {
    print('🎯 === INFLUENCERS BLOC: LOAD INFLUENCERS EVENT ===');
    print('🎯 Event received: LoadInfluencers');
    print('🎯 Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

    emit(InfluencersLoading());

    try {
      print('🔄 === LOADING INFLUENCERS ===');
      print('📄 Page: ${event.page}');
      print('📏 Limit: ${event.limit}');
      print('🔍 Search: ${event.search ?? 'None'}');
      print('📍 Zone: ${event.zone ?? 'None'}');
      print('📊 Sort Order: ${event.sortOrder ?? 'DESC'}');

      final result = await InfluencersService.getInfluencers(
        page: event.page,
        limit: event.limit,
        search: event.search,
        zone: event.zone,
        sortOrder: event.sortOrder,
      );

      if (result['success']) {
        final influencers =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final total = int.tryParse(result['total']?.toString() ?? '0') ?? 0;
        final hasMoreData = currentPage < totalPages;

        print('✅ Influencers loaded successfully');
        print('📊 Total: $total');
        print('📄 Current Page: $currentPage');
        print('📄 Total Pages: $totalPages');
        print('🔄 Has More Data: $hasMoreData');

        emit(InfluencersLoaded(
          influencers: influencers,
          currentPage: currentPage,
          totalPages: totalPages,
          total: total,
          hasMoreData: hasMoreData,
          currentSearch: event.search,
          currentZone: event.zone,
          currentSortOrder: event.sortOrder,
          currentFilters: const [],
        ));
      } else {
        print('❌ Failed to load influencers: ${result['message']}');
        emit(InfluencersError(
          error: result['message'] ?? 'Failed to load influencers',
          details: result['errorDetails']?.toString(),
        ));
      }
    } catch (e) {
      print('❌ Exception in _onLoadInfluencers: $e');
      emit(InfluencersError(
        error: 'Network error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadMoreInfluencers(
    LoadMoreInfluencers event,
    Emitter<InfluencersState> emit,
  ) async {
    try {
      print('🔄 === LOADING MORE INFLUENCERS ===');
      print('📄 Page: ${event.page}');
      print('📏 Limit: ${event.limit}');
      print('🔍 Search: ${event.search ?? 'None'}');
      print('📍 Zone: ${event.zone ?? 'None'}');
      print('📊 Sort Order: ${event.sortOrder ?? 'DESC'}');

      final result = await InfluencersService.getInfluencers(
        page: event.page,
        limit: event.limit,
        search: event.search,
        zone: event.zone,
        sortOrder: event.sortOrder,
      );

      if (result['success']) {
        final newInfluencers =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final total = int.tryParse(result['total']?.toString() ?? '0') ?? 0;
        final hasMoreData = currentPage < totalPages;

        // Get current state to append new influencers
        if (state is InfluencersLoaded) {
          final currentState = state as InfluencersLoaded;
          final allInfluencers = [
            ...currentState.influencers,
            ...newInfluencers
          ];

          print('✅ More influencers loaded successfully');
          print('📊 Previous Total: ${currentState.influencers.length}');
          print('📊 New Total: ${allInfluencers.length}');
          print('📄 Current Page: $currentPage');
          print('📄 Total Pages: $totalPages');
          print('🔄 Has More Data: $hasMoreData');

          emit(InfluencersLoaded(
            influencers: allInfluencers,
            currentPage: currentPage,
            totalPages: totalPages,
            total: total,
            hasMoreData: hasMoreData,
            currentSearch: event.search,
            currentZone: event.zone,
            currentSortOrder: event.sortOrder,
            currentFilters: const [],
          ));
        }
      } else {
        print('❌ Failed to load more influencers: ${result['message']}');
        // Don't emit error state for load more, just log it
        print('⚠️ Load more failed, keeping current state');
      }
    } catch (e) {
      print('❌ Exception in _onLoadMoreInfluencers: $e');
      // Don't emit error state for load more, just log it
      print('⚠️ Load more failed, keeping current state');
    }
  }

  Future<void> _onSearchInfluencers(
    SearchInfluencers event,
    Emitter<InfluencersState> emit,
  ) async {
    emit(InfluencersLoading());

    try {
      print('🔍 === SEARCHING INFLUENCERS ===');
      print('🔍 Search Query: ${event.search}');
      print('📄 Page: ${event.page}');
      print('📏 Limit: ${event.limit}');
      print('📍 Zone: ${event.zone ?? 'None'}');
      print('📊 Sort Order: ${event.sortOrder ?? 'DESC'}');

      final result = await InfluencersService.getInfluencers(
        page: event.page,
        limit: event.limit,
        search: event.search,
        zone: event.zone,
        sortOrder: event.sortOrder,
      );

      if (result['success']) {
        final influencers =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final total = int.tryParse(result['total']?.toString() ?? '0') ?? 0;
        final hasMoreData = currentPage < totalPages;

        print('✅ Influencers search completed successfully');
        print('📊 Results: ${influencers.length}');
        print('📄 Current Page: $currentPage');
        print('📄 Total Pages: $totalPages');
        print('🔄 Has More Data: $hasMoreData');

        emit(InfluencersLoaded(
          influencers: influencers,
          currentPage: currentPage,
          totalPages: totalPages,
          total: total,
          hasMoreData: hasMoreData,
          currentSearch: event.search,
          currentZone: event.zone,
          currentSortOrder: event.sortOrder,
          currentFilters: const [],
        ));
      } else {
        print('❌ Influencers search failed: ${result['message']}');
        emit(InfluencersError(
          error: result['message'] ?? 'Search failed',
          details: result['errorDetails']?.toString(),
        ));
      }
    } catch (e) {
      print('❌ Exception in _onSearchInfluencers: $e');
      emit(InfluencersError(
        error: 'Search error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshInfluencers(
    RefreshInfluencers event,
    Emitter<InfluencersState> emit,
  ) async {
    emit(InfluencersLoading());

    try {
      print('🔄 === REFRESHING INFLUENCERS ===');
      print('🔍 Search: ${event.search ?? 'None'}');
      print('📏 Limit: ${event.limit}');
      print('📍 Zone: ${event.zone ?? 'None'}');
      print('📊 Sort Order: ${event.sortOrder ?? 'DESC'}');

      final result = await InfluencersService.getInfluencers(
        page: 1, // Always start from page 1 on refresh
        limit: event.limit,
        search: event.search,
        zone: event.zone,
        sortOrder: event.sortOrder,
      );

      if (result['success']) {
        final influencers =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final total = int.tryParse(result['total']?.toString() ?? '0') ?? 0;
        final hasMoreData = currentPage < totalPages;

        print('✅ Influencers refreshed successfully');
        print('📊 Total: $total');
        print('📄 Current Page: $currentPage');
        print('📄 Total Pages: $totalPages');
        print('🔄 Has More Data: $hasMoreData');

        emit(InfluencersLoaded(
          influencers: influencers,
          currentPage: currentPage,
          totalPages: totalPages,
          total: total,
          hasMoreData: hasMoreData,
          currentSearch: event.search,
          currentZone: event.zone,
          currentSortOrder: event.sortOrder,
          currentFilters: const [],
        ));
      } else {
        print('❌ Failed to refresh influencers: ${result['message']}');
        emit(InfluencersError(
          error: result['message'] ?? 'Refresh failed',
          details: result['errorDetails']?.toString(),
        ));
      }
    } catch (e) {
      print('❌ Exception in _onRefreshInfluencers: $e');
      emit(InfluencersError(
        error: 'Refresh error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFilterInfluencers(
    FilterInfluencers event,
    Emitter<InfluencersState> emit,
  ) async {
    print('🔍 === FILTERING INFLUENCERS ===');
    print('🔍 Filters Count: ${event.filters.length}');

    // Log enabled filters
    final enabledFilters = event.filters.where((f) => f.enabled).toList();
    print('🔍 Enabled Filters: ${enabledFilters.length}');
    for (final filter in enabledFilters) {
      print('🔍   - ${filter.key}: ${filter.value}');
    }

    // Check if this is a pagination request (page > 1)
    final pageFilter = event.filters.firstWhere(
      (f) => f.key == 'page' && f.enabled,
      orElse: () => FilterModel(
        key: 'page',
        value: '1',
        description: 'Page number',
        enabled: true,
        equals: true,
        uuid: '',
      ),
    );
    final currentPage = int.tryParse(pageFilter.value) ?? 1;
    final isPagination = currentPage > 1;

    // If it's pagination, don't show loading state to avoid UI flicker
    if (!isPagination) {
      emit(InfluencersLoading());
    }

    try {
      final result = await InfluencersService.getInfluencersWithFilters(
        filters: event.filters,
      );

      if (result['success']) {
        final newInfluencers =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final resultCurrentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final total = int.tryParse(result['total']?.toString() ?? '0') ?? 0;
        final hasMoreData = resultCurrentPage < totalPages;

        print('✅ Influencers filtered successfully');
        print('📊 Total: $total');
        print('📄 Current Page: $resultCurrentPage');
        print('📄 Total Pages: $totalPages');
        print('🔄 Has More Data: $hasMoreData');

        // If this is pagination, append to existing list
        List<Map<String, dynamic>> finalInfluencers;
        if (isPagination) {
          final currentState = state;
          if (currentState is InfluencersLoaded) {
            finalInfluencers = List.from(currentState.influencers)
              ..addAll(newInfluencers);
            print(
                '📄 Appending ${newInfluencers.length} new influencers to existing ${currentState.influencers.length}');
          } else {
            finalInfluencers = newInfluencers;
          }
        } else {
          finalInfluencers = newInfluencers;
        }

        // Apply client-side search filtering if search parameter exists
        final searchFilter = event.filters.firstWhere(
          (f) => f.key == 'search' && f.enabled,
          orElse: () => FilterModel(
            key: 'search',
            value: '',
            description: 'Search by name or bio',
            enabled: false,
            equals: true,
            uuid: '',
          ),
        );

        if (searchFilter.enabled && searchFilter.value.isNotEmpty) {
          print(
              '🔍 Applying client-side search filter: "${searchFilter.value}"');
          final searchTerm = searchFilter.value.toLowerCase();
          finalInfluencers = finalInfluencers.where((influencer) {
            final pseudo =
                influencer['profile']?['pseudo']?.toString().toLowerCase() ??
                    '';
            final bio =
                influencer['profile']?['bio']?.toString().toLowerCase() ?? '';
            final zone =
                influencer['profile']?['zone']?.toString().toLowerCase() ?? '';

            return pseudo.contains(searchTerm) ||
                bio.contains(searchTerm) ||
                zone.contains(searchTerm);
          }).toList();
          print(
              '🔍 After search filter: ${finalInfluencers.length} influencers');
        }

        // Apply zone filter
        print('🔍 === CHECKING FOR ZONE FILTER ===');
        print('🔍 Total filters received: ${event.filters.length}');
        for (final filter in event.filters) {
          print(
              '🔍 Filter: ${filter.key} = ${filter.value} (enabled: ${filter.enabled})');
        }

        // Debug: Show available zones in the data
        print('🔍 Available zones in current data:');
        final availableZones = <String>{};
        for (final influencer in finalInfluencers) {
          final zone = influencer['profile']?['zone']?.toString() ?? 'No zone';
          availableZones.add(zone);
        }
        print('🔍 Zones: ${availableZones.toList()}');

        final zoneFilter = event.filters.firstWhere(
          (f) => f.key == 'zone' && f.enabled,
          orElse: () => FilterModel(
            key: 'zone',
            value: '',
            description: 'Location zone',
            enabled: false,
            equals: true,
            uuid: '',
          ),
        );

        print(
            '🔍 Zone filter found: enabled=${zoneFilter.enabled}, value="${zoneFilter.value}"');

        if (zoneFilter.enabled && zoneFilter.value.isNotEmpty) {
          print('🔍 Applying client-side zone filter: "${zoneFilter.value}"');
          final zoneTerm = zoneFilter.value.toLowerCase();
          print('🔍 Zone term for filtering: "$zoneTerm"');
          print(
              '🔍 Influencers before zone filter: ${finalInfluencers.length}');

          finalInfluencers = finalInfluencers.where((influencer) {
            final zone =
                influencer['profile']?['zone']?.toString().toLowerCase() ?? '';
            final matches = zone.contains(zoneTerm);
            if (matches) {
              print(
                  '🔍 ✅ Match found: ${influencer['profile']?['pseudo']} in zone "$zone"');
            }
            return matches;
          }).toList();
          print('🔍 After zone filter: ${finalInfluencers.length} influencers');
        } else {
          print(
              '🔍 No zone filter applied (enabled: ${zoneFilter.enabled}, value: "${zoneFilter.value}")');
        }
        print('🔍 === END ZONE FILTER CHECK ===');

        emit(InfluencersLoaded(
          influencers: finalInfluencers,
          currentPage: resultCurrentPage,
          totalPages: totalPages,
          total: total,
          hasMoreData: hasMoreData,
          currentFilters: event.filters,
        ));
      } else {
        print('❌ Failed to filter influencers: ${result['message']}');
        emit(InfluencersError(
          error: result['message'] ?? 'Failed to filter influencers',
          details: result['errorDetails']?.toString(),
        ));
      }
    } catch (e) {
      print('❌ Exception in _onFilterInfluencers: $e');
      emit(InfluencersError(
        error: 'Filter error: ${e.toString()}',
      ));
    }
  }
}
