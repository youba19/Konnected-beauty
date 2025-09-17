import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_details_service.dart';
import 'salon_details_event.dart';
import 'salon_details_state.dart';

class SalonDetailsBloc extends Bloc<SalonDetailsEvent, SalonDetailsState> {
  SalonDetailsBloc() : super(SalonDetailsInitial()) {
    on<LoadSalonDetails>(_onLoadSalonDetails);
    on<RefreshSalonDetails>(_onRefreshSalonDetails);
  }

  Future<void> _onLoadSalonDetails(
    LoadSalonDetails event,
    Emitter<SalonDetailsState> emit,
  ) async {
    print('🏢 === LOADING SALON DETAILS ===');
    print('🏢 Salon ID: ${event.salonId}');

    emit(SalonDetailsLoading());

    try {
      final result = await SalonDetailsService.getSalonDetails(
        event.salonId,
        salonName: event.salonName,
        salonDomain: event.salonDomain,
        salonAddress: event.salonAddress,
      );

      if (result['success'] == true) {
        print('✅ Salon details loaded successfully');
        emit(SalonDetailsLoaded(result['data']));
      } else {
        print('❌ Failed to load salon details: ${result['message']}');
        emit(SalonDetailsError(
            result['message'] ?? 'Failed to load salon details'));
      }
    } catch (e) {
      print('❌ Error loading salon details: $e');
      emit(SalonDetailsError('Error loading salon details: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshSalonDetails(
    RefreshSalonDetails event,
    Emitter<SalonDetailsState> emit,
  ) async {
    print('🔄 === REFRESHING SALON DETAILS ===');
    print('🔄 Salon ID: ${event.salonId}');

    emit(SalonDetailsLoading());

    try {
      final result = await SalonDetailsService.getSalonDetails(
        event.salonId,
        salonName: event.salonName,
        salonDomain: event.salonDomain,
        salonAddress: event.salonAddress,
      );

      if (result['success'] == true) {
        print('✅ Salon details refreshed successfully');
        emit(SalonDetailsLoaded(result['data']));
      } else {
        print('❌ Failed to refresh salon details: ${result['message']}');
        emit(SalonDetailsError(
            result['message'] ?? 'Failed to refresh salon details'));
      }
    } catch (e) {
      print('❌ Error refreshing salon details: $e');
      emit(
          SalonDetailsError('Error refreshing salon details: ${e.toString()}'));
    }
  }
}
