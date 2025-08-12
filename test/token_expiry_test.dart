import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  test('Token expiry calculation test', () {
    // This is the token from the logs: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImZkMjc1NmU5LWE4YjAtNDRhMy1iYTkyLThmYjgzNWNmNDc1ZSIsImVtYWlsIjoiWW91YmFAc3BvdGxpZ2h0ZHouZHoiLCJyb2xlIjoic2Fsb24iLCJpYXQiOjE3NTQ5MjMwMDMsImV4cCI6MTc1NDkyMzAzM30.mSvJ_aQqccJK_UwcI7vOch31wXfPlhye8Yh3ExfF8OI

    final token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImZkMjc1NmU5LWE4YjAtNDRhMy1iYTkyLThmYjgzNWNmNDc1ZSIsImVtYWlsIjoiWW91YmFAc3BvdGxpZ2h0ZHouZHoiLCJyb2xlIjoic2Fsb24iLCJpYXQiOjE3NTQ5MjMwMDMsImV4cCI6MTc1NDkyMzAzM30.mSvJ_aQqccJK_UwcI7vOch31wXfPlhye8Yh3ExfF8OI';

    final parts = token.split('.');
    expect(parts.length, equals(3));

    final payload = parts[1];
    final paddedPayload = payload + '=' * (4 - payload.length % 4);
    final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
    final payloadMap = json.decode(decodedPayload);

    print('🔍 Token payload: $payloadMap');

    final iat = payloadMap['iat'];
    final exp = payloadMap['exp'];

    print('📅 Token issued at: $iat');
    print('📅 Token expires at: $exp');
    print('⏱️  Token lifetime: ${exp - iat} seconds');

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();

    print('📅 Expires at: $expiresAt');
    print('🕐 Current time: $now');
    print('⏰ Is expired: ${now.isAfter(expiresAt)}');

    // The token has a very short lifetime (30 seconds)
    expect(exp - iat, equals(30));

    // This token is likely expired by now
    expect(now.isAfter(expiresAt), isTrue);
  });
}
