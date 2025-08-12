import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/company/presentation/pages/salon_home_screen.dart';

void main() {
  testWidgets('Bottom navigation bar renders without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (context) => LanguageBloc(),
          child: const SalonHomeScreen(),
        ),
      ),
    );

    // Verify that all navigation items are present
    expect(find.text('Services'), findsNWidgets(2)); // Header and bottom nav
    expect(find.text('Campaigns'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Influencers'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify that the bottom navigation bar is rendered
    expect(find.byType(BottomNavigationBar), findsNothing); // We use custom navigation
    expect(find.byType(Row), findsWidgets); // Should find the custom navigation row
  });
}
