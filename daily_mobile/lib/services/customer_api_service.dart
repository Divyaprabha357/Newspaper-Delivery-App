import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session_service.dart';

class CustomerApiException implements Exception {
  final String message;
  final int? statusCode;

  const CustomerApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNetworkError => statusCode == null || statusCode == 0;

  @override
  String toString() => message;
}

class CustomerApiService {
  static http.Client? customClient;

  CustomerApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? customClient ?? http.Client(),
        _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
    String? role,
  }) {
    return _request(
      '/login',
      method: 'POST',
      body: {
        'emailOrPhone': emailOrPhone,
        'password': password,
        if (role != null && role.isNotEmpty) 'role': role,
      },
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
    String? preferredDeliveryTime,
  }) {
    return _request(
      '/register',
      method: 'POST',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'password': password,
        'preferred_delivery_time': ?preferredDeliveryTime,
      },
    );
  }

  Future<Map<String, dynamic>> profile(int customerId) =>
      _request('/customer-profile?customer_id=$customerId');

  Future<Map<String, dynamic>> updateProfile(
    int customerId, {
    required String name,
    required String email,
    required String phone,
  }) =>
      _request(
        '/customer-profile/$customerId',
        method: 'PUT',
        body: {'name': name, 'email': email, 'phone': phone},
      );

  Future<Map<String, dynamic>> subscriptions(int customerId) =>
      _request('/subscriptions?customer_id=$customerId');

  Future<Map<String, dynamic>> updateSubscription(
    int customerId,
    int subscriptionId,
    String status,
  ) =>
      _request(
        '/subscriptions/$subscriptionId/status',
        method: 'PATCH',
        body: {'customer_id': customerId, 'status': status},
      );

  Future<Map<String, dynamic>> subscriptionDetail(
    int customerId,
    int subscriptionId,
  ) =>
      _request('/subscriptions/$subscriptionId?customer_id=$customerId');

  Future<Map<String, dynamic>> changeSubscriptionNewspaper({
    required int customerId,
    required int subscriptionId,
    required int newNewspaperId,
    required int newSupplierId,
  }) =>
      _request(
        '/subscriptions/$subscriptionId/change-newspaper',
        method: 'PATCH',
        body: {
          'customer_id': customerId,
          'new_newspaper_id': newNewspaperId,
          'new_supplier_id': newSupplierId,
        },
      );

  Future<Map<String, dynamic>> newspapers() => _request('/newspapers');

  Future<Map<String, dynamic>> createSubscription({
    required int customerId,
    required int newspaperId,
    required int supplierId,
    String deliveryDays = 'MON,TUE,WED,THU,FRI,SAT,SUN',
    String scheduledDeliveryTime = '07:00:00',
  }) =>
      _request(
        '/subscriptions',
        method: 'POST',
        body: {
          'customer_id': customerId,
          'newspaper_id': newspaperId,
          'supplier_id': supplierId,
          'delivery_days': deliveryDays,
          'scheduled_delivery_time': scheduledDeliveryTime,
        },
      );

  Future<Map<String, dynamic>> deliveryHistory(int customerId) =>
      _request('/delivery-history?customer_id=$customerId');

  Future<Map<String, dynamic>> payments(int customerId) =>
      _request('/payments?customer_id=$customerId');

  Future<Map<String, dynamic>> payBill({
    required int customerId,
    int? billId,
    double? amount,
    String paymentMethod = 'UPI',
  }) =>
      _request(
        '/payments',
        method: 'POST',
        body: {
          'customer_id': customerId,
          'bill_id': ?billId,
          'amount': ?amount,
          'payment_method': paymentMethod,
        },
      );


  Future<Map<String, dynamic>> requests(int customerId) =>
      _request('/requests?customer_id=$customerId');

  Future<Map<String, dynamic>> createRequest({
    required int customerId,
    required String requestType,
    int? referenceId,
    required String description,
  }) =>
      _request(
        '/requests',
        method: 'POST',
        body: {
          'customer_id': customerId,
          'request_type': requestType,
          'reference_id': referenceId,
          'description': description,
        },
      );

  Future<Map<String, dynamic>> notifications(int customerId) =>
      _request('/notifications?customer_id=$customerId');

  Future<Map<String, dynamic>> markNotificationRead(
    int customerId,
    int notificationId,
  ) =>
      _request(
        '/notifications/$notificationId/read',
        method: 'PATCH',
        body: {'customer_id': customerId},
      );

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    late http.Response response;
    try {
      response = switch (method) {
        'POST' => await _client.post(uri, headers: _headers, body: jsonEncode(body)),
        'PUT' => await _client.put(uri, headers: _headers, body: jsonEncode(body)),
        'PATCH' => await _client.patch(uri, headers: _headers, body: jsonEncode(body)),
        _ => await _client.get(uri, headers: _headers),
      };
    } on Exception {
      throw const CustomerApiException('Unable to connect to the DAILY server.');
    }

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } on FormatException {
        if (response.statusCode == 502 || response.statusCode == 504) {
          throw CustomerApiException(
            'The DAILY server gateway is temporarily unavailable (HTTP ${response.statusCode}). Please try again in a moment.',
            statusCode: response.statusCode,
          );
        }
        if (response.statusCode == 404) {
          throw const CustomerApiException(
            'The requested endpoint was not found on the server (HTTP 404).',
            statusCode: 404,
          );
        }
        throw CustomerApiException(
          'The DAILY server returned an unexpected response (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || data['success'] == false) {
      final msg = (data['message'] as String?) ??
          (data['error'] as String?) ??
          'The DAILY server could not complete the request (HTTP ${response.statusCode}).';
      if (response.statusCode == 401 && path != '/login' && path != '/register' && path != '/customer/register') {
        await SessionService.logOut();
      }
      throw CustomerApiException(
        msg,
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  Map<String, String> get _headers => const {'Content-Type': 'application/json'};
}
