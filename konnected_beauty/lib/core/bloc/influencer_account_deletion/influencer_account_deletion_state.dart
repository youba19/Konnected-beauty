abstract class InfluencerAccountDeletionState {}

class InfluencerAccountDeletionInitial extends InfluencerAccountDeletionState {}

class InfluencerAccountDeletionLoading extends InfluencerAccountDeletionState {}

class InfluencerAccountDeletionSuccess extends InfluencerAccountDeletionState {
  final String message;

  InfluencerAccountDeletionSuccess({required this.message});
}

class InfluencerAccountDeletionError extends InfluencerAccountDeletionState {
  final String message;

  InfluencerAccountDeletionError({required this.message});
}
