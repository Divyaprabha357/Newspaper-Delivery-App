import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RoleSessionService {
  static const _supplierKey = 'supplier_session';
  static const _partnerKey = 'delivery_partner_session';

  static Future<void> saveSupplier(Map<String, dynamic> user) =>
      _save(_supplierKey, user);

  static Future<void> savePartner(Map<String, dynamic> user) =>
      _save(_partnerKey, user);

  static Future<Map<String, dynamic>?> getSupplier() => _get(_supplierKey);

  static Future<Map<String, dynamic>?> getPartner() => _get(_partnerKey);

  static Future<void> clearSupplier() => _clear(_supplierKey);

  static Future<void> clearPartner() => _clear(_partnerKey);

  static Future<void> _save(String key, Map<String, dynamic> value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> _get(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(key);
    if (value == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    } on FormatException {
      await _clear(key);
      return null;
    }
  }

  static Future<void> _clear(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
