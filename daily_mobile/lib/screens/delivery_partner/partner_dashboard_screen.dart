import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'partner_models.dart';
import 'partner_widgets.dart';

class PartnerDashboardScreen extends StatelessWidget {
  final VoidCallback onStartRoute;
  final VoidCallback onReportIssue;
  const PartnerDashboardScreen({super.key, required this.onStartRoute, required this.onReportIssue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PartnerTop('Good morning, Rahul.', subtitle: 'Wednesday, 7 October 2026'),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Rule()),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: DailyColors.charcoal,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("TODAY'S ROUTE", style: TextStyle(color: DailyColors.tan, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Dadar West Morning Route', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('06:00 AM — 11:00 AM  •  12 CUSTOMERS  •  24 NEWSPAPERS', style: TextStyle(color: DailyColors.tan, fontSize: 10)),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onStartRoute, style: ElevatedButton.styleFrom(backgroundColor: DailyColors.tan, foregroundColor: DailyColors.charcoal, shape: const RoundedRectangleBorder()), child: const Text('START ROUTE'))),
            ]),
          ),
        ),
        const PartnerSection("TODAY'S PROGRESS"),
        const PartnerProgress(),
        const PartnerSection('QUICK ACTIONS'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Expanded(child: _action('Today’s Route', Icons.route_outlined, onStartRoute)),
            const SizedBox(width: 10),
            Expanded(child: _action('Report Issue', Icons.report_problem_outlined, onReportIssue)),
          ]),
        ),
        const SizedBox(height: 22),
      ]),
    );
  }

  Widget _action(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: DailyColors.burgundy),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class PartnerRouteScreen extends StatelessWidget {
  final ValueChanged<int> onCustomerSelected;
  const PartnerRouteScreen({super.key, required this.onCustomerSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PartnerTop("Today's route", subtitle: 'Dadar West Morning Route'),
        const PartnerSection("TODAY'S PROGRESS"),
        const PartnerProgress(),
        const Padding(padding: EdgeInsets.fromLTRB(24, 14, 24, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('8 / 12 Customers', style: TextStyle(fontWeight: FontWeight.bold)), Text('67% Complete', style: TextStyle(color: DailyColors.gray))])),
        const PartnerSection('ROUTE CUSTOMERS'),
        ...partnerCustomers.asMap().entries.map((entry) => _customer(entry.key, entry.value)),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _customer(int index, RouteCustomer item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: InkWell(
        onTap: () => onCustomerSelected(index),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: DailyColors.white, border: Border.all(color: DailyColors.divider)),
          child: Row(children: [
            Text(item.number, style: const TextStyle(fontSize: 22, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(item.address, style: const TextStyle(fontSize: 12, color: DailyColors.gray)),
              const SizedBox(height: 6),
              Text('${item.newspapers.length} newspapers  •  ${item.time}', style: const TextStyle(fontSize: 11, color: DailyColors.burgundy)),
            ])),
            const Icon(Icons.chevron_right, color: DailyColors.burgundy),
          ]),
        ),
      ),
    );
  }
}
