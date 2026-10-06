import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'partner_widgets.dart';

class PartnerAuthScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  const PartnerAuthScreen({super.key, required this.onSignedIn});

  @override
  State<PartnerAuthScreen> createState() => _PartnerAuthScreenState();
}

class _PartnerAuthScreenState extends State<PartnerAuthScreen> {
  bool login = true;
  int step = 0;
  bool terms = false;
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final emergency = TextEditingController();
  final registration = TextEditingController();
  String vehicle = 'Motorcycle';

  @override
  void dispose() {
    for (final c in [code, password, confirmPassword, name, email, phone, emergency, registration]) {
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('WELCOME BACK', style: TextStyle(fontSize: 11, letterSpacing: 1.7, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Partner sign in', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Access your routes, delivery history and earnings.', style: TextStyle(color: DailyColors.gray, height: 1.5)),
          const SizedBox(height: 30),
          PartnerField(label: 'Partner Code', hint: 'e.g. DP001', controller: code, icon: Icons.badge_outlined),
          const SizedBox(height: 16),
          PartnerField(label: 'Password', hint: 'Enter your password', controller: password, icon: Icons.lock_outline, obscure: true),
          const SizedBox(height: 12),
          PrimaryButton(label: 'SIGN IN', onPressed: () {
            if (code.text.isEmpty || password.text.isEmpty) {
              _message('Enter your partner code and password.');
            } else {
              widget.onSignedIn();
            }
          }),
          const SizedBox(height: 24),
          Center(child: TextButton(onPressed: () => setState(() => login = false), child: const Text('New delivery partner? Register here', style: TextStyle(color: DailyColors.burgundy)))),
        ]),
      ),
    );
  }

  Widget _signup() {
    final labels = ['Personal', 'Vehicle', 'Availability', 'Security'];
    return PartnerPage(
      title: ['Delivery Partner Sign Up', 'Vehicle Information', 'Delivery Availability', 'Secure Your Account'][step],
      onBack: () => step == 0 ? setState(() => login = true) : setState(() => step--),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: List.generate(labels.length, (index) => Expanded(child: Column(children: [
            Container(height: 4, margin: const EdgeInsets.only(right: 4), color: index <= step ? DailyColors.burgundy : DailyColors.divider),
            const SizedBox(height: 7),
            Text(labels[index], style: TextStyle(fontSize: 9, color: index == step ? DailyColors.burgundy : DailyColors.gray, fontWeight: FontWeight.bold)),
          ])))),
          const SizedBox(height: 30),
          if (step == 0) ...[
            PartnerField(label: 'Full Name', hint: 'Enter your full name', controller: name, icon: Icons.person_outline),
            const SizedBox(height: 15),
            PartnerField(label: 'Email Address', hint: 'Enter your email address', controller: email, icon: Icons.email_outlined),
            const SizedBox(height: 15),
            PartnerField(label: 'Phone Number', hint: 'Enter your phone number', controller: phone, icon: Icons.phone_outlined),
            const SizedBox(height: 15),
            PartnerField(label: 'Emergency Contact', hint: 'Name and phone number', controller: emergency, icon: Icons.contact_phone_outlined),
          ] else if (step == 1) ...[
            DropdownButtonFormField<String>(initialValue: vehicle, decoration: const InputDecoration(labelText: 'Vehicle Type'), items: ['Motorcycle', 'Scooter', 'Bicycle', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => vehicle = v!)),
            const SizedBox(height: 15),
            PartnerField(label: 'Registration Number', hint: 'e.g. MH 01 AB 1234', controller: registration, icon: Icons.directions_bike_outlined),
          ] else if (step == 2) ...[
            const Text('Shift Start'), const SizedBox(height: 8), const InputDecorator(decoration: InputDecoration(prefixIcon: Icon(Icons.schedule)), child: Text('06:00 AM')),
            const SizedBox(height: 15), const Text('Shift End'), const SizedBox(height: 8), const InputDecorator(decoration: InputDecoration(prefixIcon: Icon(Icons.schedule)), child: Text('11:00 AM')),
          ] else ...[
            PartnerField(label: 'Password', hint: 'Create a password', controller: password, icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 15),
            PartnerField(label: 'Confirm Password', hint: 'Repeat your password', controller: confirmPassword, icon: Icons.lock_outline, obscure: true),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: terms, activeColor: DailyColors.burgundy, onChanged: (v) => setState(() => terms = v ?? false), title: const Text('I agree to the Terms & Conditions', style: TextStyle(fontSize: 12))),
          ],
          const SizedBox(height: 28),
          Row(children: [
            if (step > 0) Expanded(child: OutlinedButton(onPressed: () => setState(() => step--), child: const Text('BACK'))),
            if (step > 0) const SizedBox(width: 10),
            Expanded(child: PrimaryButton(label: step == 3 ? 'CREATE ACCOUNT' : 'NEXT', onPressed: _next)),
          ]),
        ]),
      ),
    );
  }

  void _next() {
    if (step < 3) {
      setState(() => step++);
      return;
    }
    if (password.text.length < 8 || password.text != confirmPassword.text || !terms) {
      _message('Complete password requirements and accept the Terms & Conditions.');
      return;
    }
    _message('Account created. Partner code will be assigned when the backend is connected.');
    setState(() => login = true);
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
