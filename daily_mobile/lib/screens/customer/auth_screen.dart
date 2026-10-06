import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import '../../services/session_service.dart';
import 'customer_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool login = true;
  bool usePhone = false;
  final identifier = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      identifier,
      password,
      fullName,
      phone,
      email,
      address,
      newPassword,
      confirmPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
              child: DailyHeader(
                title: 'DAILY',
                onBack: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      login ? 'Welcome Back' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      login
                          ? 'Sign in to your ${_roleName()} account.'
                          : 'Set up your ${_roleName()} account.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: DailyColors.gray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _tab(
                            'LOGIN',
                            login,
                            () => setState(() => login = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tab(
                            'SIGN UP',
                            !login,
                            () => setState(() => login = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: login ? _loginForm() : _signupForm(),
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

  Widget _tab(String text, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 42,
      decoration: BoxDecoration(
        color: active ? DailyColors.burgundy : DailyColors.white,
        border: Border.all(
          color: active ? DailyColors.burgundy : DailyColors.divider,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: active ? Colors.white : DailyColors.charcoal,
          ),
        ),
      ),
    ),
  );

  Widget _loginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Sign in with'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _method(
                'Email',
                Icons.email_outlined,
                !usePhone,
                () => setState(() => usePhone = false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _method(
                'Phone',
                Icons.phone_outlined,
                usePhone,
                () => setState(() => usePhone = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _field(
          usePhone ? 'Phone Number' : 'Email Address',
          usePhone ? 'Enter your phone number' : 'Enter your email address',
          usePhone ? Icons.phone_outlined : Icons.email_outlined,
          identifier,
        ),
        const SizedBox(height: 15),
        _field(
          'Password',
          'Enter your password',
          Icons.lock_outline,
          password,
          obscure: true,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Forgot Password?',
              style: TextStyle(color: DailyColors.burgundy, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 7),
        PrimaryButton(label: 'LOGIN', onPressed: _login),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'OR',
            style: TextStyle(fontSize: 10, color: DailyColors.gray),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.g_mobiledata,
              color: DailyColors.burgundy,
              size: 25,
            ),
            label: const Text(
              'CONTINUE WITH GOOGLE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: .8,
                color: DailyColors.charcoal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(),
              side: const BorderSide(color: DailyColors.divider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signupForm() {
    return Column(
      key: const ValueKey('signup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Personal Information'),
        const SizedBox(height: 14),
        _field(
          'Full Name',
          'Enter your full name',
          Icons.person_outline,
          fullName,
        ),
        const SizedBox(height: 14),
        _field(
          'Phone Number',
          'Enter your phone number',
          Icons.phone_outlined,
          phone,
        ),
        const SizedBox(height: 14),
        _field(
          'Email Address',
          'Enter your email address',
          Icons.email_outlined,
          email,
        ),
        const SizedBox(height: 14),
        _field(
          'Delivery Address',
          'Enter your delivery address',
          Icons.location_on_outlined,
          address,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        const SectionLabel('Set Password'),
        const SizedBox(height: 14),
        _field(
          'Password',
          'Create your password',
          Icons.lock_outline,
          newPassword,
          obscure: true,
        ),
        const SizedBox(height: 14),
        _field(
          'Confirm Password',
          'Re-enter your password',
          Icons.lock_outline,
          confirmPassword,
          obscure: true,
        ),
        const SizedBox(height: 22),
        PrimaryButton(label: 'CREATE ACCOUNT', onPressed: _signup),
      ],
    );
  }

  Widget _method(
    String title,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 42,
      decoration: BoxDecoration(
        color: active ? DailyColors.tan : DailyColors.white,
        border: Border.all(
          color: active ? DailyColors.burgundy : DailyColors.divider,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: DailyColors.burgundy),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 7),
      TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: DailyColors.burgundy, size: 20),
          hintStyle: const TextStyle(fontSize: 12, color: DailyColors.gray),
        ),
      ),
    ],
  );

  String _roleName() => widget.role == 'CUSTOMER'
      ? 'customer'
      : widget.role == 'SUPPLIER'
      ? 'supplier'
      : 'delivery partner';

  Future<void> _login() async {
    if (identifier.text.trim().isEmpty || password.text.isEmpty) {
      _snack('Enter your login details.');
      return;
    }
    if (widget.role == 'CUSTOMER') {
      await SessionService.setCustomerLoggedIn();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
      );
    } else {
      _snack('${_roleName()} dashboard will be connected next.');
    }
  }

  void _signup() {
    if ([
      fullName,
      phone,
      email,
      address,
      newPassword,
      confirmPassword,
    ].any((c) => c.text.trim().isEmpty)) {
      _snack('Please complete all required information.');
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      _snack('Passwords do not match.');
      return;
    }
    _snack('Account created successfully.');
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: DailyColors.burgundy),
  );
}
