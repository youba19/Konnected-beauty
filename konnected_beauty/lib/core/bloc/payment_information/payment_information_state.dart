abstract class PaymentInformationState {}

class PaymentInformationInitial extends PaymentInformationState {}

class PaymentInformationLoading extends PaymentInformationState {}

class PaymentInformationSuccess extends PaymentInformationState {
  final String message;

  PaymentInformationSuccess({required this.message});
}

class PaymentInformationError extends PaymentInformationState {
  final String message;

  PaymentInformationError({required this.message});
}
