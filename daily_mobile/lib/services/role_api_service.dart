import 'dart:convert';

import 'package:http/http.dart' as http;

class RoleApiException implements Exception {
  final String message;
  final int? statusCode;

  const RoleApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class RoleApiService {
  RoleApiService({
    http.Client? client,
    String? baseUrl,
    this.authToken,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? const String.fromEnvironment(
          'DAILY_API_BASE_URL',
          defaultValue: 'http://localhost:5000/api',
        )).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  final String? authToken;

  Future<Map<String, dynamic>> login({
    String? emailOrPhone,
    String? partnerCode,
    required String password,
  }) =>
      _request(
        '/login',
        method: 'POST',
        body: {
          if (emailOrPhone != null && emailOrPhone.isNotEmpty)
            'emailOrPhone': emailOrPhone,
          if (partnerCode != null && partnerCode.isNotEmpty)
            'partnerCode': partnerCode,
          'password': password,
        },
      );

  Future<Map<String, dynamic>> supplierProfile(int userId) =>
      _get('/supplier/profile', userId);

  Future<Map<String, dynamic>> supplierNewspapers(int userId) =>
      _get('/supplier/newspapers', userId);

  Future<Map<String, dynamic>> supplierSubscriptions(int userId) =>
      _get('/supplier/subscriptions', userId);

  Future<Map<String, dynamic>> supplierDeliveries(int userId, {String? date}) =>
      _get('/supplier/deliveries', userId, date: date);

  Future<Map<String, dynamic>> supplierPayments(int userId) =>
      _get('/supplier/payments', userId);

  Future<Map<String, dynamic>> supplierNotifications(int userId) =>
      _get('/supplier/notifications', userId);

  Future<Map<String, dynamic>> partnerProfile(int userId) =>
      _get('/partner/profile', userId);

  Future<Map<String, dynamic>> partnerRoutes(int userId, {String? date}) =>
      _get('/partner/routes', userId, date: date);

  Future<Map<String, dynamic>> partnerDeliveries(int userId, {String? date}) =>
      _get('/partner/deliveries', userId, date: date);

  Future<Map<String, dynamic>> partnerFailureReasons(int userId) =>
      _get('/partner/failure-reasons', userId);

  Future<Map<String, dynamic>> partnerPayments(int userId) =>
      _get('/partner/payments', userId);

  Future<Map<String, dynamic>> partnerNotifications(int userId) =>
      _get('/partner/notifications', userId);

  Future<Map<String, dynamic>> updatePartnerDelivery({
    required int userId,
    required int deliveryId,
    required String status,
    int? failureReasonId,
    String? remarks,
    List<Map<String, dynamic>> items = const [],
  }) =>
      _request(
        '/partner/deliveries/$deliveryId/status',
        method: 'PATCH',
        body: {
          'user_id': userId,
          'status': status,
          'failure_reason_id': failureReasonId,
          'remarks': remarks,
          'items': items,
        },
      );

  Future<Map<String, dynamic>> _get(
    String path,
    int userId, {
    String? date,
  }) {
    final query = <String, String>{'user_id': '$userId'};
    if (date != null) query['date'] = date;
    return _request(
      '$path?${Uri(queryParameters: query).query}',
      headers: {'X-User-Id': '$userId'},
    );
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    late http.Response response;
    final uri = Uri.parse('$_baseUrl$path');
    final requestHeaders = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
      ...?headers,
    };
    try {
      response = switch (method) {
        'POST' => await _client.post(uri, headers: requestHeaders, body: jsonEncode(body)),
        'PATCH' => await _client.patch(uri, headers: requestHeaders, body: jsonEncode(body)),
        _ => await _client.get(uri, headers: requestHeaders),
      };
    } on Exception {
      throw const RoleApiException('Unable to connect to the DAILY server.');
    }

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      } on FormatException {
        throw const RoleApiException('The DAILY server returned an invalid response.');
      }
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] == false) {
      throw RoleApiException(
        (data['message'] as String?) ?? 'The DAILY server could not complete the request.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
