import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';
import '../bloc_error_helper.dart';
import 'influencer_campaigns_event.dart';
import 'influencer_campaigns_state.dart';

class InfluencerCampaignsBloc
    extends Bloc<InfluencerCampaignsEvent, InfluencerCampaignsState> {
  InfluencerCampaignsBloc() : super(InfluencerCampaignsInitial()) {
    on<LoadInfluencerCampaigns>(_onLoadCampaigns);
    on<LoadMoreInfluencerCampaigns>(_onLoadMoreCampaigns);
    on<SearchInfluencerCampaigns>(_onSearchCampaigns);
    on<RefreshInfluencerCampaigns>(_onRefreshCampaigns);
    on<FilterInfluencerCampaigns>(_onFilterCampaigns);
  }

  Future<void> _onLoadCampaigns(
    LoadInfluencerCampaigns event,
    Emitter<InfluencerCampaignsState> emit,
  ) async {
    print('📋 === LOADING INFLUENCER CAMPAIGNS ===');
    print('📋 Status: ${event.status}');
    print('📋 Search: ${event.search}');
    print('📋 Page: ${event.page}');

    emit(InfluencerCampaignsLoading());

    try {
      final result = await InfluencersService.getInfluencerCampaigns(
        status: event.status,
        page: event.page,
        limit: event.limit,
      );

      if (result['success'] == true) {
        final campaigns = List<dynamic>.from(result['data'] ?? []);
        final total = result['total'] ?? 0;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;

        print('✅ Loaded ${campaigns.length} campaigns');
        print('📄 Current Page: $currentPage');
        print('📄 Total Pages: $totalPages');
        print('📄 Has More: ${currentPage < totalPages}');

        emit(InfluencerCampaignsLoaded(
          campaigns: campaigns,
          message: result['message'] ?? 'Campaigns loaded successfully',
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          currentStatus: event.status,
          currentSearch: event.search,
          total: total,
          totalPages: totalPages,
        ));
      } else {
        print('❌ Failed to load campaigns: ${result['message']}');
        emit(InfluencerCampaignsError(
            BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(InfluencerCampaignsError(
          BlocErrorHelper.messageFrom(e, st, 'loadInfluencerCampaigns')));
    }
  }

  Future<void> _onLoadMoreCampaigns(
    LoadMoreInfluencerCampaigns event,
    Emitter<InfluencerCampaignsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! InfluencerCampaignsLoaded) return;

    print('📋 === LOADING MORE INFLUENCER CAMPAIGNS ===');
    print('📋 Current Page: ${currentState.currentPage}');
    print('📋 Has More: ${currentState.hasMore}');

    if (!currentState.hasMore) {
      print('📋 No more campaigns to load');
      return;
    }

    emit(InfluencerCampaignsLoadingMore(
      campaigns: currentState.campaigns,
      message: currentState.message,
      currentPage: currentState.currentPage,
      hasMore: currentState.hasMore,
      currentStatus: currentState.currentStatus,
      currentSearch: currentState.currentSearch,
      total: currentState.total,
      totalPages: currentState.totalPages,
    ));

    try {
      final result = await InfluencersService.getInfluencerCampaigns(
        status: event.status ?? currentState.currentStatus,
        page: currentState.currentPage + 1,
        limit: 10,
      );

      if (result['success'] == true) {
        final newCampaigns = List<dynamic>.from(result['data'] ?? []);
        final allCampaigns = [...currentState.campaigns, ...newCampaigns];
        final total = result['total'] ?? 0;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;

        print('✅ Loaded ${newCampaigns.length} more campaigns');
        print('📄 Total campaigns: ${allCampaigns.length}');
        print('📄 Current Page: $currentPage');
        print('📄 Has More: ${currentPage < totalPages}');

        emit(InfluencerCampaignsLoaded(
          campaigns: allCampaigns,
          message: result['message'] ?? 'Campaigns loaded successfully',
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          currentStatus: event.status ?? currentState.currentStatus,
          currentSearch: event.search ?? currentState.currentSearch,
          total: total,
          totalPages: totalPages,
        ));
      } else {
        print('❌ Failed to load more campaigns: ${result['message']}');
        emit(InfluencerCampaignsError(
            BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(InfluencerCampaignsError(
          BlocErrorHelper.messageFrom(e, st, 'loadMoreInfluencerCampaigns')));
    }
  }

  Future<void> _onSearchCampaigns(
    SearchInfluencerCampaigns event,
    Emitter<InfluencerCampaignsState> emit,
  ) async {
    print('🔍 === SEARCHING INFLUENCER CAMPAIGNS ===');
    print('🔍 Search Query: ${event.search}');

    emit(InfluencerCampaignsLoading());

    try {
      final result = await InfluencersService.getInfluencerCampaigns(
        page: 1,
        limit: 10,
      );

      if (result['success'] == true) {
        final campaigns = List<dynamic>.from(result['data'] ?? []);
        final total = result['total'] ?? 0;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;

        print(
            '✅ Found ${campaigns.length} campaigns for search: ${event.search}');

        emit(InfluencerCampaignsLoaded(
          campaigns: campaigns,
          message: result['message'] ?? 'Search completed',
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          currentStatus: null,
          currentSearch: event.search,
          total: total,
          totalPages: totalPages,
        ));
      } else {
        print('❌ Search failed: ${result['message']}');
        emit(InfluencerCampaignsError(
            BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(InfluencerCampaignsError(
          BlocErrorHelper.messageFrom(e, st, 'searchInfluencerCampaigns')));
    }
  }

  Future<void> _onRefreshCampaigns(
    RefreshInfluencerCampaigns event,
    Emitter<InfluencerCampaignsState> emit,
  ) async {
    print('🔄 === REFRESHING INFLUENCER CAMPAIGNS ===');

    emit(InfluencerCampaignsLoading());

    try {
      final result = await InfluencersService.getInfluencerCampaigns(
        status: event.status,
        page: 1,
        limit: 10,
      );

      if (result['success'] == true) {
        final campaigns = List<dynamic>.from(result['data'] ?? []);
        final total = result['total'] ?? 0;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;

        print('✅ Refreshed ${campaigns.length} campaigns');

        emit(InfluencerCampaignsLoaded(
          campaigns: campaigns,
          message: result['message'] ?? 'Campaigns refreshed successfully',
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          currentStatus: event.status,
          currentSearch: event.search,
          total: total,
          totalPages: totalPages,
        ));
      } else {
        print('❌ Refresh failed: ${result['message']}');
        emit(InfluencerCampaignsError(
            BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(InfluencerCampaignsError(
          BlocErrorHelper.messageFrom(e, st, 'refreshInfluencerCampaigns')));
    }
  }

  Future<void> _onFilterCampaigns(
    FilterInfluencerCampaigns event,
    Emitter<InfluencerCampaignsState> emit,
  ) async {
    print('🔍 === FILTERING INFLUENCER CAMPAIGNS ===');
    print('🔍 Filter Status: ${event.status}');

    emit(InfluencerCampaignsLoading());

    try {
      final result = await InfluencersService.getInfluencerCampaigns(
        status: event.status,
        page: 1,
        limit: 10,
      );

      if (result['success'] == true) {
        final campaigns = List<dynamic>.from(result['data'] ?? []);
        final total = result['total'] ?? 0;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;

        print(
            '✅ Filtered ${campaigns.length} campaigns for status: ${event.status}');

        emit(InfluencerCampaignsLoaded(
          campaigns: campaigns,
          message: result['message'] ?? 'Campaigns filtered successfully',
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          currentStatus: event.status,
          currentSearch: null,
          total: total,
          totalPages: totalPages,
        ));
      } else {
        print('❌ Filter failed: ${result['message']}');
        emit(InfluencerCampaignsError(
            BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(InfluencerCampaignsError(
          BlocErrorHelper.messageFrom(e, st, 'filterInfluencerCampaigns')));
    }
  }
}
