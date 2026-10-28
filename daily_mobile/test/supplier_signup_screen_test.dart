import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:daily_mobile/screens/supplier/supplier_login_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_signup_screen.dart';
import 'package:daily_mobile/services/role_api_service.dart';

void main() {
  setUp(() {
    RoleApiService.customClient = null;
  });

  group('Supplier Auth Flow Tests', () {
    testWidgets('SupplierLoginScreen renders "Don\'t have an account? Sign Up" link and navigates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create your supplier account'), findsOneWidget);
    });

    testWidgets('SupplierSignUpScreen renders all required fields and terms checkbox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierSignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY'), findsOneWidget);
      expect(find.text('SUPPLIER NETWORK'), findsOneWidget);
      expect(find.text('Create your supplier account'), findsOneWidget);
      expect(find.text('SUPPLIER / BUSINESS NAME'), findsOneWidget);
      expect(find.text("CONTACT PERSON'S FULL NAME"), findsOneWidget);
      expect(find.text('BUSINESS EMAIL'), findsOneWidget);
      expect(find.text('PHONE NUMBER'), findsOneWidget);
      expect(find.text('BUSINESS ADDRESS'), findsOneWidget);
      expect(find.text('SERVICE AREA OR AREAS'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('SupplierSignUpScreen validates empty fields and terms checkbox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierSignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final createBtn = find.text('CREATE ACCOUNT');
      expect(createBtn, findsOneWidget);

      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Supplier / business name is required.'), findsOneWidget);
    });

    testWidgets('SupplierSignUpScreen validates password mismatch and terms acceptance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierSignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Apex News Logistics');
      await tester.enterText(find.byType(TextField).at(1), 'Suresh Patil');
      await tester.enterText(find.byType(TextField).at(2), 'suresh@apexnews.com');
      await tester.enterText(find.byType(TextField).at(3), '9876543210');
      await tester.enterText(find.byType(TextField).at(4), 'Gala 5, Dadar East');
      await tester.enterText(find.byType(TextField).at(6), 'Secret123');
      await tester.enterText(find.byType(TextField).at(7), 'DifferentPassword');

      final createBtn = find.text('CREATE ACCOUNT');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);

      // Fix password mismatch but leave terms unaccepted
      await tester.enterText(find.byType(TextField).at(7), 'Secret123');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please accept the Terms and Conditions to proceed.'), findsOneWidget);
    });

    testWidgets('SupplierSignUpScreen registers supplier successfully and redirects to Login', (tester) async {
      RoleApiService.customClient = MockClient((req) async {
        if (req.url.path.contains('/supplier/register')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Supplier account created successfully! Please sign in.',
              'user': {
                'user_id': 99,
                'supplier_id': 50,
                'role': 'SUPPLIER',
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"Not found"}', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierSignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Apex News Logistics');
      await tester.enterText(find.byType(TextField).at(1), 'Suresh Patil');
      await tester.enterText(find.byType(TextField).at(2), 'suresh@apexnews.com');
      await tester.enterText(find.byType(TextField).at(3), '9876543210');
      await tester.enterText(find.byType(TextField).at(4), 'Gala 5, Dadar East');
      await tester.enterText(find.byType(TextField).at(6), 'Secret123');
      await tester.enterText(find.byType(TextField).at(7), 'Secret123');

      // Check Terms checkbox
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final createBtn = find.text('CREATE ACCOUNT');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Supplier Sign In'), findsOneWidget);
      expect(find.text('Supplier account created successfully! Please sign in.'), findsOneWidget);
    });
  });
}

