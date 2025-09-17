abstract class SalonDetailsEvent {}

class LoadSalonDetails extends SalonDetailsEvent {
  final String salonId;
  final String? salonName;
  final String? salonDomain;
  final String? salonAddress;

  LoadSalonDetails(this.salonId,
      {this.salonName, this.salonDomain, this.salonAddress});
}

class RefreshSalonDetails extends SalonDetailsEvent {
  final String salonId;
  final String? salonName;
  final String? salonDomain;
  final String? salonAddress;

  RefreshSalonDetails(this.salonId,
      {this.salonName, this.salonDomain, this.salonAddress});
}
