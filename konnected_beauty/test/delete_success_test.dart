import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_home_screen.dart';

void main() {
  testWidgets('SalonHomeScreen shows delete success banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (context) => LanguageBloc(),
          child: const SalonHomeScreen(showDeleteSuccess: true),
        ),
      ),
    );

    // Verify that the success banner is displayed
    expect(find.text('Service deleted successfully'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('SalonHomeScreen does not show delete success banner by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (context) => LanguageBloc(),
          child: const SalonHomeScreen(),
        ),
      ),
    );

    // Verify that the success banner is not displayed
    expect(find.text('Service deleted successfully'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
