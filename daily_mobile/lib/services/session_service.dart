import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionService {
  static const _loggedInKey = 'customer_logged_in';
  static const _customerKey = 'customer_session';

  static Future<bool> isCustomerLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_loggedInKey) == true &&
        preferences.getString(_customerKey) != null;
  }

  static Future<void> saveCustomer(Map<String, dynamic> customer) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_loggedInKey, true);
    await preferences.setString(_customerKey, jsonEncode(customer));
  }

  static Future<Map<String, dynamic>?> getCustomer() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_customerKey);
    if (value == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(value) as Map);
    } on FormatException {
      await logOut();
      return null;
    }
  }

  static Future<int?> getCustomerId() async {
    final customer = await getCustomer();
    final id = customer?['customer_id'];
    return id is int ? id : int.tryParse('$id');
  }

  static Future<void> logOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_loggedInKey);
    await preferences.remove(_customerKey);
  }
}
