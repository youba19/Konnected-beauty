import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/saloons_service.dart';
import 'saloons_event.dart';
import 'saloons_state.dart';

class SaloonsBloc extends Bloc<SaloonsEvent, SaloonsState> {
  SaloonsBloc() : super(SaloonsInitial()) {
    on<LoadSaloons>(_onLoadSaloons);
    on<LoadMoreSaloons>(_onLoadMoreSaloons);
    on<RefreshSaloons>(_onRefreshSaloons);
    on<SearchSaloons>(_onSearchSaloons);
  }

  Future<void> _onLoadSaloons(
      LoadSaloons event, Emitter<SaloonsState> emit) async {
    try {
      emit(SaloonsLoading());

      print('📊 === LOADING SALOONS ===');
      print('📄 Page: ${event.page}');
      print('📏 Limit: ${event.limit}');
      print('🔍 Search: "${event.search ?? 'None'}"');

      final result = await SaloonsService.getSaloons(
        search: event.search,
        page: event.page,
        limit: event.limit,
      );

      print('📊 === SALOONS LOAD RESULT ===');
      print('📊 Success: ${result['success']}');
      print('📊 Message: ${result['message']}');
      print('📊 Status Code: ${result['statusCode']}');
      print('📊 Data: ${result['data']}');

      if (result['success'] == true) {
        final saloons = List<dynamic>.from(result['data'] ?? []);
        final total = result['total'] ?? 0;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;

        print('✅ Saloons loaded successfully');
        print('📊 Results: ${saloons.length}');
        print('📄 Current Page: $currentPage');
        print('📄 Total Pages: $totalPages');
        print('📄 Total: $total');
        print('🔄 Has More Data: ${currentPage < totalPages}');

        emit(SaloonsLoaded(
          saloons: saloons,
          message: result['message'] ?? 'Saloons loaded successfully',
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          currentSearch: event.search,
          total: total,
          totalPages: totalPages,
        ));
      } else {
        print('❌ Failed to load saloons: ${result['message']}');
        emit(SaloonsError(result['message'] ?? 'Failed to load saloons'));
      }
    } catch (e) {
      print('❌ Error loading saloons: $e');
      emit(SaloonsError('Error loading saloons: $e'));
    }
  }

  Future<void> _onLoadMoreSaloons(
      LoadMoreSaloons event, Emitter<SaloonsState> emit) async {
    try {
      final currentState = state;
      if (currentState is! SaloonsLoaded) return;

      print('📄 === LOAD MORE SALOONS ===');
      print('📄 Requested Page: ${event.page}');
      print('🔍 Search: "${event.search ?? 'None'}"');

      emit(SaloonsLoadingMore(currentState.saloons));

      final result = await SaloonsService.getSaloons(
        search: event.search,
        page: event.page,
        limit: event.limit,
      );

      print('📄 === LOAD MORE RESULT ===');
      print('📄 Success: ${result['success']}');
      print('📄 New Saloons Count: ${(result['data'] as List?)?.length ?? 0}');
      print('📄 API Current Page: ${result['currentPage']}');
      print('📄 API Total Pages: ${result['totalPages']}');
      print('📄 API Total: ${result['total']}');

      if (result['success'] == true) {
        final newSaloons = List<dynamic>.from(result['data'] ?? []);
        final total = result['total'] ?? 0;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;

        // Combine existing and new saloons
        final allSaloons = [...currentState.saloons, ...newSaloons];

        print('📄 === UPDATING STATE ===');
        print('📄 Previous Saloons Count: ${currentState.saloons.length}');
        print('📄 New Saloons Count: ${newSaloons.length}');
        print('📄 Total Saloons Count: ${allSaloons.length}');
        print('📄 New Current Page: $currentPage');
        print('📄 New Has More Data: ${currentPage < totalPages}');

        emit(SaloonsLoaded(
          saloons: allSaloons,
          message: result['message'] ?? 'Saloons loaded successfully',
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          currentSearch: event.search,
          total: total,
          totalPages: totalPages,
        ));
      } else {
        print('❌ Failed to load more saloons: ${result['message']}');
        emit(SaloonsError(result['message'] ?? 'Failed to load more saloons'));
      }
    } catch (e) {
      print('❌ Error loading more saloons: $e');
      emit(SaloonsError('Error loading more saloons: $e'));
    }
  }

  Future<void> _onRefreshSaloons(
      RefreshSaloons event, Emitter<SaloonsState> emit) async {
    print('🔄 === REFRESHING SALOONS ===');
    add(LoadSaloons(
      search: event.search,
      page: 1,
      limit: event.limit,
    ));
  }

  Future<void> _onSearchSaloons(
      SearchSaloons event, Emitter<SaloonsState> emit) async {
    print('🔍 === SEARCHING SALOONS ===');
    print('🔍 Search Term: "${event.search}"');
    add(LoadSaloons(
      search: event.search,
      page: 1,
      limit: 10,
    ));
  }
}
