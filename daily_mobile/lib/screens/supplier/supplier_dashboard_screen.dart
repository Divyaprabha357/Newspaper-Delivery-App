import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'supplier_distribution_screen.dart';

class SupplierDashboardScreen extends StatelessWidget {
  const SupplierDashboardScreen({super.key});

  String _today() {
    final date = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DASHBOARD',
                style: TextStyle(
                  color: DailyColors.burgundy,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Good morning,\nSupplier.',
                style: TextStyle(
                  color: DailyColors.charcoal,
                  fontSize: 40,
                  height: .98,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                _today(),
                style: const TextStyle(
                  color: DailyColors.gray,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 17),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _leftColumn(context),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      flex: 4,
                      child: _rightColumn(),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _leftColumn(context),
                    const SizedBox(height: 13),
                    _rightColumn(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _leftColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Today\'s distribution'),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: DailyColors.charcoal,
            border: Border.fromBorderSide(
              BorderSide(color: DailyColors.charcoal),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Morning circulation',
                      style: TextStyle(
                        color: DailyColors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    color: DailyColors.burgundy,
                    child: const Text(
                      'ON TRACK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Distribution progress across all active routes.',
                style: TextStyle(
                  color: Color(0xFFC8BBA8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 19),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '2,244',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 7, bottom: 5),
                    child: Text(
                      'of 2,480 delivered',
                      style: TextStyle(
                        color: Color(0xFFC8BBA8),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  value: .905,
                  minHeight: 7,
                  color: Color(0xFFE5C9A8),
                  backgroundColor: Color(0xFF5D5A56),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  _DarkStat('96.2%', 'ON-TIME'),
                  SizedBox(width: 24),
                  _DarkStat('18', 'ACTIVE ROUTES'),
                  SizedBox(width: 24),
                  _DarkStat('236', 'REMAINING'),
                ],
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupplierDistributionScreen(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE5C9A8),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'VIEW DISTRIBUTION \u2192',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            const Expanded(child: _SectionHeading('Recent activity')),
            TextButton(
              onPressed: () {},
              child: const Text(
                'VIEW ALL',
                style: TextStyle(
                  color: DailyColors.burgundy,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _panel(
          Column(
            children: [
              _ActivityRow(
                time: '07:42 AM',
                title: 'Route 12 completed',
                detail: 'North Sector \u00B7 150 deliveries',
                color: DailyColors.success,
              ),
              _ActivityRow(
                time: '07:18 AM',
                title: 'Stock replenished',
                detail: 'The Times of India \u00B7 240 copies',
                color: DailyColors.burgundy,
              ),
              _ActivityRow(
                time: '06:55 AM',
                title: 'Issue reported',
                detail: 'Route 17 \u00B7 Missing newspaper',
                color: DailyColors.warning,
              ),
              _ActivityRow(
                time: 'Yesterday',
                title: 'Payout reconciliation',
                detail: '3 delivery partners pending',
                color: DailyColors.gray,
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Quick overview'),
        const SizedBox(height: 7),
        _panel(
          Column(
            children: [
              const _OverviewRow('Active subscriptions', '2,480'),
              const _OverviewRow('Newspapers in circulation', '18'),
              const _OverviewRow('Customers served', '1,126'),
              const _OverviewRow('Collections due', '\u20B928,450', last: true),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const _SectionHeading('Supply issues'),
        const SizedBox(height: 7),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IssueRow(
                icon: Icons.inventory_2_outlined,
                title: 'Low stock alert',
                detail: 'The Hindu \u00B7 42 copies remaining',
                color: DailyColors.warning,
              ),
              const _IssueRow(
                icon: Icons.report_problem_outlined,
                title: 'Open complaints',
                detail: '2 delivery issues need attention',
                color: DailyColors.burgundy,
              ),
              const _IssueRow(
                icon: Icons.payments_outlined,
                title: 'Partner payouts',
                detail: '3 reconciliations pending',
                color: DailyColors.gray,
                last: true,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DailyColors.burgundy,
                    side: const BorderSide(color: DailyColors.burgundy),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text(
                    'REVIEW ALL ISSUES',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: DailyColors.burgundy,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _DarkStat extends StatelessWidget {
  final String value;
  final String label;

  const _DarkStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC8BBA8),
            fontSize: 14,
            letterSpacing: .7,
          ),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _OverviewRow(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: DailyColors.divider),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: DailyColors.gray),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DailyColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String time;
  final String title;
  final String detail;
  final Color color;
  final bool last;

  const _ActivityRow({
    required this.time,
    required this.title,
    required this.detail,
    required this.color,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: DailyColors.divider),
              ),
      ),
      child: Row(
        children: [
          StatusDot(color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 15,
                    color: DailyColors.gray,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: DailyColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final bool last;

  const _IssueRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: DailyColors.divider),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 15,
                    color: DailyColors.gray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 17,
            color: DailyColors.gray,
          ),
        ],
      ),
    );
  }
}



