abstract class InviteSalonEvent {}

class InviteSalon extends InviteSalonEvent {
  final String receiverId;
  final int promotion;
  final String promotionType;
  final String invitationMessage;

  InviteSalon({
    required this.receiverId,
    required this.promotion,
    required this.promotionType,
    required this.invitationMessage,
  });
}
