abstract class SalonPaymentInformationState {
  const SalonPaymentInformationState();
}

class SalonPaymentInformationInitial extends SalonPaymentInformationState {}

class SalonPaymentInformationLoading extends SalonPaymentInformationState {}

class SalonPaymentInformationSuccess extends SalonPaymentInformationState {
  final String message;

  const SalonPaymentInformationSuccess({required this.message});
}

class SalonPaymentInformationError extends SalonPaymentInformationState {
  final String message;

  const SalonPaymentInformationError({required this.message});
}
