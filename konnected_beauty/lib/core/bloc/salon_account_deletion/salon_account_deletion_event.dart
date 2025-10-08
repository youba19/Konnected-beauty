abstract class SalonAccountDeletionEvent {}

class RequestSalonAccountDeletion extends SalonAccountDeletionEvent {
  final String reason;

  RequestSalonAccountDeletion({required this.reason});
}
