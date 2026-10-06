import 'package:flutter/material.dart';

import '../../widgets/daily_widgets.dart';

enum LoginType { phone, email }

class LoginScreen extends StatefulWidget {
  final LoginType loginType;

  const LoginScreen({super.key, required this.loginType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhone = widget.loginType == LoginType.phone;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const SizedBox(height: 25),

                    const Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2A28),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isPhone
                          ? 'Sign in using your phone number.'
                          : 'Sign in using your email address.',

                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),

                    const SizedBox(height: 45),

                    // ------------------------------------------------
                    // PHONE / EMAIL
                    // ------------------------------------------------
                    TextField(
                      controller: identifierController,

                      keyboardType: isPhone
                          ? TextInputType.phone
                          : TextInputType.emailAddress,

                      decoration: InputDecoration(
                        labelText: isPhone ? 'Phone Number' : 'Email Address',

                        hintText: isPhone
                            ? 'Enter your phone number'
                            : 'Enter your email address',

                        prefixIcon: Icon(
                          isPhone ? Icons.phone_outlined : Icons.email_outlined,
                        ),

                        filled: true,
                        fillColor: const Color(0xFFE6D6C8),

                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
                        ),

                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
                        ),

                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF7A1F1F),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ------------------------------------------------
                    // PASSWORD
                    // ------------------------------------------------
                    TextField(
                      controller: passwordController,

                      obscureText: obscurePassword,

                      decoration: InputDecoration(
                        labelText: 'Password',

                        hintText: 'Enter your password',

                        prefixIcon: const Icon(Icons.lock_outline),

                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),

                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),

                        filled: true,
                        fillColor: const Color(0xFFE6D6C8),

                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
                        ),

                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC1B6A8)),
                        ),

                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF7A1F1F),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,

                      child: TextButton(
                        onPressed: () {},

                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFF7A1F1F)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ------------------------------------------------
                    // LOGIN BUTTON
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A1F1F),
                          foregroundColor: Colors.white,

                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),

                        onPressed: () {
                          if (identifierController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter your login details.',
                                ),
                              ),
                            );

                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Login will be connected to the DAILY database.',
                              ),
                            ),
                          );
                        },

                        child: const Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
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
