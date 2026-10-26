import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/daily_widgets.dart';
import 'customer/auth_screen.dart';
import 'delivery_partner/delivery_partner_app_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _open(BuildContext context, String role) {
    if (role == 'DELIVERY_PARTNER') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryPartnerAppScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 25, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            border: Border.all(color: DailyColors.burgundy),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.newspaper_outlined,
                            color: DailyColors.burgundy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'DAILY',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: DailyColors.burgundy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Choose Your Role',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Rule(),
                    const SizedBox(height: 16),
                    _role(
                      context,
                      Icons.person_outline,
                      'CUSTOMER',
                      'Subscribe to newspapers and manage deliveries',
                      'CUSTOMER',
                    ),
                    const SizedBox(height: 14),
                    _role(
                      context,
                      Icons.delivery_dining_outlined,
                      'DELIVERY PARTNER',
                      'View assigned deliveries and manage delivery tasks',
                      'DELIVERY_PARTNER',
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: GestureDetector(
                        onTap: () => _open(context, 'CUSTOMER'),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: DailyColors.gray,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: DailyColors.burgundy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 64,
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: DailyColors.divider)),
              ),
              child: const Center(
                child: Text(
                  'D A I L Y  E D I T O R I A L  G R O U P  •  E S T A B L I S H E D  2 0 2 6',
                  style: TextStyle(
                    fontSize: 8,
                    color: DailyColors.gray,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _role(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String role,
  ) {
    return InkWell(
      onTap: () => _open(context, role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: const Color(0xFFEDE4DA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F0EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEAD7D0)),
              ),
              child: Icon(icon, color: DailyColors.burgundy, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: DailyColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DailyColors.gray,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: DailyColors.gray, size: 22),
          ],
        ),
      ),
    );
  }
}
