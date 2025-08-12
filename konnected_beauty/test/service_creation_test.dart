import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/bloc/language/language_bloc.dart';
import 'package:konnected_beauty/features/company/presentation/pages/create_service_screen.dart';
import 'package:konnected_beauty/features/company/presentation/pages/service_details_screen.dart';

void main() {
  group('Service Creation Screens', () {
    testWidgets('CreateServiceScreen renders without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => LanguageBloc(),
            child: const CreateServiceScreen(),
          ),
        ),
      );

      // Verify that the screen renders without throwing errors
      expect(find.text('Create new service'),
          findsNWidgets(2)); // Header and button
      expect(find.text('Service name'), findsOneWidget);
      expect(find.text('Service price (EURO)'), findsOneWidget);
      expect(find.text('Service description'), findsOneWidget);
    });

    testWidgets('ServiceDetailsScreen renders without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => LanguageBloc(),
            child: const ServiceDetailsScreen(
              serviceId: '123',
              serviceName: 'Test Service',
              servicePrice: '100',
              serviceDescription: 'Test description',
              showSuccessMessage: true,
            ),
          ),
        ),
      );

      // Verify that the screen renders without throwing errors
      expect(find.text('Service details'), findsOneWidget);
      expect(find.text('Test Service'), findsOneWidget);
      expect(find.text('100 €'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('ServiceDetailsScreen without success message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => LanguageBloc(),
            child: const ServiceDetailsScreen(
              serviceId: '123',
              serviceName: 'Test Service',
              servicePrice: '100',
              serviceDescription: 'Test description',
              showSuccessMessage: false,
            ),
          ),
        ),
      );

      // Verify that the screen renders without success message
      expect(find.text('Service details'), findsOneWidget);
      expect(find.text('Test Service'), findsOneWidget);
      expect(find.text('100 €'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
