import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_mobile/screens/customer/auth_screen.dart';
import 'package:daily_mobile/screens/customer/customer_dashboard_screen.dart';
import 'package:daily_mobile/screens/customer/profile_screen.dart';
import 'package:daily_mobile/screens/delivery_partner/delivery_partner_app_screen.dart';
import 'package:daily_mobile/screens/delivery_partner/partner_auth_screen.dart';
import 'package:daily_mobile/screens/role_selection_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_app_shell.dart';
import 'package:daily_mobile/screens/supplier/supplier_login_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_profile_screen.dart';
import 'package:daily_mobile/services/customer_api_service.dart';
import 'package:daily_mobile/services/role_api_service.dart';
import 'package:daily_mobile/services/role_session_service.dart';
import 'package:daily_mobile/services/session_service.dart';

class LogoutMockClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;
  LogoutMockClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final res = await handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      headers: res.headers,
    );
  }
}

void main() {
  late http.Client mockClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockClient = LogoutMockClient((req) async {
      final path = req.url.path;

      if (path.contains('/customer-profile') || path.contains('/profile')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'user': {
              'customer_id': 1,
              'name': 'Aarav Sharma',
              'email': 'aarav@gmail.com',
              'phone': '9876543210',
              'role': 'CUSTOMER',
            },
            'profile': {
              'supplier_id': 1,
              'supplier_name': 'Mumbai Daily Distributors',
              'contact_number': '9876543214',
              'address': 'Dadar West',
              'service_areas': ['Dadar West'],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/subscriptions')) {
        return http.Response(
          jsonEncode({'success': true, 'subscriptions': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/deliveries') || path.contains('/delivery-history')) {
        return http.Response(
          jsonEncode({'success': true, 'deliveries': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/payments')) {
        return http.Response(
          jsonEncode({'success': true, 'payments': [], 'bills': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/routes')) {
        return http.Response(
          jsonEncode({'success': true, 'routes': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/newspapers')) {
        return http.Response(
          jsonEncode({'success': true, 'newspapers': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        jsonEncode({'success': true}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    CustomerApiService.customClient = mockClient;
    RoleApiService.customClient = mockClient;
  });

  tearDown(() {
    CustomerApiService.customClient = null;
    RoleApiService.customClient = null;
  });

  group('DAILY Logout Redirect Tests', () {
    testWidgets('1. Supplier logout from SupplierAppShell drawer redirects to SupplierLoginScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'supplier_session': jsonEncode({
          'supplier_id': 1,
          'user_id': 5,
          'name': 'Mumbai Daily Admin',
          'role': 'SUPPLIER',
        }),
      });

      expect(await RoleSessionService.getSupplier(), isNotNull);

      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierAppShell(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SupplierAppShell), findsOneWidget);

      // Open drawer
      final menuButton = find.byIcon(Icons.menu_rounded);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Scroll and tap 'Log Out'
      final logoutTile = find.widgetWithText(ListTile, 'Log Out');
      await tester.scrollUntilVisible(
        logoutTile,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(logoutTile, findsOneWidget);
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      // Session must be cleared
      expect(await RoleSessionService.getSupplier(), isNull);

      // Must be on SupplierLoginScreen and NOT RoleSelectionScreen
      expect(find.byType(SupplierLoginScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.text('Supplier Sign In'), findsOneWidget);
    });

    testWidgets('2. Supplier logout from SupplierProfileScreen redirects to SupplierLoginScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'supplier_session': jsonEncode({
          'supplier_id': 1,
          'user_id': 5,
          'name': 'Mumbai Daily Admin',
          'role': 'SUPPLIER',
        }),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupplierProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final logoutButton = find.widgetWithText(OutlinedButton, 'LOG OUT');
      await tester.scrollUntilVisible(
        logoutButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Session must be cleared
      expect(await RoleSessionService.getSupplier(), isNull);

      // Must be on SupplierLoginScreen and NOT RoleSelectionScreen
      expect(find.byType(SupplierLoginScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.text('Supplier Sign In'), findsOneWidget);
    });

    testWidgets('3. Delivery Partner logout redirects to DeliveryPartnerAppScreen (PartnerAuthScreen)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'delivery_partner_session': jsonEncode({
          'user_id': 3,
          'partner_id': 1,
          'name': 'Rahul Patil',
          'role': 'DELIVERY_PARTNER',
        }),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryPartnerAppScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Profile tab
      final profileTab = find.byIcon(Icons.person_outline);
      expect(profileTab, findsOneWidget);
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      // Tap logout icon
      final logoutIcon = find.byIcon(Icons.logout);
      expect(logoutIcon, findsOneWidget);
      await tester.tap(logoutIcon);
      await tester.pumpAndSettle();

      // Session must be cleared
      expect(await RoleSessionService.getPartner(), isNull);

      // Must display PartnerAuthScreen and NOT RoleSelectionScreen
      expect(find.byType(PartnerAuthScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.text('Partner sign in'), findsOneWidget);
    });

    testWidgets('4. Customer logout from ProfileScreen redirects to AuthScreen(role: CUSTOMER)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'customer_logged_in': true,
        'customer_session': jsonEncode({
          'customer_id': 1,
          'user_id': 1,
          'name': 'Aarav Sharma',
          'email': 'aarav@gmail.com',
          'role': 'CUSTOMER',
        }),
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap 'LOG OUT' button
      final logoutBtn = find.widgetWithText(TextButton, 'LOG OUT');
      await tester.scrollUntilVisible(
        logoutBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Confirm in dialog
      final confirmBtn = find.widgetWithText(ElevatedButton, 'LOGOUT');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Session must be cleared
      expect(await SessionService.isCustomerLoggedIn(), isFalse);

      // Must be on Customer AuthScreen and NOT RoleSelectionScreen
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.text('Sign in to your customer account.'), findsOneWidget);
    });

    testWidgets('5. Protected SupplierAppShell without session redirects to SupplierLoginScreen',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); // No session

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const SupplierAppShell()),
                ),
                child: const Text('Open Supplier'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Supplier'));
      await tester.pumpAndSettle();
      expect(find.byType(SupplierLoginScreen), findsOneWidget);
    });

    testWidgets('6. Protected CustomerDashboardScreen without session redirects to Customer AuthScreen',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); // No session

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
                ),
                child: const Text('Open Customer'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Customer'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
    });

    testWidgets('7. Protected DeliveryPartnerAppScreen without session renders PartnerAuthScreen',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({}); // No session

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryPartnerAppScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PartnerAuthScreen), findsOneWidget);
    });

    testWidgets('8. Browser back navigation on root SupplierLoginScreen routes safely to RoleSelectionScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final supplierBack = find.byIcon(Icons.chevron_left);
      expect(supplierBack, findsOneWidget);
      await tester.tap(supplierBack);
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
    });

    testWidgets('9. Browser back navigation on root Customer AuthScreen routes safely to RoleSelectionScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(role: 'CUSTOMER'),
        ),
      );
      await tester.pumpAndSettle();
      final custBack = find.byIcon(Icons.chevron_left);
      expect(custBack, findsOneWidget);
      await tester.tap(custBack);
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
    });
  });
}

