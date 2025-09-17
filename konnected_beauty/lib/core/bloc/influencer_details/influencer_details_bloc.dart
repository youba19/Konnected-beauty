import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencers_service.dart';
import 'influencer_details_event.dart';
import 'influencer_details_state.dart';

class InfluencerDetailsBloc
    extends Bloc<InfluencerDetailsEvent, InfluencerDetailsState> {
  InfluencerDetailsBloc() : super(InfluencerDetailsInitial()) {
    on<LoadInfluencerDetails>(_onLoadInfluencerDetails);
    on<RefreshInfluencerDetails>(_onRefreshInfluencerDetails);
  }

  Future<void> _onLoadInfluencerDetails(
    LoadInfluencerDetails event,
    Emitter<InfluencerDetailsState> emit,
  ) async {
    print('👤 === LOADING INFLUENCER DETAILS ===');
    print('🆔 Influencer ID: ${event.influencerId}');

    emit(InfluencerDetailsLoading());

    try {
      final result =
          await InfluencersService.getInfluencerDetails(event.influencerId);

      print('🔍 === INFLUENCER DETAILS BLOC RESULT ===');
      print('🔍 Success: ${result['success']}');
      print('🔍 Message: ${result['message']}');
      print('🔍 Status Code: ${result['statusCode']}');
      print('🔍 Data: ${result['data']}');
      print('🔍 === END INFLUENCER DETAILS BLOC RESULT ===');

      if (result['success'] == true) {
        print('✅ Influencer details loaded successfully');
        emit(InfluencerDetailsLoaded(influencerData: result['data']));
      } else {
        print('❌ Failed to load influencer details: ${result['message']}');
        emit(InfluencerDetailsError(
            message: result['message'] ?? 'Failed to load influencer details'));
      }
    } catch (e) {
      print('❌ Exception in _onLoadInfluencerDetails: $e');
      emit(InfluencerDetailsError(
          message: 'Error loading influencer details: $e'));
    }
  }

  Future<void> _onRefreshInfluencerDetails(
    RefreshInfluencerDetails event,
    Emitter<InfluencerDetailsState> emit,
  ) async {
    print('🔄 === REFRESHING INFLUENCER DETAILS ===');
    print('🆔 Influencer ID: ${event.influencerId}');

    emit(InfluencerDetailsLoading());

    try {
      final result =
          await InfluencersService.getInfluencerDetails(event.influencerId);

      print('🔍 === REFRESH INFLUENCER DETAILS BLOC RESULT ===');
      print('🔍 Success: ${result['success']}');
      print('🔍 Message: ${result['message']}');
      print('🔍 Status Code: ${result['statusCode']}');
      print('🔍 Data: ${result['data']}');
      print('🔍 === END REFRESH INFLUENCER DETAILS BLOC RESULT ===');

      if (result['success'] == true) {
        print('✅ Influencer details refreshed successfully');
        emit(InfluencerDetailsLoaded(influencerData: result['data']));
      } else {
        print('❌ Failed to refresh influencer details: ${result['message']}');
        emit(InfluencerDetailsError(
            message:
                result['message'] ?? 'Failed to refresh influencer details'));
      }
    } catch (e) {
      print('❌ Exception in _onRefreshInfluencerDetails: $e');
      emit(InfluencerDetailsError(
          message: 'Error refreshing influencer details: $e'));
    }
  }
}
