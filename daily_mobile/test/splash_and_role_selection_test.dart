import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_mobile/screens/splash_screen.dart';
import 'package:daily_mobile/screens/role_selection_screen.dart';
import 'package:daily_mobile/screens/customer/customer_dashboard_screen.dart';
import 'package:daily_mobile/screens/delivery_partner/delivery_partner_app_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_app_shell.dart';
import 'package:daily_mobile/services/session_service.dart';
import 'package:daily_mobile/services/role_session_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Scenario 1: No session routes to RoleSelectionScreen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial splash frame with logo and progress indicator
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Allow async session check and transition to complete
    await tester.pumpAndSettle();

    // Verify redirected to RoleSelectionScreen
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.text('Choose Your Role'), findsOneWidget);
  });

  testWidgets('Scenario 2: Logged-in Customer routes to CustomerDashboardScreen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'customer_logged_in': true,
      'customer_session': '{"customer_id": 10, "name": "Test Customer"}',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CustomerDashboardScreen), findsOneWidget);
    expect(find.byType(RoleSelectionScreen), findsNothing);
  });

  testWidgets(
      'Scenario 3: Logged-in Delivery Partner routes to DeliveryPartnerAppScreen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'delivery_partner_session':
          '{"partner_id": 5, "user_id": 25, "name": "Partner Alex"}',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(DeliveryPartnerAppScreen), findsOneWidget);
    expect(find.byType(RoleSelectionScreen), findsNothing);
  });

  testWidgets('Scenario 4: Logged-in Supplier routes to SupplierAppShell',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'supplier_session':
          '{"supplier_id": 3, "user_id": 12, "name": "Supplier Apex"}',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SupplierAppShell), findsOneWidget);
    expect(find.byType(RoleSelectionScreen), findsNothing);
  });

  testWidgets('Scenario 5: Customer logout clears session and routes to RoleSelectionScreen',
      (WidgetTester tester) async {
    await SessionService.saveCustomer({'customer_id': 10, 'name': 'Test'});
    expect(await SessionService.isCustomerLoggedIn(), isTrue);

    await SessionService.logOut();
    expect(await SessionService.isCustomerLoggedIn(), isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
  });

  testWidgets('Scenario 6: Delivery Partner logout clears session and routes to RoleSelectionScreen',
      (WidgetTester tester) async {
    await RoleSessionService.savePartner({'partner_id': 5, 'name': 'Alex'});
    expect(await RoleSessionService.getPartner(), isNotNull);

    await RoleSessionService.clearPartner();
    expect(await RoleSessionService.getPartner(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
  });

  testWidgets('Scenario 7: Supplier logout clears session and routes to RoleSelectionScreen',
      (WidgetTester tester) async {
    await RoleSessionService.saveSupplier({'supplier_id': 3, 'name': 'Apex'});
    expect(await RoleSessionService.getSupplier(), isNotNull);

    await RoleSessionService.clearSupplier();
    expect(await RoleSessionService.getSupplier(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
  });

  testWidgets(
      'Scenario 8: RoleSelectionScreen displays only Customer and Delivery Partner options with descriptions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionScreen(),
      ),
    );

    // Customer option & exact subtitle
    expect(find.text('CUSTOMER'), findsOneWidget);
    expect(
      find.text('Subscribe to newspapers and manage deliveries'),
      findsOneWidget,
    );

    // Delivery Partner option & exact subtitle
    expect(find.text('DELIVERY PARTNER'), findsOneWidget);
    expect(
      find.text('View assigned deliveries and manage delivery tasks'),
      findsOneWidget,
    );

    // Supplier is completely removed
    expect(find.text('SUPPLIER'), findsNothing);
    expect(find.text('Supplier'), findsNothing);

    // Verify icons exist
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.delivery_dining_outlined), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsNothing);
  });
}

