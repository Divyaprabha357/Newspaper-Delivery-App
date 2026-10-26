import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DailyApp());
}

class DailyApp extends StatelessWidget {
  final bool? isLoggedIn;
  final Widget? home;

  const DailyApp({super.key, this.isLoggedIn, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DAILY',
      theme: AppTheme.lightTheme,
      home: home ?? const SplashScreen(),
    );
  }
}
