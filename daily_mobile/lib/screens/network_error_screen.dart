import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/daily_widgets.dart';

class NetworkErrorScreen extends StatelessWidget {
  const NetworkErrorScreen({super.key});

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
                title: 'Network Error',
                onBack: () => Navigator.pop(context),
                trailing: const SizedBox(width: 20),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 38),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 210,
                      height: 150,
                      color: const Color(0xFFD9D1C8),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_off,
                          size: 55,
                          color: DailyColors.gray,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'No Internet Connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 9),

                    const Text(
                      'Check your network and try again. '
                      'Your morning news is waiting for you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: DailyColors.gray,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    PrimaryButton(
                      label: '↻  RETRY',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Still offline.')),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DailyColors.divider),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text(
                          'GO TO HOME',
                          style: TextStyle(
                            fontSize: 9,
                            color: DailyColors.charcoal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 22),
              child: Text(
                'EST. 2026 • DAILY NEWS CO.',
                style: TextStyle(
                  fontSize: 8,
                  color: DailyColors.gray,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
