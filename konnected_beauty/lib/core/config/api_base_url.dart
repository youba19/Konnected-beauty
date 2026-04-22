/// Central API origin. Toggle for local/ngrok testing; set [useDevTunnel] to
/// `false` before production / store builds.
class ApiBaseUrl {
  ApiBaseUrl._();

  /// TEMPORARY — set to `false` when pointing back to production.
  static const bool useDevTunnel = false;

  static const String _production = 'https://server.konectedbeauty.com';
  static const String _devTunnel =
      'https://5326-105-235-131-197.ngrok-free.app';

  static String get value => useDevTunnel ? _devTunnel : _production;

  /// Ngrok free tier returns an HTML interstitial unless this header is set.
  static Map<String, String> mergeRequestHeaders([
    Map<String, String>? headers,
  ]) {
    final h = Map<String, String>.from(headers ?? const {});
    if (useDevTunnel) {
      h.putIfAbsent('ngrok-skip-browser-warning', () => 'true');
    }
    return h;
  }
}
