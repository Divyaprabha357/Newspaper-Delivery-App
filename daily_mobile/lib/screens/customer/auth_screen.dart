import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/mobile_role_design.dart';
import '../../widgets/daily_widgets.dart';
import '../../services/session_service.dart';
import '../../services/customer_api_service.dart';
import 'customer_dashboard_screen.dart';
import '../role_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  final CustomerApiService? apiService;
  const AuthScreen({super.key, required this.role, this.apiService});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool login = true;
  bool usePhone = false;
  bool loading = false;
  bool terms = false;
  bool obscureLoginPassword = true;
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
    return Theme(
      data: MobileRoleDesign.theme(context),
      child: Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
              child: DailyHeader(
                title: 'DAILY',
                onBack: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    );
                  }
                },
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      login
                          ? 'Sign in to your ${_roleName()} account.'
                          : 'Set up your ${_roleName()} account.',
                      style: const TextStyle(
                        fontSize: 14,
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
            fontSize: 14,
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
          keyboardType: usePhone ? TextInputType.phone : TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        _field(
          'Password',
          'Enter your password',
          Icons.lock_outline,
          password,
          obscure: obscureLoginPassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscureLoginPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: DailyColors.gray,
              size: 20,
            ),
            onPressed: () =>
                setState(() => obscureLoginPassword = !obscureLoginPassword),
          ),
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
        PrimaryButton(
          label: loading ? 'SIGNING IN...' : 'LOGIN',
          onPressed: loading ? () {} : _login,
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'OR',
            style: TextStyle(fontSize: 14, color: DailyColors.gray),
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
                fontSize: 14,
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
        const SizedBox(height: 14),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: terms,
          activeColor: DailyColors.burgundy,
          onChanged: (v) => setState(() => terms = v ?? false),
          title: const Text(
            'I agree to the Terms & Conditions',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: loading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT',
          onPressed: loading ? () {} : _signup,
        ),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 7),
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: DailyColors.burgundy, size: 20),
          suffixIcon: suffixIcon,
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
    if (loading) return;

    final rawId = identifier.text.trim();
    final rawPassword = password.text;

    if (rawId.isEmpty) {
      _snack(usePhone
          ? 'Please enter your phone number.'
          : 'Please enter your email address.');
      return;
    }

    if (usePhone) {
      final digits = rawId.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10) {
        _snack('Please enter a valid 10-digit phone number.');
        return;
      }
    } else {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(rawId)) {
        _snack('Please enter a valid email address.');
        return;
      }
    }

    if (rawPassword.isEmpty) {
      _snack('Please enter your password.');
      return;
    }

    if (widget.role != 'CUSTOMER') {
      _snack('${_roleName()} dashboard will be connected next.');
      return;
    }

    setState(() => loading = true);
    try {
      final api = widget.apiService ?? CustomerApiService();
      final data = await api.login(
        emailOrPhone: rawId,
        password: rawPassword,
        role: 'CUSTOMER',
      );
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? {});
      final role = (user['role'] ?? '').toString().toUpperCase();
      if (role != 'CUSTOMER' || user['customer_id'] == null) {
        throw const CustomerApiException(
          'This account is not authorized as a Customer account.',
          statusCode: 403,
        );
      }
      await SessionService.saveCustomer(user);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
      );
    } on CustomerApiException catch (error) {
      if (mounted) _snack(error.message);
    } catch (_) {
      if (mounted) {
        _snack('Unable to connect to the DAILY server. Please try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signup() async {
    if (fullName.text.trim().isEmpty) {
      _snack('Please enter your full name.');
      return;
    }
    if (phone.text.trim().isEmpty) {
      _snack('Please enter your phone number.');
      return;
    }
    if (phone.text.trim().length < 10) {
      _snack('Phone number must be at least 10 digits.');
      return;
    }
    if (email.text.trim().isEmpty) {
      _snack('Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.text.trim())) {
      _snack('Please enter a valid email address.');
      return;
    }
    if (address.text.trim().isEmpty) {
      _snack('Please enter your delivery address.');
      return;
    }
    if (newPassword.text.isEmpty) {
      _snack('Please create a password.');
      return;
    }
    if (newPassword.text.length < 6) {
      _snack('Password must be at least 6 characters long.');
      return;
    }
    if (confirmPassword.text.isEmpty) {
      _snack('Please confirm your password.');
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      _snack('Passwords do not match.');
      return;
    }
    if (!terms) {
      _snack('Please accept the Terms & Conditions.');
      return;
    }

    setState(() => loading = true);
    try {
      final api = widget.apiService ?? CustomerApiService();
      final data = await api.register(
        name: fullName.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        address: address.text.trim(),
        password: newPassword.text,
      );
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? {});
      if (user['customer_id'] == null) {
        throw const CustomerApiException('Customer account could not be initialized.');
      }
      await SessionService.saveCustomer(user);
      if (!mounted) return;
      _snack('Account created successfully!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
      );
    } on CustomerApiException catch (error) {
      if (mounted) _snack(error.message);
    } catch (_) {
      if (mounted) _snack('Unable to connect to the DAILY server.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: DailyColors.burgundy),
    );
  }
}


