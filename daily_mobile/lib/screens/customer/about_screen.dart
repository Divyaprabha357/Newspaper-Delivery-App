import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'About Us',
                onBack: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: const [
                  Text(
                    'DAILY',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: DailyColors.burgundy,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'DAILY makes newspaper delivery simple, reliable and easy to manage. Choose the publications you trust and receive them at your doorstep every morning.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 22),
                  SectionLabel('How DAILY works'),
                  SizedBox(height: 10),
                  Text(
                    'Browse available newspapers, subscribe in a few taps, and use the DAILY customer app to manage deliveries, payments and support requests.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 22),
                  SectionLabel('Support'),
                  SizedBox(height: 10),
                  Text(
                    'For help with delivery, subscriptions or payments, use Ask Help or contact the DAILY support team.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


