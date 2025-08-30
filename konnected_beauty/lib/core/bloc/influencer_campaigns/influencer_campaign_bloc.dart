import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class InfluencerCampaignEvent {}

class LoadInfluencerCampaigns extends InfluencerCampaignEvent {}

class AcceptCampaign extends InfluencerCampaignEvent {
  final String campaignId;
  AcceptCampaign(this.campaignId);
}

class RefuseCampaign extends InfluencerCampaignEvent {
  final String campaignId;
  RefuseCampaign(this.campaignId);
}

class CopyCampaignLink extends InfluencerCampaignEvent {
  final String campaignId;
  CopyCampaignLink(this.campaignId);
}

// States
abstract class InfluencerCampaignState {}

class InfluencerCampaignInitial extends InfluencerCampaignState {}

class InfluencerCampaignLoading extends InfluencerCampaignState {}

class InfluencerCampaignLoaded extends InfluencerCampaignState {
  final List<Map<String, dynamic>> campaigns;
  InfluencerCampaignLoaded(this.campaigns);
}

class InfluencerCampaignError extends InfluencerCampaignState {
  final String message;
  InfluencerCampaignError(this.message);
}

class CampaignActionSuccess extends InfluencerCampaignState {
  final String message;
  final List<Map<String, dynamic>> campaigns;
  CampaignActionSuccess(this.message, this.campaigns);
}

// BLoC
class InfluencerCampaignBloc
    extends Bloc<InfluencerCampaignEvent, InfluencerCampaignState> {
  InfluencerCampaignBloc() : super(InfluencerCampaignInitial()) {
    on<LoadInfluencerCampaigns>(_onLoadInfluencerCampaigns);
    on<AcceptCampaign>(_onAcceptCampaign);
    on<RefuseCampaign>(_onRefuseCampaign);
    on<CopyCampaignLink>(_onCopyCampaignLink);
  }

  // Mock data for demonstration - replace with actual API call
  final List<Map<String, dynamic>> _mockCampaigns = [
    {
      'id': '1',
      'saloonName': 'Elegance Salon',
      'createdAt': '14/07/2025',
      'status': 'waiting for you',
      'promotionType': 'Pourcentage',
      'promotionValue': '20%',
      'message': 'Salut Perdo! Accepter svp!',
      'clicks': 0,
      'completedOrders': 0,
      'total': '0 EUR',
    },
    {
      'id': '2',
      'saloonName': 'Beauty Studio',
      'createdAt': '15/07/2025',
      'status': 'on going',
      'promotionType': 'Fixed Amount',
      'promotionValue': '50 EUR',
      'message': 'Great collaboration opportunity!',
      'clicks': 1250,
      'completedOrders': 35,
      'total': '1,750 EUR',
    },
    {
      'id': '3',
      'saloonName': 'Glamour Place',
      'createdAt': '10/07/2025',
      'status': 'finished',
      'promotionType': 'Pourcentage',
      'promotionValue': '15%',
      'message': 'Thank you for the amazing collaboration!',
      'clicks': 5420,
      'completedOrders': 120,
      'total': '3,600 EUR',
    },
  ];

  Future<void> _onLoadInfluencerCampaigns(
    LoadInfluencerCampaigns event,
    Emitter<InfluencerCampaignState> emit,
  ) async {
    emit(InfluencerCampaignLoading());

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // TODO: Replace with actual API call
      // final campaigns = await InfluencerCampaignService.getCampaigns();

      emit(InfluencerCampaignLoaded(_mockCampaigns));
    } catch (e) {
      emit(
          InfluencerCampaignError('Failed to load campaigns: ${e.toString()}'));
    }
  }

  Future<void> _onAcceptCampaign(
    AcceptCampaign event,
    Emitter<InfluencerCampaignState> emit,
  ) async {
    try {
      // TODO: Replace with actual API call
      // await InfluencerCampaignService.acceptCampaign(event.campaignId);

      // Update campaign status in mock data
      final updatedCampaigns = _mockCampaigns.map((campaign) {
        if (campaign['id'] == event.campaignId) {
          return {...campaign, 'status': 'on going'};
        }
        return campaign;
      }).toList();

      // Update the mock data for future requests
      _mockCampaigns.clear();
      _mockCampaigns.addAll(updatedCampaigns);

      emit(CampaignActionSuccess(
          'Campaign accepted successfully!', updatedCampaigns));
    } catch (e) {
      emit(InfluencerCampaignError(
          'Failed to accept campaign: ${e.toString()}'));
    }
  }

  Future<void> _onRefuseCampaign(
    RefuseCampaign event,
    Emitter<InfluencerCampaignState> emit,
  ) async {
    try {
      // TODO: Replace with actual API call
      // await InfluencerCampaignService.refuseCampaign(event.campaignId);

      // Remove campaign from mock data
      final updatedCampaigns = _mockCampaigns
          .where((campaign) => campaign['id'] != event.campaignId)
          .toList();

      // Update the mock data for future requests
      _mockCampaigns.clear();
      _mockCampaigns.addAll(updatedCampaigns);

      emit(CampaignActionSuccess(
          'Campaign refused successfully!', updatedCampaigns));
    } catch (e) {
      emit(InfluencerCampaignError(
          'Failed to refuse campaign: ${e.toString()}'));
    }
  }

  Future<void> _onCopyCampaignLink(
    CopyCampaignLink event,
    Emitter<InfluencerCampaignState> emit,
  ) async {
    try {
      // TODO: Replace with actual API call to get campaign link
      // final link = await InfluencerCampaignService.getCampaignLink(event.campaignId);

      // For now, just emit success
      final currentCampaigns = state is InfluencerCampaignLoaded
          ? (state as InfluencerCampaignLoaded).campaigns
          : _mockCampaigns;

      emit(CampaignActionSuccess(
          'Campaign link copied to clipboard!', currentCampaigns));
    } catch (e) {
      emit(InfluencerCampaignError(
          'Failed to copy campaign link: ${e.toString()}'));
    }
  }
}
