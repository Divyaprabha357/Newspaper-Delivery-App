import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class FeedbackAlertScreen extends StatelessWidget {
  const FeedbackAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
                  child: DailyHeader(
                    title: 'Feedback & Alerts',
                    onBack: () => Navigator.pop(context),
                    trailing: const Icon(Icons.search, size: 22),
                  ),
                ),
                Expanded(child: Container(color: const Color(0x66555555))),
              ],
            ),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth.clamp(0.0, 340.0),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    color: DailyColors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              size: 22,
                              color: DailyColors.gray,
                            ),
                          ),
                        ),
                        Container(
                          width: 65,
                          height: 65,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE9F0E1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.newspaper_outlined,
                            size: 33,
                            color: DailyColors.oliveDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Subscription\nConfirmed!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'The Times of India has been successfully added to your active subscriptions. Your first copy arrives tomorrow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: DailyColors.gray,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DailyColors.burgundy,
                              foregroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: const Text(
                              'View Subscriptions',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Go to Home',
                            style: TextStyle(
                              fontSize: 12,
                              color: DailyColors.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


