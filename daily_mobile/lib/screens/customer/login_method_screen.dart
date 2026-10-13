import 'package:flutter/material.dart';

import '../../widgets/daily_widgets.dart';
import 'login_screen.dart';

class LoginMethodScreen extends StatelessWidget {
  const LoginMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5ECE0),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
              child: DailyHeader(
                title: 'Sign In',
                onBack: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const SizedBox(height: 25),

                    const Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2A28),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Choose how you want to sign in.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF8A8A8A)),
                    ),

                    const SizedBox(height: 45),

                    _LoginOption(
                      title: 'PHONE NUMBER',
                      icon: Icons.phone_outlined,

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LoginScreen(loginType: LoginType.phone),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    _LoginOption(
                      title: 'EMAIL',
                      icon: Icons.email_outlined,

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LoginScreen(loginType: LoginType.email),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    _LoginOption(
                      title: 'GOOGLE',
                      icon: Icons.g_mobiledata,

                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Google Sign-In will be connected later.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// LOGIN OPTION
// ------------------------------------------------------------

class _LoginOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LoginOption({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),

        decoration: BoxDecoration(
          color: const Color(0xFFE6D6C8),

          border: Border.all(color: const Color(0xFFC1B6A8)),
        ),

        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7A1F1F), size: 28),

            const SizedBox(width: 18),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF2B2A28),
                ),
              ),
            ),

            const Icon(Icons.chevron_right, color: Color(0xFF7A1F1F)),
          ],
        ),
      ),
    );
  }
}


