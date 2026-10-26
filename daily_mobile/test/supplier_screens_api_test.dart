import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_mobile/screens/supplier/supplier_distribution_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_delivery_operations_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_requests_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_payments_screen.dart';
import 'package:daily_mobile/services/role_api_service.dart';
import 'package:daily_mobile/services/role_session_service.dart';

class TestMockClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;
  TestMockClient(this.handler);

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Supplier Distribution Screen Tests', () {
    testWidgets('Renders distribution demand, stock, shortage, dispatch and interactive table', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
        'name': 'Mumbai Daily Admin',
        'session_token': 'test_token',
      });

      RoleApiService.customClient = TestMockClient((req) async {
        if (req.url.path.contains('/supplier/distribution')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'date': '2026-10-26',
              'distribution': [
                {
                  'id': '1',
                  'newspaper_id': 1,
                  'name': 'The Times of India',
                  'required': 12,
                  'available': 10,
                  'shortage': 2,
                  'dispatch': 10,
                  'status': 'ACTIVE',
                },
                {
                  'id': '2',
                  'newspaper_id': 2,
                  'name': 'Hindustan Times',
                  'required': 8,
                  'available': 8,
                  'shortage': 0,
                  'dispatch': 8,
                  'status': 'ACTIVE',
                },
              ],
              'summary': {
                'expected_demand': 20,
                'available_stock': 18,
                'shortage': 2,
                'dispatch_planned': 18,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"Not found"}', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupplierDistributionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header & Screen Title
      expect(find.text('DAILY DISTRIBUTION'), findsOneWidget);
      expect(find.text('Distribution'), findsOneWidget);

      // Verify Summary Metric Cards
      expect(find.text('EXPECTED DEMAND'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('AVAILABLE STOCK'), findsOneWidget);
      expect(find.text('18'), findsWidgets); // Stock and Dispatch both 18
      expect(find.text('SHORTAGE'), findsWidgets); // Metric card and table header
      expect(find.text('2'), findsWidgets); // Shortage card and row

      // Verify Newspapers in Table
      expect(find.text('The Times of India'), findsOneWidget);
      expect(find.text('Hindustan Times'), findsOneWidget);

      // Verify Confirm Distribution Action
      final confirmBtn = find.text('CONFIRM DISTRIBUTION');
      expect(confirmBtn, findsOneWidget);
      await tester.scrollUntilVisible(confirmBtn, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog
      expect(find.text('Confirm Distribution Plan'), findsOneWidget);
      expect(find.text('CONFIRM ALLOCATION'), findsOneWidget);
      await tester.tap(find.text('CONFIRM ALLOCATION'));
      await tester.pumpAndSettle();

      expect(find.text('Allocation Confirmed'), findsOneWidget);
    });
  });

  group('Supplier Delivery Operations Screen Tests', () {
    testWidgets('Loads deliveries and renders across operational tabs with formatted date', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
        'session_token': 'test_token',
      });

      RoleApiService.customClient = TestMockClient((req) async {
        if (req.url.path.contains('/supplier/deliveries')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'deliveries': [
                {
                  'delivery_id': 1,
                  'delivery_date': '2026-09-08T00:00:00.000Z',
                  'area_name': 'Dadar West',
                  'partner_name': 'Rahul Patil',
                  'delivery_status': 'DELIVERED',
                  'customer_name': 'Aarav Sharma',
                  'newspaper_name': 'The Times of India',
                  'item_status': 'DELIVERED',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"Not found"}', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupplierDeliveryOperationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Check title and tabs
      expect(find.text('Delivery Operations'), findsOneWidget);
      expect(find.text('ROUTES'), findsOneWidget);
      expect(find.text('DELIVERY PARTNERS'), findsOneWidget);
      expect(find.text('DELIVERY PROGRESS'), findsOneWidget);

      // Check formatted delivery date (2026-09-08 rather than raw ISO)
      expect(find.text('2026-09-08'), findsOneWidget);
      expect(find.text('Rahul Patil'), findsOneWidget);
      expect(find.text('DELIVERED'), findsOneWidget);

      // Switch to Delivery Partners Tab
      await tester.tap(find.text('DELIVERY PARTNERS'));
      await tester.pumpAndSettle();
      expect(find.text('Rahul Patil'), findsOneWidget);
      expect(find.text('Dadar West'), findsOneWidget);

      // Switch to Delivery Progress Tab
      await tester.tap(find.text('DELIVERY PROGRESS'));
      await tester.pumpAndSettle();
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('The Times of India'), findsOneWidget);
    });
  });

  group('Supplier Requests Screen Tests', () {
    testWidgets('Renders requests, complaints, search filter, and detail dialog', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
        'session_token': 'test_token',
      });

      RoleApiService.customClient = TestMockClient((req) async {
        if (req.url.path.contains('/supplier/requests')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'requests': [
                {
                  'request_id': 101,
                  'request_type': 'SUBSCRIPTION_PAUSE',
                  'customer_name': 'Aarav Sharma',
                  'customer_phone': '9876543210',
                  'newspaper_name': 'The Times of India',
                  'description': 'Pause delivery for 3 days',
                  'status': 'PENDING',
                  'created_at': '2026-10-24T10:00:00.000Z',
                },
              ],
              'complaints': [
                {
                  'complaint_id': 201,
                  'complaint_type': 'MISSED_DELIVERY',
                  'customer_name': 'Aarav Sharma',
                  'customer_phone': '9876543210',
                  'newspaper_name': 'The Times of India',
                  'description': 'Paper not received this morning',
                  'status': 'OPEN',
                  'created_at': '2026-10-25T08:00:00.000Z',
                  'resolution': null,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"Not found"}', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupplierRequestsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Requests & Complaints'), findsOneWidget);
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Requests (1)'), findsOneWidget);
      expect(find.text('Complaints (1)'), findsOneWidget);

      // Verify cards rendered
      expect(find.text('SUBSCRIPTION PAUSE'), findsOneWidget);
      expect(find.text('MISSED DELIVERY'), findsOneWidget);

      // Tap View Details on Complaint
      final viewDetailsButtons = find.text('VIEW DETAILS');
      expect(viewDetailsButtons, findsWidgets);
      await tester.tap(viewDetailsButtons.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Complaint #201'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
      await tester.tap(find.text('CLOSE'));
      await tester.pumpAndSettle();
    });
  });

  group('Supplier Payments Screen Tests', () {
    testWidgets('Calculates and renders real earnings, received, and pending balances', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
        'session_token': 'test_token',
      });

      RoleApiService.customClient = TestMockClient((req) async {
        if (req.url.path.contains('/supplier/payments')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'payments': [
                {
                  'bill_id': 1,
                  'customer_name': 'Aarav Sharma',
                  'newspaper_names': 'The Times of India',
                  'amount': '156.00',
                  'supplier_item_total': '156.00',
                  'payment_status': 'SUCCESS',
                  'bill_status': 'PAID',
                  'payment_date': '2026-09-08',
                },
                {
                  'bill_id': 2,
                  'customer_name': 'Priya Patel',
                  'newspaper_names': 'Dainik Jagran',
                  'amount': '130.00',
                  'supplier_item_total': '130.00',
                  'payment_status': 'FAILED',
                  'bill_status': 'PENDING',
                  'generated_at': '2026-09-08',
                },
              ],
              'summary': {
                'total_earnings': '286.00',
                'amount_received': '156.00',
                'pending_amount': '130.00',
                'total_records': 2,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"Not found"}', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupplierPaymentsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payments'), findsOneWidget);

      // Verify real calculated balances are shown
      expect(find.text('TOTAL EARNINGS'), findsOneWidget);
      expect(find.text('₹286.00'), findsOneWidget);
      expect(find.text('AMOUNT RECEIVED'), findsOneWidget);
      expect(find.text('₹156.00'), findsWidgets);
      expect(find.text('PENDING AMOUNT'), findsOneWidget);
      expect(find.text('₹130.00'), findsWidgets);

      // Verify records in list
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Priya Patel'), findsOneWidget);
    });

    testWidgets('Does NOT display misleading ₹0.00 totals when API fails with an error', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
        'session_token': 'test_token',
      });

      RoleApiService.customClient = TestMockClient((req) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Failed to connect to payment gateway (HTTP 500)',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SupplierPaymentsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure error state is displayed with retry
      expect(find.textContaining('Failed to connect to payment gateway'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);

      // Ensure fake ₹0.00 totals are NOT displayed to mislead the user
      expect(find.text('₹0.00'), findsNothing);
      expect(find.text('TOTAL EARNINGS'), findsNothing);
    });
  });
}
