import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_mobile/screens/customer/profile_details_screen.dart';
import 'package:daily_mobile/screens/customer/delivery_history_screen.dart';
import 'package:daily_mobile/screens/customer/service_request_screen.dart';
import 'package:daily_mobile/screens/delivery_partner/partner_profile_screen.dart';
import 'package:daily_mobile/screens/delivery_partner/partner_history_earnings_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_reports_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_communication_screen.dart';
import 'package:daily_mobile/screens/supplier/supplier_profile_screen.dart';
import 'package:daily_mobile/services/customer_api_service.dart';
import 'package:daily_mobile/services/role_api_service.dart';
import 'package:daily_mobile/services/session_service.dart';
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
  late http.Client mockClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockClient = TestMockClient((req) async {
      final path = req.url.path;

      if (path.contains('/customer-profile/1') && req.method == 'PUT') {
        return http.Response(jsonEncode({
          'success': true,
          'message': 'Profile details updated successfully',
        }), 200, headers: {'content-type': 'application/json'});
      }

      if (path.contains('/delivery-history')) {
        return http.Response(jsonEncode({
          'success': true,
          'deliveries': [
            {
              'delivery_id': 101,
              'newspaper_name': 'The Times of India',
              'item_status': 'DELIVERED',
              'delivery_date': '2026-10-25',
              'actual_time': '06:45:00',
            },
            {
              'delivery_id': 102,
              'newspaper_name': 'Hindustan Times',
              'item_status': 'DELAYED',
              'delivery_date': '2026-10-25',
              'scheduled_time': '07:30:00',
            },
            {
              'delivery_id': 103,
              'newspaper_name': 'City Morning',
              'item_status': 'NOT_DELIVERED',
              'delivery_date': '2026-10-24',
              'scheduled_time': '07:00:00',
            },
          ],
        }), 200, headers: {'content-type': 'application/json'});
      }

      if (path.contains('/supplier/profile')) {
        return http.Response(jsonEncode({
          'success': true,
          'profile': {
            'supplier_id': 1,
            'supplier_name': 'Mumbai Daily Distributors',
            'name': 'Mumbai Daily Admin',
            'email': 'admin@mumbaidaily.com',
            'phone': '9876543214',
            'address': 'Dadar West, Mumbai',
            'supplier_status': 'ACTIVE',
            'created_at': '2026-09-08T11:51:19.000Z',
            'service_areas': [
              {
                'area_id': 1,
                'area_name': 'Dadar West',
                'city': 'Mumbai',
                'pincode': '400028',
                'status': 'ACTIVE',
              },
            ],
          },
        }), 200, headers: {'content-type': 'application/json'});
      }

      if (path.contains('/supplier/reports')) {
        return http.Response(jsonEncode({
          'success': true,
          'reports': {
            'summary': {
              'total_subscribers': 42,
              'active_subscriptions': 58,
              'monthly_revenue': '12500.00',
              'delivery_success_rate': '97.5',
              'collection_rate': '94.2',
              'resolution_rate': '91.0',
            },
            'deliveries': {
              'total': 120,
              'delivered': 117,
              'undelivered': 3,
              'success_rate': '97.5',
            },
            'revenue': {
              'total_billed': '12500.00',
              'total_collected': '11775.00',
              'total_pending': '725.00',
              'collection_rate': '94.2',
            },
            'requests': {
              'total': 11,
              'resolved': 10,
              'pending': 1,
              'resolution_rate': '90.9',
            },
            'top_newspapers': [
              {
                'newspaper_id': 1,
                'name': 'The Times of India',
                'language': 'English',
                'subscribers': 28,
                'revenue': '5600.00',
              },
            ],
          },
        }), 200, headers: {'content-type': 'application/json'});
      }

      if (path.contains('/supplier/notifications')) {
        return http.Response(jsonEncode({
          'success': true,
          'notifications': [
            {
              'notification_id': 501,
              'notification_type': 'PAYMENT',
              'title': 'Payment Received',
              'message': 'Customer Aarav Sharma paid bill #2.',
              'is_read': 0,
              'created_at': '2026-10-25T10:00:00.000Z',
            },
            {
              'notification_id': 502,
              'notification_type': 'SYSTEM',
              'title': 'Route Auto-Generated',
              'message': 'Morning routes for Dadar West generated.',
              'is_read': 1,
              'created_at': '2026-10-24T05:00:00.000Z',
            },
          ],
        }), 200, headers: {'content-type': 'application/json'});
      }

      if (path.contains('/partner/profile')) {
        return http.Response(jsonEncode({
          'success': true,
          'profile': {
            'user_id': 3,
            'partner_id': 1,
            'partner_code': 'DP001',
            'name': 'Rahul Patil',
            'email': 'rahul@daily.com',
            'phone': '9876543212',
            'partner_status': 'AVAILABLE',
            'emergency_contact': '9988776655',
            'vehicle_type': 'Motorcycle',
            'registration_number': 'MH01AB1234',
            'shift_start': '06:00:00',
            'shift_end': '11:00:00',
          },
        }), 200, headers: {'content-type': 'application/json'});
      }

      if (path.contains('/partner/payments')) {
        final withPayments = req.headers['authorization']?.contains('with-payments') == true;
        return http.Response(jsonEncode({
          'success': true,
          'earnings': {
            'rate_per_delivery': 10,
            'completed_deliveries': withPayments ? 5 : 2,
            'calculated_total': withPayments ? 50.0 : 20.0,
            'total_earnings': withPayments ? 50.0 : 20.0,
          },
          'completed_deliveries': withPayments ? 5 : 2,
          'calculated_earnings': withPayments ? 50.0 : 20.0,
          'payments': withPayments
              ? [
                  {
                    'partner_payment_id': 101,
                    'partner_id': 1,
                    'payment_period': 'September 2026',
                    'amount': '30.00',
                    'status': 'PAID',
                    'paid_at': '2026-10-01T08:00:00.000Z',
                  }
                ]
              : [],
        }), 200, headers: {'content-type': 'application/json'});
      }

      return http.Response('{"success": true}', 200, headers: {'content-type': 'application/json'});
    });

    CustomerApiService.customClient = mockClient;
    RoleApiService.customClient = mockClient;
  });

  tearDown(() {
    CustomerApiService.customClient = null;
    RoleApiService.customClient = null;
  });

  group('Customer Repaired Screens Tests', () {
    testWidgets('ProfileDetailsScreen renders fields, validates empty inputs, and saves profile', (tester) async {
      await SessionService.saveCustomer({
        'customer_id': 1,
        'user': {
          'id': 1,
          'name': 'Aarav Sharma',
          'email': 'aarav@daily.press',
          'phone': '9876543210',
        },
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileDetailsScreen(
            customer: {
              'customer_id': 1,
              'name': 'Aarav Sharma',
              'email': 'aarav@daily.press',
              'phone': '9876543210',
              'address_line': 'Flat 401, Palm Heights',
              'city': 'Mumbai',
              'pincode': '400001',
            },
          ),
        ),
      );

      // Verify header and fields rendered
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('aarav@daily.press'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Enter edit mode
      final editButton = find.byTooltip('Edit profile');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // "SAVE PROFILE" button should appear
      expect(find.text('SAVE PROFILE'), findsOneWidget);

      // Clear name and tap save to verify empty validation
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '');
      await tester.tap(find.text('SAVE PROFILE'));
      await tester.pumpAndSettle();
      expect(find.text('Name, email, and phone number cannot be empty.'), findsOneWidget);

      // Fill valid name and tap save
      await tester.enterText(nameField, 'Aarav Sharma Updated');
      await tester.tap(find.text('SAVE PROFILE'));
      await tester.pumpAndSettle();

      // Verify successful update snackbar appears and edit mode exits
      expect(find.text('Profile details updated successfully'), findsOneWidget);
    });

    testWidgets('DeliveryHistoryScreen renders live timeline, interactive filter tabs, and search', (tester) async {
      await SessionService.saveCustomer({
        'customer_id': 1,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and titles
      expect(find.text('DELIVERY HISTORY'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);

      // Check items rendered
      expect(find.text('The Times of India'), findsOneWidget);
      expect(find.text('Hindustan Times'), findsOneWidget);
      expect(find.text('City Morning'), findsOneWidget);

      // Check interactive filter tabs
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('DELIVERED'), findsOneWidget);

      // Tap DELIVERED tab -> only The Times of India should remain visible
      await tester.tap(find.text('DELIVERED'));
      await tester.pumpAndSettle();
      expect(find.text('The Times of India'), findsOneWidget);
      expect(find.text('City Morning'), findsNothing);

      // Tap MISSED tab -> City Morning should be visible
      await tester.tap(find.text('MISSED'));
      await tester.pumpAndSettle();
      expect(find.text('City Morning'), findsOneWidget);
      expect(find.text('The Times of India'), findsNothing);

      // Search button toggles search bar
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Search input appears
      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);

      // Verify Status Guide is displayed cleanly with no mojibake
      expect(find.textContaining('STATUS GUIDE'), findsOneWidget);
      expect(find.textContaining('â€¢'), findsNothing);
    });

    testWidgets('ServiceRequestScreen handles initialRequestType automatically', (tester) async {
      await SessionService.saveCustomer({
        'customer_id': 1,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ServiceRequestScreen(initialRequestType: 'Missed Delivery'),
        ),
      );
      await tester.pumpAndSettle();

      // Dialog should be automatically opened for 'Missed Delivery'
      expect(find.text('Missed Delivery'), findsWidgets);
      expect(find.text('Describe your request details...'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('SUBMIT'), findsOneWidget);

      // Cancel dismisses dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('Describe your request details...'), findsNothing);
    });
  });

  group('Delivery Partner Repaired Screens Tests', () {
    testWidgets('PartnerProfileSubScreen renders with FAQ and no mojibake', (tester) async {
      await RoleSessionService.savePartner({
        'user_id': 3,
        'partner_id': 1,
        'name': 'Rahul Patil',
        'email': 'rahul@daily.com',
        'phone': '9876543212',
        'partner_code': 'DP001',
        'partner_status': 'AVAILABLE',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: PartnerProfileSubScreen(
            screen: ProfileSubScreen.help,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How do I start my route?'), findsOneWidget);
      // Verify no mojibake in help text
      expect(find.textContaining("Open Today's Route from your dashboard and select START ROUTE."), findsOneWidget);
      expect(find.textContaining('â€™'), findsNothing);
    });

    testWidgets('PartnerEarningsScreen renders calculated earnings and handles empty payments correctly', (tester) async {
      await RoleSessionService.savePartner({
        'user_id': 3,
        'partner_id': 1,
        'name': 'Rahul Patil',
        'partner_code': 'DP001',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PartnerEarningsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Top title and subtitle
      expect(find.text('My earnings'), findsOneWidget);
      expect(find.text('2 completed deliveries (₹10/delivery)'), findsOneWidget);

      // Section header and total earnings card
      expect(find.text('CALCULATED EARNINGS'), findsOneWidget);
      expect(find.text('TOTAL EARNINGS'), findsOneWidget);
      expect(find.text('₹20.00'), findsOneWidget);
      expect(find.text('DELIVERIES: 2'), findsOneWidget);
      expect(find.text('RATE: ₹10/delivery'), findsOneWidget);

      // Payment history section and empty state
      expect(find.text('PAYMENT HISTORY'), findsOneWidget);
      expect(find.text('No payment history recorded yet.'), findsOneWidget);
      expect(find.text('No earnings recorded yet.'), findsNothing);
    });

    testWidgets('PartnerEarningsScreen renders actual payment history and disbursed/pending breakdown', (tester) async {
      await RoleSessionService.savePartner({
        'user_id': 3,
        'partner_id': 1,
        'name': 'Rahul Patil',
        'partner_code': 'DP001',
        'session_token': 'test-with-payments-token',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PartnerEarningsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Top title and subtitle
      expect(find.text('My earnings'), findsOneWidget);
      expect(find.text('5 completed deliveries • 1 payment record'), findsOneWidget);

      // Section header and total earnings card
      expect(find.text('CALCULATED EARNINGS'), findsOneWidget);
      expect(find.text('TOTAL EARNINGS'), findsOneWidget);
      expect(find.text('₹50.00'), findsOneWidget);
      expect(find.text('DELIVERIES: 5'), findsOneWidget);
      expect(find.text('RATE: ₹10/delivery'), findsOneWidget);

      // Disbursed & Pending amounts
      expect(find.text('DISBURSED: ₹30.00'), findsOneWidget);
      expect(find.text('PENDING: ₹20.00'), findsOneWidget);

      // Payment history item
      expect(find.text('PAYMENT HISTORY'), findsOneWidget);
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('₹30.00'), findsWidgets);
      expect(find.text('PAID'), findsOneWidget);
    });
  });

  group('Supplier Repaired Screens Tests', () {
    testWidgets('SupplierReportsScreen renders real KPIs and newspaper circulation', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Operational Reports'), findsOneWidget);

      // KPI Metric Cards
      expect(find.text('TOTAL SUBSCRIBERS'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('MONTHLY RECURRING'), findsOneWidget);
      expect(find.text('₹12500.00'), findsWidgets);
      expect(find.text('DELIVERY FULFILLMENT'), findsOneWidget);
      expect(find.text('97.5%'), findsWidgets);

      // Circulation breakdown
      expect(find.text('NEWSPAPER CIRCULATION BREAKDOWN'), findsOneWidget);
      expect(find.text('The Times of India'), findsOneWidget);
      expect(find.text('28 subs'), findsOneWidget);
    });

    testWidgets('SupplierProfileScreen renders real sections, service areas, and opens edit dialog', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
        'name': 'Mumbai Daily Admin',
        'supplier_name': 'Mumbai Daily Distributors',
        'email': 'admin@mumbaidaily.com',
        'phone': '9876543214',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header and Edit button
      expect(find.text('Supplier Profile'), findsOneWidget);
      expect(find.text('EDIT PROFILE'), findsOneWidget);

      // Verify sections
      expect(find.text('BUSINESS INFORMATION'), findsOneWidget);
      expect(find.text('SERVICE AREAS'), findsOneWidget);
      expect(find.text('ACCOUNT & COMMUNICATIONS'), findsOneWidget);
      expect(find.text('SUPPORT & INFORMATION'), findsOneWidget);

      // Verify service area is rendered
      expect(find.text('Dadar West, Mumbai'), findsWidgets);

      // Verify inaccurate warning banner was removed
      expect(find.textContaining('Profile editing, notification preferences, service-area management and Supplier profile retrieval are not currently supported'), findsNothing);

      // Tap EDIT PROFILE
      await tester.tap(find.text('EDIT PROFILE'));
      await tester.pumpAndSettle();

      // Dialog fields appear
      expect(find.text('Edit Supplier Profile'), findsOneWidget);
      expect(find.text('Distributor / Supplier Name'), findsOneWidget);
      expect(find.text('Contact Person Name'), findsOneWidget);
      expect(find.text('SAVE CHANGES'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Supplier Profile'), findsNothing);
    });

    testWidgets('SupplierCommunicationScreen renders filter tabs and notifications list', (tester) async {
      await RoleSessionService.saveSupplier({
        'user_id': 5,
        'supplier_id': 1,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SupplierCommunicationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Communications & Alerts'), findsOneWidget);
      expect(find.text('Notifications & Broadcasts'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('UNREAD'), findsOneWidget);
      expect(find.text('READ'), findsOneWidget);

      // Verify notifications rendered
      expect(find.text('Payment Received'), findsOneWidget);
      expect(find.text('Customer Aarav Sharma paid bill #2.'), findsOneWidget);
      expect(find.text('Route Auto-Generated'), findsOneWidget);
      expect(find.text('MARK AS READ'), findsOneWidget);
    });
  });
}
