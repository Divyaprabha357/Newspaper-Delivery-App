import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_mobile/screens/customer/auth_screen.dart';
import 'package:daily_mobile/screens/customer/customer_dashboard_screen.dart';
import 'package:daily_mobile/screens/customer/login_screen.dart';
import 'package:daily_mobile/screens/delivery_partner/partner_auth_screen.dart';
import 'package:daily_mobile/services/customer_api_service.dart';
import 'package:daily_mobile/services/role_api_service.dart';
import 'package:daily_mobile/services/session_service.dart';
import 'package:daily_mobile/services/role_session_service.dart';

class MockCustomerApiService extends CustomerApiService {
  final Future<Map<String, dynamic>> Function({
    required String emailOrPhone,
    required String password,
    String? role,
  })? onLogin;

  MockCustomerApiService({this.onLogin});

  @override
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
    String? role,
  }) async {
    if (onLogin != null) {
      return onLogin!(
        emailOrPhone: emailOrPhone,
        password: password,
        role: role,
      );
    }
    return {
      'token': 'mock-customer-token',
      'user': {
        'id': 1,
        'customer_id': 1,
        'name': 'Aarav Sharma',
        'email': emailOrPhone,
        'phone': '9876543210',
        'role': 'CUSTOMER',
      },
    };
  }
}

class MockRoleApiService extends RoleApiService {
  final Future<Map<String, dynamic>> Function({
    String? emailOrPhone,
    String? partnerCode,
    required String password,
    String? role,
  })? onLogin;

  MockRoleApiService({this.onLogin});

  @override
  Future<Map<String, dynamic>> login({
    String? emailOrPhone,
    String? partnerCode,
    required String password,
    String? role,
  }) async {
    if (onLogin != null) {
      return onLogin!(
        emailOrPhone: emailOrPhone,
        partnerCode: partnerCode,
        password: password,
        role: role,
      );
    }
    return {
      'token': 'mock-partner-token',
      'user': {
        'id': 3,
        'partner_id': 1,
        'partner_code': 'DP001',
        'name': 'Rahul Verma',
        'email': emailOrPhone,
        'phone': '9876543212',
        'role': 'DELIVERY_PARTNER',
      },
    };
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Customer AuthScreen Tests', () {
    testWidgets('Validation: empty email displays error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthScreen(role: 'CUSTOMER'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email address.'), findsOneWidget);
    });

    testWidgets('Validation: invalid email format displays error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthScreen(role: 'CUSTOMER'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'invalidemail');
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('Validation: empty password displays error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthScreen(role: 'CUSTOMER'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'aarav@gmail.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('Validation: empty phone number in phone mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthScreen(role: 'CUSTOMER'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Phone tab
      await tester.tap(find.text('Phone'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your phone number.'), findsOneWidget);
    });

    testWidgets('Validation: invalid phone number (< 10 digits)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthScreen(role: 'CUSTOMER'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Phone tab
      await tester.tap(find.text('Phone'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '12345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 10-digit phone number.'), findsOneWidget);
    });

    testWidgets('Successful customer login saves session and navigates',
        (WidgetTester tester) async {
      String? sentRole;
      String? sentIdentifier;
      String? sentPassword;

      final mockApi = MockCustomerApiService(
        onLogin: ({required emailOrPhone, required password, role}) async {
          sentIdentifier = emailOrPhone;
          sentPassword = password;
          sentRole = role;
          return {
            'token': 'jwt-token-123',
            'user': {
              'id': 1,
              'customer_id': 1,
              'name': 'Aarav Sharma',
              'email': emailOrPhone,
              'role': 'CUSTOMER',
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(role: 'CUSTOMER', apiService: mockApi),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'aarav@gmail.com');
      await tester.enterText(textFields.at(1), '123456');

      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();

      // Verify API request payload
      expect(sentIdentifier, 'aarav@gmail.com');
      expect(sentPassword, '123456');
      expect(sentRole, 'CUSTOMER');

      // Verify session stored
      final user = await SessionService.getCustomer();
      expect(user, isNotNull);
      expect(user!['customer_id'], 1);
      expect(user['name'], 'Aarav Sharma');

      // Verify navigation to CustomerDashboardScreen
      expect(find.byType(CustomerDashboardScreen), findsOneWidget);
    });

    testWidgets('Customer login API error displays message in SnackBar',
        (WidgetTester tester) async {
      final mockApi = MockCustomerApiService(
        onLogin: ({required emailOrPhone, required password, role}) async {
          throw const CustomerApiException('Invalid email or password.', statusCode: 401);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthScreen(role: 'CUSTOMER', apiService: mockApi),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'aarav@gmail.com');
      await tester.enterText(textFields.at(1), 'wrongpass');

      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
      expect(find.byType(CustomerDashboardScreen), findsNothing);
    });

    testWidgets('Customer login with role mismatch displays 403 error',
        (WidgetTester tester) async {
      final mockApi = MockCustomerApiService(
        onLogin: ({required emailOrPhone, required password, role}) async {
          return {
            'token': 'jwt-token-partner',
            'user': {
              'id': 3,
              'partner_id': 1,
              'name': 'Rahul Verma',
              'role': 'DELIVERY_PARTNER',
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthScreen(role: 'CUSTOMER', apiService: mockApi),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'rahul@daily.com');
      await tester.enterText(textFields.at(1), 'demo_hash_123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();

      expect(
        find.text('This account is not authorized as a Customer account.'),
        findsOneWidget,
      );
      expect(find.byType(CustomerDashboardScreen), findsNothing);
    });
  });

  group('Customer LoginScreen Tests', () {
    testWidgets('Email mode: validates input and logs in successfully',
        (WidgetTester tester) async {
      final mockApi = MockCustomerApiService(
        onLogin: ({required emailOrPhone, required password, role}) async {
          return {
            'token': 'jwt-token-customer',
            'user': {
              'id': 2,
              'customer_id': 2,
              'name': 'Priya Patel',
              'email': emailOrPhone,
              'role': 'CUSTOMER',
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            loginType: LoginType.email,
            apiService: mockApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit with empty email
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email address.'), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(LoginScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Submit with invalid email
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'priya');
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(LoginScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Submit with empty password
      await tester.enterText(textFields.at(0), 'priya@gmail.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your password.'), findsOneWidget);

      // Fill valid credentials and sign in
      await tester.enterText(textFields.at(1), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();

      // Verify session and navigation
      final user = await SessionService.getCustomer();
      expect(user, isNotNull);
      expect(user!['customer_id'], 2);
      expect(find.byType(CustomerDashboardScreen), findsOneWidget);
    });

    testWidgets('Phone mode: validates 10-digit phone number',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(loginType: LoginType.phone),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '987');
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 10-digit phone number.'), findsOneWidget);
    });
  });

  group('Delivery Partner PartnerAuthScreen Tests', () {
    testWidgets('Validation: empty email, invalid email, empty password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartnerAuthScreen(onSignedIn: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty email
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email address.'), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(PartnerAuthScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Invalid email
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'invalidpartneremail');
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(PartnerAuthScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Empty password
      await tester.enterText(textFields.at(0), 'rahul@daily.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('Successful partner login saves session and invokes onSignedIn',
        (WidgetTester tester) async {
      bool signedInCalled = false;
      String? sentRole;
      String? sentEmail;

      final mockApi = MockRoleApiService(
        onLogin: ({emailOrPhone, partnerCode, required password, role}) async {
          sentEmail = emailOrPhone;
          sentRole = role;
          return {
            'token': 'partner-jwt-token',
            'user': {
              'id': 3,
              'partner_id': 1,
              'partner_code': 'DP001',
              'name': 'Rahul Verma',
              'email': emailOrPhone,
              'role': 'DELIVERY_PARTNER',
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartnerAuthScreen(
              onSignedIn: () => signedInCalled = true,
              apiService: mockApi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'rahul@daily.com');
      await tester.enterText(textFields.at(1), 'demo_hash_123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();

      // Verify payload
      expect(sentEmail, 'rahul@daily.com');
      expect(sentRole, 'DELIVERY_PARTNER');

      // Verify session stored
      final partner = await RoleSessionService.getPartner();
      expect(partner, isNotNull);
      expect(partner!['partner_id'], 1);
      expect(partner['partner_code'], 'DP001');

      // Verify callback invoked
      expect(signedInCalled, isTrue);
    });

    testWidgets('Delivery partner login API error displays message in SnackBar',
        (WidgetTester tester) async {
      final mockApi = MockRoleApiService(
        onLogin: ({emailOrPhone, partnerCode, required password, role}) async {
          throw const RoleApiException('Invalid email or password.', statusCode: 401);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartnerAuthScreen(
              onSignedIn: () {},
              apiService: mockApi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'rahul@daily.com');
      await tester.enterText(textFields.at(1), 'wrongpassword');

      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('Delivery partner login with role mismatch displays authorization error',
        (WidgetTester tester) async {
      final mockApi = MockRoleApiService(
        onLogin: ({emailOrPhone, partnerCode, required password, role}) async {
          return {
            'token': 'customer-token',
            'user': {
              'id': 1,
              'customer_id': 1,
              'name': 'Aarav Sharma',
              'role': 'CUSTOMER',
            },
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PartnerAuthScreen(
              onSignedIn: () {},
              apiService: mockApi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'aarav@gmail.com');
      await tester.enterText(textFields.at(1), '123456');

      await tester.tap(find.widgetWithText(ElevatedButton, 'SIGN IN'));
      await tester.pumpAndSettle();

      expect(
        find.text('This account is not authorized for the Delivery Partner workspace.'),
        findsOneWidget,
      );
    });
  });
}

