import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/customer/customer_dashboard_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await SessionService.isCustomerLoggedIn();
  runApp(DailyApp(isLoggedIn: isLoggedIn));
}

class DailyApp extends StatelessWidget {
  final bool isLoggedIn;

  const DailyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DAILY',
      theme: AppTheme.lightTheme,
      home: isLoggedIn
          ? const CustomerDashboardScreen()
          : const WelcomeScreen(),
    );
  }
}
