import 'package:flutter_test/flutter_test.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';

void main() {
  test('App theme uses Montserrat font family', () {
    // Verify that the app theme has Montserrat as the font family
    expect(AppTheme.fontFamily, equals('Montserrat'));
  });
}
