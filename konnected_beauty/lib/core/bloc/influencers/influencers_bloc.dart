import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';

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

  InfluencersLoaded({
    required this.influencers,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.hasMoreData,
    this.currentSearch,
    this.currentZone,
    this.currentSortOrder,
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
  }

  Future<void> _onLoadInfluencers(
    LoadInfluencers event,
    Emitter<InfluencersState> emit,
  ) async {
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
}
