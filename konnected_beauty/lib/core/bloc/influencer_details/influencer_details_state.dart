abstract class InfluencerDetailsState {}

class InfluencerDetailsInitial extends InfluencerDetailsState {}

class InfluencerDetailsLoading extends InfluencerDetailsState {}

class InfluencerDetailsLoaded extends InfluencerDetailsState {
  final Map<String, dynamic> influencerData;

  InfluencerDetailsLoaded({required this.influencerData});
}

class InfluencerDetailsError extends InfluencerDetailsState {
  final String message;

  InfluencerDetailsError({required this.message});
}
