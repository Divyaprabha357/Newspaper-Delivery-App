import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _loggedInKey = 'customer_logged_in';

  static Future<bool> isCustomerLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_loggedInKey) ?? false;
  }

  static Future<void> setCustomerLoggedIn() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_loggedInKey, true);
  }

  static Future<void> logOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_loggedInKey);
  }
}
