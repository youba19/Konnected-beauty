import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';
import '../bloc_error_helper.dart';
import 'campaigns_event.dart';
import 'campaigns_state.dart';

class CampaignsBloc extends Bloc<CampaignsEvent, CampaignsState> {
  CampaignsBloc() : super(CampaignsInitial()) {
    on<LoadCampaigns>(_onLoadCampaigns);
    on<LoadMoreCampaigns>(_onLoadMoreCampaigns);
    on<RefreshCampaigns>(_onRefreshCampaigns);
    on<DeleteCampaign>(_onDeleteCampaign);
  }

  Future<void> _onLoadCampaigns(
    LoadCampaigns event,
    Emitter<CampaignsState> emit,
  ) async {
    print('📊 === LOADING CAMPAIGNS ===');
    print('📄 Page: ${event.page}');
    print('📏 Limit: ${event.limit}');
    print('🔍 Search: "${event.search ?? 'None'}"');
    print('🔍 Search Type: ${event.search.runtimeType}');
    print('🔍 Search Length: ${event.search?.length ?? 0}');
    print('🔍 Search Is Empty: ${event.search?.isEmpty ?? true}');
    print('📊 Status: ${event.status ?? 'None'}');

    // Check if this is pagination (page > 1)
    final isPagination = event.page > 1;

    // If it's pagination, don't show loading state to avoid UI flicker
    if (!isPagination) {
      emit(CampaignsLoading());
    }

    try {
      final result = await InfluencersService.getSalonCampaigns(
        page: event.page,
        limit: event.limit,
        search: event.search,
        status: event.status,
      );

      print('🔍 === CAMPAIGNS BLOC RESULT ===');
      print('🔍 Success: ${result['success']}');
      print('🔍 Message: ${result['message']}');
      print('🔍 Status Code: ${result['statusCode']}');
      print('🔍 Data: ${result['data']}');
      print('🔍 === END CAMPAIGNS BLOC RESULT ===');

      if (result['success'] == true) {
        final newCampaigns =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final total = int.tryParse(result['total']?.toString() ?? '0') ?? 0;
        final hasMoreData = currentPage < totalPages;

        print('✅ Campaigns loaded successfully');
        print('📊 Total: $total');
        print('📄 Current Page: $currentPage');
        print('📄 Total Pages: $totalPages');
        print('🔄 Has More Data: $hasMoreData');

        // Debug: Show search term and returned campaigns
        if (event.search != null && event.search!.isNotEmpty) {
          print('🔍 === SEARCH DEBUG ===');
          print('🔍 Search Term: "${event.search}"');
          print('🔍 Campaigns Returned: ${newCampaigns.length}');
          print('🔍 Total from API: $total');
          print('🔍 Expected: Should be filtered results, not all campaigns');

          bool hasAnyMatch = false;
          for (int i = 0; i < newCampaigns.length; i++) {
            final campaign = newCampaigns[i];
            final pseudo =
                campaign['influencer']?['profile']?['pseudo'] ?? 'N/A';
            final bio = campaign['influencer']?['profile']?['bio'] ?? 'N/A';
            final zone = campaign['influencer']?['profile']?['zone'] ?? 'N/A';
            final message = campaign['invitationMessage'] ?? 'N/A';

            print('🔍 Campaign ${i + 1}:');
            print('🔍   Pseudo: "$pseudo"');
            print('🔍   Bio: "$bio"');
            print('🔍   Zone: "$zone"');
            print('🔍   Message: "$message"');

            // Check if search term matches any field
            final searchLower = event.search!.toLowerCase();
            final matchesPseudo = pseudo.toLowerCase().contains(searchLower);
            final matchesBio = bio.toLowerCase().contains(searchLower);
            final matchesZone = zone.toLowerCase().contains(searchLower);
            final matchesMessage = message.toLowerCase().contains(searchLower);

            print('🔍   Matches Pseudo: $matchesPseudo');
            print('🔍   Matches Bio: $matchesBio');
            print('🔍   Matches Zone: $matchesZone');
            print('🔍   Matches Message: $matchesMessage');

            if (matchesPseudo || matchesBio || matchesZone || matchesMessage) {
              hasAnyMatch = true;
            }
            print('🔍   ---');
          }

          print('🔍 === SEARCH ANALYSIS ===');
          print('🔍 Has any matching campaign: $hasAnyMatch');
          if (!hasAnyMatch && newCampaigns.isNotEmpty) {
            print(
                '❌ PROBLEM: API returned ${newCampaigns.length} campaigns but NONE match the search term "${event.search}"');
            print(
                '❌ This confirms the API is NOT filtering by search parameter');
            print('✅ Solution: Using client-side filtering to fix this issue');
          } else if (hasAnyMatch) {
            print('✅ Found matching campaigns in API response');
            print('✅ Client-side filtering will show only matching campaigns');
          }
          print('🔍 === END SEARCH DEBUG ===');
        }

        // Apply client-side search filtering if search parameter exists
        List<Map<String, dynamic>> filteredCampaigns = newCampaigns;
        if (event.search != null && event.search!.isNotEmpty) {
          print('🔍 === APPLYING CLIENT-SIDE SEARCH FILTER ===');
          print('🔍 Search Term: "${event.search}"');
          print('🔍 Campaigns before filtering: ${newCampaigns.length}');

          final searchLower = event.search!.toLowerCase();
          filteredCampaigns = newCampaigns.where((campaign) {
            final pseudo = (campaign['influencer']?['profile']?['pseudo'] ?? '')
                .toString()
                .toLowerCase();
            final bio = (campaign['influencer']?['profile']?['bio'] ?? '')
                .toString()
                .toLowerCase();
            final zone = (campaign['influencer']?['profile']?['zone'] ?? '')
                .toString()
                .toLowerCase();
            final message =
                (campaign['invitationMessage'] ?? '').toString().toLowerCase();

            return pseudo.contains(searchLower) ||
                bio.contains(searchLower) ||
                zone.contains(searchLower) ||
                message.contains(searchLower);
          }).toList();

          print('🔍 Campaigns after filtering: ${filteredCampaigns.length}');
          print('🔍 === END CLIENT-SIDE SEARCH FILTER ===');
        }

        // If this is pagination, append to existing list
        List<Map<String, dynamic>> finalCampaigns;
        if (isPagination) {
          final currentState = state;
          if (currentState is CampaignsLoaded) {
            finalCampaigns = List.from(currentState.campaigns)
              ..addAll(filteredCampaigns);
            print(
                '📄 Appending ${filteredCampaigns.length} new campaigns to existing ${currentState.campaigns.length}');
          } else {
            finalCampaigns = filteredCampaigns;
          }
        } else {
          finalCampaigns = filteredCampaigns;
        }

        emit(CampaignsLoaded(
          campaigns: finalCampaigns,
          currentPage: currentPage,
          totalPages: totalPages,
          total: total,
          hasMore: hasMoreData,
          currentSearch: event.search,
          currentStatus: event.status,
        ));
      } else {
        print('❌ Failed to load campaigns: ${result['message']}');
        emit(CampaignsError(
            message: BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(CampaignsError(
          message: BlocErrorHelper.messageFrom(e, st, 'loadCampaigns')));
    }
  }

  Future<void> _onLoadMoreCampaigns(
    LoadMoreCampaigns event,
    Emitter<CampaignsState> emit,
  ) async {
    print('📄 === BLOC: LOAD MORE CAMPAIGNS ===');
    print('📄 Requested Page: ${event.page}');
    print('📄 Search: ${event.search}');
    print('📄 Status: ${event.status}');

    // Capture the current state BEFORE emitting any intermediate loading state
    final CampaignsState previousStateSnapshot = state;

    try {
      final result = await InfluencersService.getSalonCampaigns(
        page: event.page,
        limit: event.limit,
        search: event.search,
        status: event.status,
      );

      print('📄 === LOAD MORE RESULT ===');
      print('📄 Success: ${result['success']}');
      print('📄 New Campaigns Count: ${result['data']?.length ?? 0}');

      if (result['success'] == true) {
        final newCampaigns =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final totalPages = result['totalPages'] ?? 1;
        final total = result['total'] ?? 0;

        // Use the previous loaded state snapshot to append new campaigns
        if (previousStateSnapshot is CampaignsLoaded) {
          final currentState = previousStateSnapshot;

          // Append all campaigns but limit to the total specified by API
          final allCampaigns = [...currentState.campaigns, ...newCampaigns];

          // Limit campaigns to exactly match the total from API
          final limitedCampaigns = allCampaigns.take(total).toList();

          // Use total and totalPages attributes from API to control pagination
          // Stop when we reach the total number of campaigns or total pages
          final bool hasReachedTotal = limitedCampaigns.length >= total;
          final bool hasReachedTotalPages = event.page >= totalPages;
          final bool hasMoreData = !hasReachedTotal && !hasReachedTotalPages;

          print('📄 === UPDATING STATE ===');
          print(
              '📄 Previous Campaigns Count: ${currentState.campaigns.length}');
          print('📄 New Campaigns Count: ${newCampaigns.length}');
          print('📄 All Campaigns Count: ${allCampaigns.length}');
          print('📄 Limited Campaigns Count: ${limitedCampaigns.length}');
          print('📄 New Current Page: ${event.page}');
          print('📄 Total Pages (from API): $totalPages');
          print('📄 Total Campaigns (from API): $total');
          print('📄 Has Reached Total: $hasReachedTotal');
          print('📄 Has Reached Total Pages: $hasReachedTotalPages');
          print('📄 New Has More Data: $hasMoreData');

          emit(CampaignsLoaded(
            campaigns: limitedCampaigns,
            currentPage: event.page,
            totalPages: totalPages,
            total: total,
            hasMore: hasMoreData,
            currentSearch: event.search,
            currentStatus: event.status,
          ));
        } else {
          print(
              '📄 ❌ Previous state is not CampaignsLoaded: ${previousStateSnapshot.runtimeType}');
        }
      } else {
        print('❌ Failed to load more campaigns: ${result['message']}');
        emit(CampaignsError(
            message: BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(CampaignsError(
          message: BlocErrorHelper.messageFrom(e, st, 'loadMoreCampaigns')));
    }
  }

  Future<void> _onRefreshCampaigns(
    RefreshCampaigns event,
    Emitter<CampaignsState> emit,
  ) async {
    print('🔄 === REFRESHING CAMPAIGNS ===');
    print('📄 Page: ${event.page}');
    print('📏 Limit: ${event.limit}');
    print('🔍 Search: ${event.search ?? 'None'}');
    print('📊 Status: ${event.status ?? 'None'}');

    emit(CampaignsLoading());

    try {
      // If limit is high (>= 50), try to fetch all campaigns across multiple pages
      if (event.limit >= 50) {
        print('📄 === USING MULTI-PAGE FETCH STRATEGY (REFRESH) ===');
        await _fetchAllCampaigns(
            LoadCampaigns(
              page: event.page,
              limit: event.limit,
              search: event.search,
              status: event.status,
            ),
            emit);
        return;
      }

      // Use normal pagination for smaller limits
      print('📄 === USING NORMAL PAGINATION (REFRESH) ===');
      print('📄 Page: ${event.page}');
      print('📏 Limit: ${event.limit}');
      print('🔍 Search: ${event.search ?? 'None'}');
      print('📊 Status: ${event.status ?? 'None'}');

      final result = await InfluencersService.getSalonCampaigns(
        page: event.page,
        limit: event.limit,
        search: event.search,
        status: event.status,
      );

      print('🔍 === REFRESH CAMPAIGNS BLOC RESULT ===');
      print('🔍 Success: ${result['success']}');
      print('🔍 Message: ${result['message']}');
      print('🔍 Status Code: ${result['statusCode']}');
      print('🔍 Data: ${result['data']}');
      print('🔍 === END REFRESH CAMPAIGNS BLOC RESULT ===');

      if (result['success'] == true) {
        final campaigns =
            List<Map<String, dynamic>>.from(result['data'] ?? []);
        final currentPage =
            int.tryParse(result['currentPage']?.toString() ?? '1') ?? 1;
        final totalPages =
            int.tryParse(result['totalPages']?.toString() ?? '1') ?? 1;
        final total = int.tryParse(result['total']?.toString() ?? '0') ?? 0;

        // Check if we have more data based on actual total vs current count
        final bool hasMoreData = campaigns.length < total;

        print('✅ Campaigns refreshed successfully');
        print('📊 Total Campaigns: ${campaigns.length}');
        print('📄 Current Page: $currentPage');
        print('📄 Total Pages: $totalPages');
        print('📄 Has More Data: $hasMoreData');

        emit(CampaignsLoaded(
          campaigns: campaigns,
          currentPage: currentPage,
          totalPages: totalPages,
          total: total,
          hasMore: hasMoreData,
        ));
      } else {
        print('❌ Failed to refresh campaigns: ${result['message']}');
        emit(CampaignsError(
            message: BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(CampaignsError(
          message: BlocErrorHelper.messageFrom(e, st, 'refreshCampaigns')));
    }
  }

  Future<void> _onDeleteCampaign(
    DeleteCampaign event,
    Emitter<CampaignsState> emit,
  ) async {
    print('🗑️ === DELETING CAMPAIGN ===');
    print('🆔 Campaign ID: ${event.campaignId}');

    try {
      final result = await InfluencersService.deleteCampaignInvite(
        campaignId: event.campaignId,
      );

      print('🔍 === DELETE CAMPAIGN BLOC RESULT ===');
      print('🔍 Success: ${result['success']}');
      print('🔍 Message: ${result['message']}');
      print('🔍 Status Code: ${result['statusCode']}');
      print('🔍 Data: ${result['data']}');
      print('🔍 === END DELETE CAMPAIGN BLOC RESULT ===');

      if (result['success'] == true) {
        print('✅ Campaign deleted successfully');
        emit(CampaignDeleted(message: 'Campaign deleted successfully'));
      } else {
        print('❌ Failed to delete campaign: ${result['message']}');
        emit(CampaignsError(
            message: BlocErrorHelper.messageFromApiMap(result),
            statusCode: result['statusCode']));
      }
    } catch (e, st) {
      emit(CampaignsError(
          message: BlocErrorHelper.messageFrom(e, st, 'deleteCampaign')));
    }
  }

  Future<void> _fetchAllCampaigns(
    LoadCampaigns event,
    Emitter<CampaignsState> emit,
  ) async {
    print('🔄 === STARTING MULTI-PAGE FETCH ===');

    List<Map<String, dynamic>> allCampaigns = [];
    int currentPage = 1;
    int totalPages = 1;
    int total = 0;
    bool hasMore = true;

    try {
      while (hasMore && currentPage <= 10) {
        // Safety limit of 10 pages
        print('🔄 === FETCHING PAGE $currentPage ===');

        final result = await InfluencersService.getSalonCampaigns(
          page: currentPage,
          limit: 10, // Use normal page size
          search: event.search,
          status: event.status,
        );

        if (result['success'] == true) {
          final campaigns =
              List<Map<String, dynamic>>.from(result['data'] ?? []);
          totalPages = result['totalPages'] ?? 1;
          total = result['total'] ?? 0;

          print('📄 Page $currentPage: ${campaigns.length} campaigns');
          print('📄 Total Pages: $totalPages');
          print('📄 API Total: $total');

          // Check for duplicates
          final existingIds = allCampaigns.map((c) => c['id']).toSet();
          final newIds = campaigns.map((c) => c['id']).toSet();
          final duplicates = existingIds.intersection(newIds);

          if (duplicates.isNotEmpty) {
            print('⚠️ DUPLICATES DETECTED ON PAGE $currentPage: $duplicates');
            // Filter out duplicates
            final uniqueNewCampaigns =
                campaigns.where((c) => !existingIds.contains(c['id'])).toList();
            print('📄 Unique new campaigns: ${uniqueNewCampaigns.length}');
            allCampaigns.addAll(uniqueNewCampaigns);
          } else {
            allCampaigns.addAll(campaigns);
          }

          hasMore = currentPage < totalPages;
          currentPage++;

          print('📊 Total campaigns so far: ${allCampaigns.length}');

          // If we got all duplicates, stop fetching
          if (campaigns.isNotEmpty && duplicates.length == campaigns.length) {
            print(
                '🛑 All campaigns on page $currentPage were duplicates, stopping');
            break;
          }
        } else {
          print('❌ Failed to fetch page $currentPage: ${result['message']}');
          break;
        }
      }

      print('✅ === MULTI-PAGE FETCH COMPLETE ===');
      print('📊 Total Campaigns Fetched: ${allCampaigns.length}');
      print('📄 Pages Fetched: ${currentPage - 1}');
      print('📄 API Total: $total');

      emit(CampaignsLoaded(
        campaigns: allCampaigns,
        currentPage: currentPage - 1,
        totalPages: totalPages,
        total: total,
        hasMore: false, // We fetched everything
      ));
    } catch (e, st) {
      emit(CampaignsError(
          message: BlocErrorHelper.messageFrom(e, st, 'fetchAllCampaigns')));
    }
  }
}
