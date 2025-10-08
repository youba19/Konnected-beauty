abstract class InfluencerAccountDeletionEvent {}

class RequestInfluencerAccountDeletion extends InfluencerAccountDeletionEvent {
  final String reason;

  RequestInfluencerAccountDeletion({required this.reason});
}
