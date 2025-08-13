import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  /// Save access token
  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Save user email
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Save user role
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Save all authentication data
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String email,
    required String role,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserEmail(email),
      saveUserRole(role),
    ]);
  }

  /// Clear all authentication data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userEmailKey),
      prefs.remove(_userRoleKey),
    ]);
    
    print('🧹 === AUTH DATA CLEARED ===');
    print('🧹 All tokens and user data removed');
    print('🧹 === END CLEARED ===');
  }

  /// Clear all app data (for logout)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    print('🧹 === ALL APP DATA CLEARED ===');
    print('🧹 Complete app reset - all data removed');
    print('🧹 === END CLEARED ===');
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Check if access token is expired
  static Future<bool> isAccessTokenExpired() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      print('🔍 Token expiry check: No access token found');
      return true;
    }

    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        print('🔍 Token expiry check: Invalid token format');
        return true;
      }

      final payload = parts[1];
      final paddedPayload = payload + '=' * (4 - payload.length % 4);
      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      final payloadMap = json.decode(decodedPayload);

      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(payloadMap['exp'] * 1000);
      final now = DateTime.now();

      print('🔍 Token expiry check:');
      print('   📅 Expires at: $expiresAt');
      print('   🕐 Current time: $now');
      print('   ⏰ Is expired: ${now.isAfter(expiresAt)}');

      return now.isAfter(expiresAt);
    } catch (e) {
      print('❌ Error checking token expiry: $e');
      return true;
    }
  }

  /// Check if refresh token is expired
  static Future<bool> isRefreshTokenExpired() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return true;

    try {
      final parts = refreshToken.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final paddedPayload = payload + '=' * (4 - payload.length % 4);
      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      final payloadMap = json.decode(decodedPayload);

      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(payloadMap['exp'] * 1000);
      final now = DateTime.now();

      return now.isAfter(expiresAt);
    } catch (e) {
      print('❌ Error checking refresh token expiry: $e');
      return true;
    }
  }

  /// Print all stored tokens to console
  static Future<void> printStoredTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    final userEmail = await getUserEmail();
    final userRole = await getUserRole();

    print('🔐 === STORED TOKENS ===');
    print('📧 Email: $userEmail');
    print('👤 Role: $userRole');
    print('🔑 Access Token: $accessToken');
    print('🔄 Refresh Token: $refreshToken');
    print('🔐 === END STORED TOKENS ===');

    // Decode and display token information
    if (accessToken != null) {
      print('🔍 === ACCESS TOKEN DECODED ===');
      _decodeAndPrintToken(accessToken, 'Access Token');
      print('🔍 === END ACCESS TOKEN ===');
    }

    if (refreshToken != null) {
      print('🔍 === REFRESH TOKEN DECODED ===');
      _decodeAndPrintToken(refreshToken, 'Refresh Token');
      print('🔍 === END REFRESH TOKEN ===');
    }

    // Print token status summary
    await _printTokenStatusSummary();
  }

  /// Get user information from access token
  static Future<Map<String, dynamic>?> getUserInfoFromToken() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return null;

    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final paddedPayload = payload + '=' * (4 - payload.length % 4);
      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      final payloadMap = json.decode(decodedPayload);

      return payloadMap as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error decoding token payload: $e');
      return null;
    }
  }

  /// Get user ID from token
  static Future<String?> getUserIdFromToken() async {
    final userInfo = await getUserInfoFromToken();
    return userInfo?['id'] as String?;
  }

  /// Get salon ID from token (if available)
  static Future<String?> getSalonIdFromToken() async {
    final userInfo = await getUserInfoFromToken();
    return userInfo?['salonId'] as String?;
  }

  /// Print token status summary
  static Future<void> _printTokenStatusSummary() async {
    final isAccessExpired = await isAccessTokenExpired();
    final isRefreshExpired = await isRefreshTokenExpired();

    print('📊 === TOKEN STATUS SUMMARY ===');
    print('🔑 Access Token: ${isAccessExpired ? "❌ EXPIRED" : "✅ VALID"}');
    print('🔄 Refresh Token: ${isRefreshExpired ? "❌ EXPIRED" : "✅ VALID"}');

    if (isAccessExpired && isRefreshExpired) {
      print('⚠️  Both tokens are expired. User needs to login again.');
    } else if (isAccessExpired && !isRefreshExpired) {
      print(
          '🔄 Access token expired but refresh token is valid. Can refresh access token.');
    } else if (!isAccessExpired && !isRefreshExpired) {
      print('✅ Both tokens are valid. User is authenticated.');
    }

    // Print user info from token
    final userInfo = await getUserInfoFromToken();
    if (userInfo != null) {
      print('👤 User ID: ${userInfo['id']}');
      print('📧 Email: ${userInfo['email']}');
      print('🏢 Salon ID: ${userInfo['salonId'] ?? 'N/A'}');
      print('👥 Role: ${userInfo['role']}');
    }

    print('📊 === END STATUS SUMMARY ===');
  }

  /// Decode and print JWT token information
  static void _decodeAndPrintToken(String token, String tokenType) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Invalid JWT token format');
        return;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed
      final paddedPayload = payload + '=' * (4 - payload.length % 4);
      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      final payloadMap = json.decode(decodedPayload);

      print('📋 Token Type: $tokenType');
      print('🆔 User ID: ${payloadMap['id']}');
      print('📧 Email: ${payloadMap['email']}');
      print('👤 Role: ${payloadMap['role']}');

      // Convert timestamps to readable dates
      final issuedAt =
          DateTime.fromMillisecondsSinceEpoch(payloadMap['iat'] * 1000);
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(payloadMap['exp'] * 1000);
      final now = DateTime.now();

      print('📅 Issued At: $issuedAt');
      print('⏰ Expires At: $expiresAt');
      print('🕐 Current Time: $now');

      // Check if token is expired
      final isExpired = now.isAfter(expiresAt);
      final timeUntilExpiry = expiresAt.difference(now);

      if (isExpired) {
        print('❌ Token is EXPIRED!');
      } else {
        print('✅ Token is VALID');
        print('⏳ Time until expiry: ${timeUntilExpiry.inMinutes} minutes');
      }
    } catch (e) {
      print('❌ Error decoding token: $e');
    }
  }
}
