abstract class SalonDetailsState {}

class SalonDetailsInitial extends SalonDetailsState {}

class SalonDetailsLoading extends SalonDetailsState {}

class SalonDetailsLoaded extends SalonDetailsState {
  final Map<String, dynamic> salonDetails;

  SalonDetailsLoaded(this.salonDetails);
}

class SalonDetailsError extends SalonDetailsState {
  final String message;

  SalonDetailsError(this.message);
}
