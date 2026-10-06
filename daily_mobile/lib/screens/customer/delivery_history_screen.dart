import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '5 SEP 2026',
        'The Times of India',
        'DELIVERED • 7:02 AM',
        DailyColors.success,
      ),
      ('4 SEP 2026', 'The Hindu', 'DELIVERED • 6:58 AM', DailyColors.success),
      ('3 SEP 2026', 'Indian Express', 'MISSED • 7:05 AM', DailyColors.warning),
      (
        '2 SEP 2026',
        'Business Standard',
        'DELIVERED • 7:05 AM',
        DailyColors.success,
      ),
      (
        '1 SEP 2026',
        'The Times of India',
        'DELIVERED • 7:00 AM',
        DailyColors.success,
      ),
    ];
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Delivery History',
                onBack: () => Navigator.pop(context),
                trailing: const Icon(Icons.search, size: 19),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                children: [
                  const Text(
                    'Timeline',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your journey of informed mornings, recorded day by day.',
                    style: TextStyle(fontSize: 10, color: DailyColors.gray),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'DELIVERED', 'DELAYED', 'MISSED']
                          .map(
                            (x) => Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: x == 'ALL'
                                      ? DailyColors.burgundy
                                      : DailyColors.white,
                                  border: Border.all(
                                    color: DailyColors.divider,
                                  ),
                                ),
                                child: Text(
                                  x,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: x == 'ALL'
                                        ? Colors.white
                                        : DailyColors.charcoal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DailyColors.white,
                      border: Border.all(color: DailyColors.divider),
                    ),
                    child: Column(
                      children: List.generate(items.length, (i) {
                        final e = items[i];
                        return _item(
                          e.$1,
                          e.$2,
                          e.$3,
                          e.$4,
                          i == items.length - 1,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DailyColors.white,
                      border: Border.all(color: DailyColors.divider),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: DailyColors.burgundy,
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'STATUS GUIDE\nGreen = delivered. Orange = attention required. Missing a paper? Report it from Service Requests.',
                            style: TextStyle(fontSize: 9, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    String date,
    String paper,
    String status,
    Color color,
    bool last,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          if (!last)
            Container(width: 1, height: 52, color: DailyColors.divider),
        ],
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 8,
                  color: DailyColors.gray,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                paper,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: TextStyle(
                  fontSize: 8,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
