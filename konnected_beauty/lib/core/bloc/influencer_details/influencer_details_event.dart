abstract class InfluencerDetailsEvent {}

class LoadInfluencerDetails extends InfluencerDetailsEvent {
  final String influencerId;

  LoadInfluencerDetails({required this.influencerId});
}

class RefreshInfluencerDetails extends InfluencerDetailsEvent {
  final String influencerId;

  RefreshInfluencerDetails({required this.influencerId});
}
