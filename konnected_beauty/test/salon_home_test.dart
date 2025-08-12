import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_home_screen.dart';

void main() {
  testWidgets('SalonHomeScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (context) => LanguageBloc(),
          child: const SalonHomeScreen(),
        ),
      ),
    );

    // Verify that the screen renders without throwing errors
    expect(find.text('Services'), findsNWidgets(2)); // One in header, one in bottom nav
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Create new service'), findsOneWidget);
  });
}
