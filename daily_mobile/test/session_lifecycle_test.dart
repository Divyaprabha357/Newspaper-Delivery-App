import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_mobile/screens/splash_screen.dart';
import 'package:daily_mobile/screens/role_selection_screen.dart';
import 'package:daily_mobile/screens/customer/customer_dashboard_screen.dart';
import 'package:daily_mobile/screens/delivery_partner/delivery_partner_app_screen.dart';
import 'package:daily_mobile/services/customer_api_service.dart';
import 'package:daily_mobile/services/role_api_service.dart';
import 'package:daily_mobile/services/session_service.dart';
import 'package:daily_mobile/services/role_session_service.dart';

class MockLifecycleCustomerApi extends CustomerApiService {
  final Future<Map<String, dynamic>> Function(int customerId)? onProfile;

  MockLifecycleCustomerApi({this.onProfile});

  @override
  Future<Map<String, dynamic>> profile(int customerId) async {
    if (onProfile != null) return onProfile!(customerId);
    return {
      'success': true,
      'user': {
        'customer_id': customerId,
        'name': 'Aarav Sharma',
        'email': 'aarav@gmail.com',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> subscriptions(int customerId) async {
    return {'success': true, 'subscriptions': []};
  }

  @override
  Future<Map<String, dynamic>> deliveryHistory(int customerId) async {
    return {'success': true, 'deliveries': []};
  }
}

class MockLifecycleRoleApi extends RoleApiService {
  final Future<Map<String, dynamic>> Function(int userId, {int? partnerId})?
      onPartnerProfile;

  MockLifecycleRoleApi({this.onPartnerProfile});

  @override
  Future<Map<String, dynamic>> partnerProfile(int userId, {int? partnerId}) async {
    if (onPartnerProfile != null) {
      return onPartnerProfile!(userId, partnerId: partnerId);
    }
    return {
      'success': true,
      'profile': {
        'user_id': userId,
        'partner_id': partnerId ?? 1,
        'name': 'Rahul Verma',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> partnerDeliveries(int userId,
      {int? partnerId, String? date}) async {
    return {'success': true, 'deliveries': []};
  }

  @override
  Future<Map<String, dynamic>> partnerRoutes(int userId,
      {int? partnerId, String? date}) async {
    return {'success': true, 'routes': []};
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Session Lifecycle & Startup Authentication Tests', () {
    testWidgets('Case 1: Fresh app launch with no saved session -> splash -> Choose Your Role',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      bool customerApiCalled = false;
      bool partnerApiCalled = false;

      final mockCustomerApi = MockLifecycleCustomerApi(
        onProfile: (_) async {
          customerApiCalled = true;
          return {};
        },
      );
      final mockRoleApi = MockLifecycleRoleApi(
        onPartnerProfile: (_, {partnerId}) async {
          partnerApiCalled = true;
          return {};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            customerApiService: mockCustomerApi,
            roleApiService: mockRoleApi,
          ),
        ),
      );

      // Verify splash screen appears with progress indicator
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Navigates directly to Choose Your Role
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.text('Choose Your Role'), findsOneWidget);

      // Ensure NO protected API was called
      expect(customerApiCalled, isFalse);
      expect(partnerApiCalled, isFalse);

      // Ensure no invalid-session error is displayed to first-time user
      expect(find.textContaining('Your session is invalid'), findsNothing);
      expect(find.textContaining('expired'), findsNothing);
    });

    testWidgets('Case 2: Open app after logout -> splash -> Choose Your Role',
        (WidgetTester tester) async {
      // User logs in first
      await SessionService.saveCustomer({'customer_id': 1, 'name': 'Aarav'});
      expect(await SessionService.isCustomerLoggedIn(), isTrue);

      // User logs out
      await SessionService.logOut();
      expect(await SessionService.isCustomerLoggedIn(), isFalse);

      bool apiCalled = false;
      final mockCustomerApi = MockLifecycleCustomerApi(
        onProfile: (_) async {
          apiCalled = true;
          return {};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(customerApiService: mockCustomerApi),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(apiCalled, isFalse);
      expect(find.textContaining('Your session is invalid'), findsNothing);
    });

    testWidgets('Case 3: Valid Customer session -> validates & routes to Customer Dashboard',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'customer_logged_in': true,
        'customer_session': jsonEncode({
          'customer_id': 1,
          'name': 'Aarav Sharma',
          'email': 'aarav@gmail.com',
        }),
      });

      int validatedCustomerId = 0;
      final mockCustomerApi = MockLifecycleCustomerApi(
        onProfile: (customerId) async {
          validatedCustomerId = customerId;
          return {
            'success': true,
            'user': {
              'customer_id': customerId,
              'name': 'Aarav Sharma',
              'email': 'aarav@gmail.com',
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(customerApiService: mockCustomerApi),
        ),
      );
      await tester.pumpAndSettle();

      // Verifies backend validation call occurred
      expect(validatedCustomerId, 1);

      // Navigates to Customer Dashboard
      expect(find.byType(CustomerDashboardScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);

      // Session remains stored
      final stored = await SessionService.getCustomer();
      expect(stored, isNotNull);
      expect(stored!['customer_id'], 1);
    });

    testWidgets('Case 4: Valid Delivery Partner session -> validates & routes to Partner Dashboard',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'delivery_partner_session': jsonEncode({
          'user_id': 3,
          'partner_id': 1,
          'partner_code': 'DP001',
          'session_token': 'partner-valid-token',
        }),
      });

      int validatedUserId = 0;
      final mockRoleApi = MockLifecycleRoleApi(
        onPartnerProfile: (userId, {partnerId}) async {
          validatedUserId = userId;
          return {
            'success': true,
            'profile': {
              'user_id': userId,
              'partner_id': partnerId ?? 1,
              'name': 'Rahul Verma',
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(roleApiService: mockRoleApi),
        ),
      );
      await tester.pumpAndSettle();

      expect(validatedUserId, 3);
      expect(find.byType(DeliveryPartnerAppScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);

      // Session is preserved
      final partner = await RoleSessionService.getPartner();
      expect(partner, isNotNull);
      expect(partner!['partner_id'], 1);
    });

    testWidgets('Case 5A: Expired Customer session -> stale session cleared & Choose Your Role shown',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'customer_logged_in': true,
        'customer_session': jsonEncode({
          'customer_id': 99,
          'name': 'Expired Customer',
        }),
      });

      final mockCustomerApi = MockLifecycleCustomerApi(
        onProfile: (_) async {
          throw const CustomerApiException(
            'Your session is invalid or has expired',
            statusCode: 401,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(customerApiService: mockCustomerApi),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: stale session cleared
      final customer = await SessionService.getCustomer();
      expect(customer, isNull);
      expect(await SessionService.isCustomerLoggedIn(), isFalse);

      // Navigated to Choose Your Role, NOT showing dashboard with error
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(CustomerDashboardScreen), findsNothing);
      expect(find.textContaining('Your session is invalid'), findsNothing);
    });

    testWidgets('Case 5B: Expired Partner session -> stale session cleared & Choose Your Role shown',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'delivery_partner_session': jsonEncode({
          'user_id': 3,
          'partner_id': 1,
          'session_token': 'expired-token',
        }),
      });

      final mockRoleApi = MockLifecycleRoleApi(
        onPartnerProfile: (_, {partnerId}) async {
          throw const RoleApiException(
            'Your session is invalid or has expired',
            statusCode: 401,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(roleApiService: mockRoleApi),
        ),
      );
      await tester.pumpAndSettle();

      // Verified: stale partner session cleared
      final partner = await RoleSessionService.getPartner();
      expect(partner, isNull);

      // Navigated to Choose Your Role
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(DeliveryPartnerAppScreen), findsNothing);
      expect(find.textContaining('Your session is invalid'), findsNothing);
    });

    testWidgets('Case 6A: Temporary network failure on startup preserves session',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'customer_logged_in': true,
        'customer_session': jsonEncode({
          'customer_id': 1,
          'name': 'Aarav Sharma',
        }),
      });

      // Network exception (statusCode: null)
      final mockCustomerApi = MockLifecycleCustomerApi(
        onProfile: (_) async {
          throw const CustomerApiException(
            'Unable to connect to the DAILY server.',
            statusCode: null,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(customerApiService: mockCustomerApi),
        ),
      );
      await tester.pumpAndSettle();

      // Session MUST NOT be cleared on network failure
      final customer = await SessionService.getCustomer();
      expect(customer, isNotNull);
      expect(customer!['customer_id'], 1);

      // Navigates to dashboard for offline use / retry
      expect(find.byType(CustomerDashboardScreen), findsOneWidget);
    });

    testWidgets('Case 6B: Temporary network error in Dashboard displays retry without declaring session invalid',
        (WidgetTester tester) async {
      final mockCustomerApi = MockLifecycleCustomerApi(
        onProfile: (_) async {
          throw const CustomerApiException(
            'Unable to connect to the DAILY server.',
            statusCode: null,
          );
        },
      );

      await SessionService.saveCustomer({'customer_id': 1, 'name': 'Aarav'});

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDashboardScreen(apiService: mockCustomerApi),
        ),
      );
      await tester.pumpAndSettle();

      // Shows retry UI
      expect(find.text('TRY AGAIN'), findsOneWidget);
      expect(find.textContaining('Unable to connect to the DAILY server'), findsOneWidget);

      // Does NOT declare session invalid
      expect(find.textContaining('Your session is invalid'), findsNothing);

      // Session is preserved
      final customer = await SessionService.getCustomer();
      expect(customer, isNotNull);
    });
  });
}

