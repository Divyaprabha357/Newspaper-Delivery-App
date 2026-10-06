import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class PartnerPage extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onBack;

  const PartnerPage({super.key, required this.title, required this.child, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
              child: DailyHeader(title: title, onBack: onBack ?? () => Navigator.pop(context)),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class PartnerField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscure;

  const PartnerField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.bold, color: DailyColors.gray)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 19, color: DailyColors.burgundy)),
        ),
      ],
    );
  }
}

class PartnerSection extends StatelessWidget {
  final String title;
  const PartnerSection(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: Text(title, style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
    );
  }
}

class PartnerTop extends StatelessWidget {
  final String title;
  final String? subtitle;
  const PartnerTop(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DAILY DELIVERY PARTNER', style: TextStyle(fontSize: 9, letterSpacing: 1.4, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(color: DailyColors.gray, fontSize: 12))],
              ],
            ),
          ),
          const CircleAvatar(backgroundColor: DailyColors.burgundy, child: Text('R', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class PartnerProgress extends StatelessWidget {
  const PartnerProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('7 Delivered', style: TextStyle(fontWeight: FontWeight.bold)), Text('5 Remaining', style: TextStyle(color: DailyColors.gray))]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(2), child: const LinearProgressIndicator(value: .58, minHeight: 9, backgroundColor: DailyColors.tan, valueColor: AlwaysStoppedAnimation(DailyColors.burgundy))),
          ],
        ),
      ),
    );
  }
}
