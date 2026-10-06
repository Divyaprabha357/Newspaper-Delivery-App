import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'role_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'DAILY',
                style: TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.bold,
                  height: .95,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your newspaper\nDelivered daily.',
                style: TextStyle(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: DailyColors.gray,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE8E1),
                    border: Border.all(color: DailyColors.divider),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'A simpler way to stay informed,\nevery day.',
                style: TextStyle(
                  fontSize: 16,
                  color: DailyColors.gray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'B E G I N   R E A D I N G',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: DailyColors.burgundy,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: DailyColors.divider, thickness: 1),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 5,
                      decoration: BoxDecoration(
                        color: DailyColors.burgundy,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: DailyColors.divider,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
