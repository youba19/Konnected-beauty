abstract class SalonPaymentInformationEvent {
  const SalonPaymentInformationEvent();
}

class UpdateSalonPaymentInformation extends SalonPaymentInformationEvent {
  final String businessName;
  final String registryNumber;
  final String iban;

  const UpdateSalonPaymentInformation({
    required this.businessName,
    required this.registryNumber,
    required this.iban,
  });
}
