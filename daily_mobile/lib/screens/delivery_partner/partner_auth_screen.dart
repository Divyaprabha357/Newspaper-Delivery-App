import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'partner_widgets.dart';

class PartnerAuthScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  final RoleApiService? apiService;
  const PartnerAuthScreen({
    super.key,
    required this.onSignedIn,
    this.apiService,
  });

  @override
  State<PartnerAuthScreen> createState() => _PartnerAuthScreenState();
}

class _PartnerAuthScreenState extends State<PartnerAuthScreen> {
  bool login = true;
  int step = 0;
  bool terms = false;
  bool obscureLoginPassword = true;
  final loginEmail = TextEditingController();
  final loginPassword = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final emergency = TextEditingController();
  final registration = TextEditingController();
  String vehicle = 'Motorcycle';
  bool loading = false;

  @override
  void dispose() {
    for (final c in [
      loginEmail,
      loginPassword,
      password,
      confirmPassword,
      name,
      email,
      phone,
      emergency,
      registration,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => login ? _login() : _signup();

  Widget _login() {
    return PartnerPage(
      title: 'Delivery Partner',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WELCOME BACK', style: AppTextStyles.headerOverline),
            const SizedBox(height: 10),
            Text('Partner sign in', style: AppTextStyles.pageTitle),
            const SizedBox(height: 8),
            Text(
              'Access your routes, delivery history and earnings.',
              style: AppTextStyles.pageSubtitle,
            ),
            const SizedBox(height: 30),
            PartnerField(
              label: 'Email Address',
              hint: 'Enter your email address',
              controller: loginEmail,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            PartnerField(
              label: 'Password',
              hint: 'Enter your password',
              controller: loginPassword,
              icon: Icons.lock_outline,
              obscure: obscureLoginPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: DailyColors.gray,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => obscureLoginPassword = !obscureLoginPassword,
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: loading ? 'SIGNING IN...' : 'SIGN IN',
              onPressed: loading
                  ? () {}
                  : () async {
                      if (loading) return;
                      final emailStr = loginEmail.text.trim();
                      final passwordStr = loginPassword.text;

                      if (emailStr.isEmpty) {
                        _message('Please enter your email address.');
                        return;
                      }

                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(emailStr)) {
                        _message('Please enter a valid email address.');
                        return;
                      }

                      if (passwordStr.isEmpty) {
                        _message('Please enter your password.');
                        return;
                      }
                      setState(() => loading = true);
                      try {
                        final api = widget.apiService ?? RoleApiService();
                        final response = await api.login(
                          emailOrPhone: emailStr,
                          password: passwordStr,
                          role: 'DELIVERY_PARTNER',
                        );
                        final user = Map<String, dynamic>.from(
                          response['user'] as Map? ?? {},
                        );
                        final role = (user['role'] ?? '')
                            .toString()
                            .toUpperCase();
                        if (role != 'DELIVERY_PARTNER' ||
                            user['partner_id'] == null) {
                          throw const RoleApiException(
                            'This account is not authorized for the Delivery Partner workspace.',
                          );
                        }
                        await RoleSessionService.savePartner(user);
                        if (mounted) widget.onSignedIn();
                      } on RoleApiException catch (error) {
                        if (mounted) _message(error.message);
                      } catch (_) {
                        if (mounted) {
                          _message(
                            'Unable to connect to the DAILY server. Please try again.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => setState(() => login = false),
                child: Text(
                  'New delivery partner? Register here',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: DailyColors.burgundy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signup() {
    final labels = ['Personal', 'Vehicle', 'Availability', 'Security'];
    return PartnerPage(
      title: [
        'Delivery Partner Sign Up',
        'Vehicle Information',
        'Delivery Availability',
        'Secure Your Account',
      ][step],
      onBack: () =>
          step == 0 ? setState(() => login = true) : setState(() => step--),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                labels.length,
                (index) => Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        margin: const EdgeInsets.only(right: 4),
                        color: index <= step
                            ? DailyColors.burgundy
                            : DailyColors.divider,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        labels[index],
                        style: AppTextStyles.caption.copyWith(
                          color: index == step
                              ? DailyColors.burgundy
                              : DailyColors.gray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (step == 0) ...[
              PartnerField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: name,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),
              PartnerField(
                label: 'Email Address',
                hint: 'Enter your email address',
                controller: email,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),
              PartnerField(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                controller: phone,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 15),
              PartnerField(
                label: 'Emergency Contact',
                hint: 'Name and phone number',
                controller: emergency,
                icon: Icons.contact_phone_outlined,
              ),
            ] else if (step == 1) ...[
              DropdownButtonFormField<String>(
                initialValue: vehicle,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                items: ['Motorcycle', 'Scooter', 'Bicycle', 'Other']
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, style: AppTextStyles.body),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => vehicle = v!),
              ),
              const SizedBox(height: 15),
              PartnerField(
                label: 'Registration Number',
                hint: 'e.g. MH 01 AB 1234',
                controller: registration,
                icon: Icons.directions_bike_outlined,
              ),
            ] else if (step == 2) ...[
              Text('Shift Start', style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.schedule),
                ),
                child: Text('06:00 AM', style: AppTextStyles.body),
              ),
              const SizedBox(height: 15),
              Text('Shift End', style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.schedule),
                ),
                child: Text('11:00 AM', style: AppTextStyles.body),
              ),
            ] else ...[
              PartnerField(
                label: 'Password',
                hint: 'Create a password',
                controller: password,
                icon: Icons.lock_outline,
                obscure: true,
              ),
              const SizedBox(height: 15),
              PartnerField(
                label: 'Confirm Password',
                hint: 'Repeat your password',
                controller: confirmPassword,
                icon: Icons.lock_outline,
                obscure: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: terms,
                activeColor: DailyColors.burgundy,
                onChanged: (v) => setState(() => terms = v ?? false),
                title: Text(
                  'I agree to the Terms & Conditions',
                  style: AppTextStyles.caption.copyWith(
                    color: DailyColors.charcoal,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                if (step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => step--),
                      style: OutlinedButton.styleFrom(
                        textStyle: AppTextStyles.button,
                      ),
                      child: const Text('BACK'),
                    ),
                  ),
                if (step > 0) const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: loading
                        ? (step == 3 ? 'CREATING ACCOUNT...' : 'NEXT')
                        : (step == 3 ? 'CREATE ACCOUNT' : 'NEXT'),
                    onPressed: loading ? () {} : _next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _next() async {
    if (step == 0) {
      if (name.text.trim().isEmpty) {
        _message('Please enter your full name.');
        return;
      }
      if (email.text.trim().isEmpty) {
        _message('Please enter your email address.');
        return;
      }
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.text.trim())) {
        _message('Please enter a valid email address.');
        return;
      }
      if (phone.text.trim().isEmpty) {
        _message('Please enter your phone number.');
        return;
      }
      setState(() => step = 1);
      return;
    }
    if (step == 1) {
      setState(() => step = 2);
      return;
    }
    if (step == 2) {
      setState(() => step = 3);
      return;
    }
    // Step 3
    if (password.text.isEmpty) {
      _message('Please create a password.');
      return;
    }
    if (password.text.length < 6) {
      _message('Password must be at least 6 characters long.');
      return;
    }
    if (confirmPassword.text.isEmpty) {
      _message('Please confirm your password.');
      return;
    }
    if (password.text != confirmPassword.text) {
      _message('Passwords do not match.');
      return;
    }
    if (!terms) {
      _message('Please accept the Terms & Conditions.');
      return;
    }

    setState(() => loading = true);
    try {
      final api = widget.apiService ?? RoleApiService();
      final response = await api.registerPartner(
        name: name.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        password: password.text,
        emergencyContact: emergency.text.trim().isEmpty
            ? null
            : emergency.text.trim(),
        vehicleType: vehicle,
        registrationNumber: registration.text.trim().isEmpty
            ? null
            : registration.text.trim(),
      );
      final user = Map<String, dynamic>.from(response['user'] as Map? ?? {});
      await RoleSessionService.savePartner(user);
      if (!mounted) return;
      _message('Account created successfully!');
      widget.onSignedIn();
    } on RoleApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Unable to register delivery partner account.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
