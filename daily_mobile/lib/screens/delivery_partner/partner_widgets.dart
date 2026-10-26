import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import '../role_selection_screen.dart';

Widget partnerError(Object error, VoidCallback retry) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, color: DailyColors.burgundy, size: 38),
        const SizedBox(height: 12),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: retry, child: const Text('RETRY')),
      ]),
    );

Widget partnerEmpty(String message) => Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: DailyColors.gray))),
    );

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
              child: DailyHeader(
                title: title,
                onBack: onBack ?? () {
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
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const PartnerField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 14, letterSpacing: 1.1, fontWeight: FontWeight.bold, color: DailyColors.gray)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19, color: DailyColors.burgundy),
            suffixIcon: suffixIcon,
          ),
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
      child: Text(title, style: const TextStyle(fontSize: 14, letterSpacing: 1.5, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
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
                const Text('DAILY DELIVERY PARTNER', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
  final int delivered;
  final int total;
  const PartnerProgress({super.key, required this.delivered, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$delivered Delivered', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${total - delivered} Remaining', style: const TextStyle(color: DailyColors.gray))]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: total == 0 ? 0 : delivered / total, minHeight: 9, backgroundColor: DailyColors.tan, valueColor: const AlwaysStoppedAnimation(DailyColors.burgundy))),
          ],
        ),
      ),
    );
  }
}

