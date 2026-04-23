abstract class InviteSalonState {}

class InviteSalonInitial extends InviteSalonState {}

class InviteSalonLoading extends InviteSalonState {}

class InviteSalonSuccess extends InviteSalonState {
  final Map<String, dynamic> invitationData;
  final String message;

  InviteSalonSuccess({
    required this.invitationData,
    required this.message,
  });
}

class InviteSalonError extends InviteSalonState {
  final String message;
  /// True when API returns 499 / Stripe account not linked (invite blocked).
  final bool stripeAccountNotLinked;

  InviteSalonError(
    this.message, {
    this.stripeAccountNotLinked = false,
  });
}
