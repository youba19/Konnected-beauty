/// Shared parsing for API errors when Stripe Express is not linked (e.g. HTTP/body 499, `messgae` typo).
class StripeLinkError {
  StripeLinkError._();

  static int? parseStatusCode(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static String messageFrom(Map<String, dynamic> data) {
    final raw = data['message'] ?? data['messgae'];
    if (raw == null) return '';
    return raw.toString();
  }

  static bool isAccountNotLinked(String msg, int? code) {
    final m = msg.toLowerCase();
    if (code == 499) return true;
    return m.contains('stripe') &&
        (m.contains('not linked') || m.contains('account id'));
  }
}
