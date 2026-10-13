import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'partner_widgets.dart';

class PartnerHistoryScreen extends StatelessWidget {
  const PartnerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PartnerTop('Delivery history', subtitle: 'Your completed route activity'),
      const PartnerSection('DELIVERY SUMMARY'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [_stat('86%', 'Delivered'), _stat('8%', 'Partial'), _stat('6%', 'Issues')])),
      const PartnerSection('7 OCTOBER 2026'),
      _item('âœ“', 'Aarav Sharma', 'The Times of India â€¢ 7:03 AM', DailyColors.success),
      _item('â—', 'Priya Deshmukh', 'Partial delivery â€¢ 7:12 AM', DailyColors.warning),
      const PartnerSection('6 OCTOBER 2026'),
      _item('âœ“', 'Aarav Sharma', '2 newspapers â€¢ 7:01 AM', DailyColors.success),
      _item('âœ•', 'Vikram Joshi', 'Customer not available', DailyColors.burgundy),
    ]));
  }

  Widget _stat(String value, String label) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)), child: Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DailyColors.burgundy)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 14, color: DailyColors.gray))])));
  Widget _item(String icon, String name, String detail, Color color) => Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 10), child: Container(padding: const EdgeInsets.all(15), color: DailyColors.white, child: Row(children: [Text(icon, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(width: 13), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(detail, style: const TextStyle(fontSize: 12, color: DailyColors.gray))])])));
}

class PartnerEarningsScreen extends StatelessWidget {
  const PartnerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const PartnerTop('My earnings', subtitle: 'September 2026'),
    Padding(padding: const EdgeInsets.fromLTRB(24, 10, 24, 18), child: Container(padding: const EdgeInsets.all(20), color: DailyColors.charcoal, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TOTAL EARNINGS', style: TextStyle(color: DailyColors.tan, fontSize: 14, letterSpacing: 1.4, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text('₹8,500', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), SizedBox(height: 18), Text('PENDING  ₹2,500     PAID  ₹6,000', style: TextStyle(color: DailyColors.tan, fontSize: 12))]))),
    const PartnerSection('PAYMENT HISTORY'),
    _payment('September', '₹8,500', 'PENDING'),
    _payment('August', '₹8,200', 'PAID'),
    _payment('July', '₹7,950', 'PAID'),
  ]));

  Widget _payment(String month, String amount, String status) => Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 10), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)), child: Row(children: [Expanded(child: Text(month, style: const TextStyle(fontWeight: FontWeight.bold))), Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 15), Text(status, style: TextStyle(fontSize: 14, color: status == 'PAID' ? DailyColors.success : DailyColors.warning, fontWeight: FontWeight.bold))])));
}


