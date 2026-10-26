import 'package:flutter/material.dart';

import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';
import '../../widgets/daily_widgets.dart';
import 'customer_dashboard_screen.dart';

enum LoginType { phone, email }

class LoginScreen extends StatefulWidget {
  final LoginType loginType;
  final CustomerApiService? apiService;

  const LoginScreen({
    super.key,
    required this.loginType,
    this.apiService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool loading = false;

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
                        fontSize: 24,
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

                        onPressed: loading ? () {} : () async {
                          if (loading) return;

                          final rawId = identifierController.text.trim();
                          final rawPassword = passwordController.text;

                          if (rawId.isEmpty) {
                            _snack(isPhone
                                ? 'Please enter your phone number.'
                                : 'Please enter your email address.');
                            return;
                          }

                          if (isPhone) {
                            final digits = rawId.replaceAll(RegExp(r'\D'), '');
                            if (digits.length < 10) {
                              _snack('Please enter a valid 10-digit phone number.');
                              return;
                            }
                          } else {
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(rawId)) {
                              _snack('Please enter a valid email address.');
                              return;
                            }
                          }

                          if (rawPassword.isEmpty) {
                            _snack('Please enter your password.');
                            return;
                          }

                          setState(() => loading = true);
                          final nav = Navigator.of(context);
                          try {
                            final api = widget.apiService ?? CustomerApiService();
                            final data = await api.login(
                              emailOrPhone: rawId,
                              password: rawPassword,
                              role: 'CUSTOMER',
                            );
                            final user = Map<String, dynamic>.from(
                                data['user'] as Map? ?? {});
                            final role =
                                (user['role'] ?? '').toString().toUpperCase();
                            if (role != 'CUSTOMER' ||
                                user['customer_id'] == null) {
                              throw const CustomerApiException(
                                'This account is not authorized as a Customer account.',
                                statusCode: 403,
                              );
                            }
                            await SessionService.saveCustomer(user);
                            if (!mounted) return;
                            nav.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CustomerDashboardScreen(),
                              ),
                            );
                          } on CustomerApiException catch (error) {
                            if (mounted) _snack(error.message);
                          } catch (_) {
                            if (mounted) {
                              _snack(
                                  'Unable to connect to the DAILY server. Please try again.');
                            }
                          } finally {
                            if (mounted) setState(() => loading = false);
                          }
                        },

                        child: Text(
                          loading ? 'SIGNING IN...' : 'SIGN IN',
                          style: const TextStyle(
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7A1F1F),
      ),
    );
  }
}


