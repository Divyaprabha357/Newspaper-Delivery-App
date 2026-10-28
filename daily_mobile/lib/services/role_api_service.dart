import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'role_session_service.dart';

class RoleApiException implements Exception {
  final String message;
  final int? statusCode;

  const RoleApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNetworkError => statusCode == null || statusCode == 0;

  @override
  String toString() => message;
}

class RoleApiService {
  static http.Client? customClient;

  RoleApiService({
    http.Client? client,
    String? baseUrl,
    this.authToken,
  })  : _client = client ?? customClient ?? http.Client(),
        _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;
  final String? authToken;

  Future<Map<String, dynamic>> login({
    String? emailOrPhone,
    String? partnerCode,
    required String password,
    String? role,
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
          if (role != null && role.isNotEmpty)
            'role': role,
        },
      );

  Future<Map<String, dynamic>> registerPartner({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? emergencyContact,
    String? vehicleType,
    String? registrationNumber,
    String shiftStart = '06:00:00',
    String shiftEnd = '11:00:00',
  }) =>
      _request(
        '/partner/register',
        method: 'POST',
        body: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          if (emergencyContact != null && emergencyContact.isNotEmpty)
            'emergency_contact': emergencyContact,
          if (vehicleType != null && vehicleType.isNotEmpty)
            'vehicle_type': vehicleType,
          if (registrationNumber != null && registrationNumber.isNotEmpty)
            'registration_number': registrationNumber,
          'shift_start': shiftStart,
          'shift_end': shiftEnd,
        },
      );

  Future<Map<String, dynamic>> supplierProfile(int userId) =>
      _get('/supplier/profile', userId);

  Future<Map<String, dynamic>> supplierNewspapers(int userId) =>
      _get('/supplier/newspapers', userId);

  Future<Map<String, dynamic>> supplierSubscriptions(int userId) =>
      _get('/supplier/subscriptions', userId);

  Future<Map<String, dynamic>> supplierDistribution(
    int userId, {
    int? supplierId,
    String? date,
  }) =>
      _get('/supplier/distribution', userId, supplierId: supplierId, date: date);

  Future<Map<String, dynamic>> supplierRoutes(
    int userId, {
    int? supplierId,
    String? date,
  }) =>
      _get('/supplier/routes', userId, supplierId: supplierId, date: date);

  Future<Map<String, dynamic>> supplierPartners(
    int userId, {
    int? supplierId,
    String? date,
  }) =>
      _get('/supplier/partners', userId, supplierId: supplierId, date: date);

  Future<Map<String, dynamic>> supplierDeliveries(
    int userId, {
    int? supplierId,
    String? date,
  }) =>
      _get('/supplier/deliveries', userId, supplierId: supplierId, date: date);

  Future<Map<String, dynamic>> supplierPayments(int userId, {int? supplierId}) =>
      _get('/supplier/payments', userId, supplierId: supplierId);

  Future<Map<String, dynamic>> supplierRequests(int userId, {int? supplierId}) =>
      _get('/supplier/requests', userId, supplierId: supplierId);

  Future<Map<String, dynamic>> updateSupplierRequestStatus({
    required int userId,
    int? supplierId,
    required int requestId,
    required String status,
  }) =>
      _request(
        '/supplier/requests/$requestId/status',
        method: 'PATCH',
        headers: {
          'X-User-Id': '$userId',
          'X-Supplier-Id': ?supplierId?.toString(),
        },
        body: {'status': status},
      );

  Future<Map<String, dynamic>> updateSupplierComplaintStatus({
    required int userId,
    int? supplierId,
    required int complaintId,
    required String status,
    String? resolution,
  }) =>
      _request(
        '/supplier/complaints/$complaintId/status',
        method: 'PATCH',
        headers: {
          'X-User-Id': '$userId',
          'X-Supplier-Id': ?supplierId?.toString(),
        },
        body: {
          'status': status,
          'resolution': ?resolution,
        },
      );

  Future<Map<String, dynamic>> supplierNotifications(int userId) =>
      _get('/supplier/notifications', userId);

  Future<Map<String, dynamic>> updateSupplierProfile({
    required int userId,
    int? supplierId,
    String? name,
    String? email,
    String? phone,
    String? supplierName,
    String? contactNumber,
    String? address,
  }) =>
      _request(
        '/supplier/profile?user_id=$userId${supplierId != null ? '&supplier_id=$supplierId' : ''}',
        method: 'PUT',
        headers: {
          'X-User-Id': '$userId',
          if (supplierId != null) 'X-Supplier-Id': '$supplierId',
        },
        body: {
          'name': ?name,
          'email': ?email,
          'phone': ?phone,
          'supplier_name': ?supplierName,
          'contact_number': ?contactNumber,
          'address': ?address,
        },
      );

  Future<Map<String, dynamic>> supplierReports(int userId, {int? supplierId}) =>
      _get('/supplier/reports', userId, supplierId: supplierId);

  Future<Map<String, dynamic>> markSupplierNotificationRead({
    required int userId,
    int? supplierId,
    required int notificationId,
  }) =>
      _request(
        '/supplier/notifications/$notificationId/read?user_id=$userId${supplierId != null ? '&supplier_id=$supplierId' : ''}',
        method: 'PATCH',
        headers: {
          'X-User-Id': '$userId',
          if (supplierId != null) 'X-Supplier-Id': '$supplierId',
        },
      );

  Future<Map<String, dynamic>> updatePartnerProfile({
    required int userId,
    int? partnerId,
    String? name,
    String? email,
    String? phone,
    String? emergencyContact,
    String? registrationNumber,
    String? vehicleType,
    String? status,
  }) =>
      _request(
        '/partner/profile?user_id=$userId${partnerId != null ? '&partner_id=$partnerId' : ''}',
        method: 'PUT',
        headers: {
          'X-User-Id': '$userId',
          if (partnerId != null) 'X-Partner-Id': '$partnerId',
        },
        body: {
          'name': ?name,
          'email': ?email,
          'phone': ?phone,
          'emergency_contact': ?emergencyContact,
          'registration_number': ?registrationNumber,
          'vehicle_type': ?vehicleType,
          'status': ?status,
        },
      );

  Future<Map<String, dynamic>> markPartnerNotificationRead({
    required int userId,
    int? partnerId,
    required int notificationId,
  }) =>
      _request(
        '/partner/notifications/$notificationId/read?user_id=$userId${partnerId != null ? '&partner_id=$partnerId' : ''}',
        method: 'PATCH',
        headers: {
          'X-User-Id': '$userId',
          if (partnerId != null) 'X-Partner-Id': '$partnerId',
        },
      );


  Future<Map<String, dynamic>> partnerProfile(int userId, {int? partnerId}) =>
      _get('/partner/profile', userId, partnerId: partnerId);

  Future<Map<String, dynamic>> partnerRoutes(int userId, {int? partnerId, String? date}) =>
      _get('/partner/routes', userId, partnerId: partnerId, date: date);

  Future<Map<String, dynamic>> partnerDeliveries(int userId, {int? partnerId, String? date}) =>
      _get('/partner/deliveries', userId, partnerId: partnerId, date: date);

  Future<Map<String, dynamic>> partnerFailureReasons(int userId, {int? partnerId}) =>
      _get('/partner/failure-reasons', userId, partnerId: partnerId);

  Future<Map<String, dynamic>> partnerPayments(int userId, {int? partnerId}) =>
      _get('/partner/payments', userId, partnerId: partnerId);

  Future<Map<String, dynamic>> partnerNotifications(int userId, {int? partnerId}) =>
      _get('/partner/notifications', userId, partnerId: partnerId);

  Future<Map<String, dynamic>> updatePartnerDelivery({
    required int userId,
    int? partnerId,
    required int deliveryId,
    int? assignmentId,
    required String status,
    int? failureReasonId,
    String? remarks,
    List<Map<String, dynamic>> items = const [],
  }) =>
      _request(
        '/partner/deliveries/$deliveryId/status',
        method: 'PATCH',
        headers: {
          'X-User-Id': '$userId',
          'X-Partner-Id': '${partnerId ?? userId}',
        },
        body: {
          'user_id': userId,
          'partner_id': partnerId ?? userId,
          'assignment_id': ?assignmentId,
          'status': status,
          'failure_reason_id': failureReasonId,
          'remarks': remarks,
          'items': items,
        },
      );

  Future<Map<String, dynamic>> _get(
    String path,
    int userId, {
    int? supplierId,
    int? partnerId,
    String? date,
  }) {
    final isSupplier = path.contains('supplier');
    final isPartner = path.contains('partner');
    final sId = isSupplier ? (supplierId ?? userId) : supplierId;
    final pId = isPartner ? (partnerId ?? userId) : partnerId;
    final query = <String, String>{
      'user_id': '$userId',
      if (sId != null) 'supplier_id': '$sId',
      if (pId != null) 'partner_id': '$pId',
    };
    if (date != null) query['date'] = date;
    return _request(
      '$path?${Uri(queryParameters: query).query}',
      headers: {
        'X-User-Id': '$userId',
        if (sId != null) 'X-Supplier-Id': '$sId',
        if (pId != null) 'X-Partner-Id': '$pId',
      },
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
      if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
      ...?headers,
    };
    try {
      response = switch (method) {
        'POST' => await _client.post(uri, headers: requestHeaders, body: jsonEncode(body)),
        'PUT' => await _client.put(uri, headers: requestHeaders, body: jsonEncode(body)),
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
        if (response.statusCode == 502 || response.statusCode == 504) {
          throw RoleApiException(
            'The DAILY server gateway is temporarily unavailable (HTTP ${response.statusCode}). Please try again in a moment.',
            statusCode: response.statusCode,
          );
        }
        if (response.statusCode == 404) {
          throw const RoleApiException(
            'The requested endpoint was not found on the server (HTTP 404).',
            statusCode: 404,
          );
        }
        throw RoleApiException(
          'The DAILY server returned an unexpected response (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] == false) {
      final msg = (data['message'] as String?) ??
          (data['error'] as String?) ??
          'The DAILY server could not complete the request (HTTP ${response.statusCode}).';
      if (response.statusCode == 401 && path != '/login' && !path.contains('register')) {
        if (path.contains('partner')) {
          await RoleSessionService.clearPartner();
        } else if (path.contains('supplier')) {
          await RoleSessionService.clearSupplier();
        }
      }
      throw RoleApiException(
        msg,
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
