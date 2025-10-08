abstract class PaymentInformationEvent {}

class UpdatePaymentInformation extends PaymentInformationEvent {
  final String businessName;
  final String registryNumber;
  final String iban;

  UpdatePaymentInformation({
    required this.businessName,
    required this.registryNumber,
    required this.iban,
  });
}
