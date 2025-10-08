abstract class SalonAccountDeletionState {}

class SalonAccountDeletionInitial extends SalonAccountDeletionState {}

class SalonAccountDeletionLoading extends SalonAccountDeletionState {}

class SalonAccountDeletionSuccess extends SalonAccountDeletionState {
  final String message;

  SalonAccountDeletionSuccess({required this.message});
}

class SalonAccountDeletionError extends SalonAccountDeletionState {
  final String message;

  SalonAccountDeletionError({required this.message});
}
