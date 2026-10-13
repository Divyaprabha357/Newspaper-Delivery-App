import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tx = [
      ('The Times of India', '₹300', '01 SEP 2026'),
      ('The Hindu', '₹550', '28 AUG 2026'),
      ('Indian Express', '₹500', '25 AUG 2026'),
    ];

    return Scaffold(
      backgroundColor: DailyColors.cream,

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),

              child: DailyHeader(
                title: 'Payments & Bills',
                trailing: const Icon(Icons.notifications_none, size: 19),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),

                children: [
                  const SectionLabel('Current Amount Due'),

                  const SizedBox(height: 5),

                  // CURRENT BILL
                  Container(
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: DailyColors.white,
                      border: Border.all(color: DailyColors.divider),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          '₹300',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: DailyColors.burgundy,
                          ),
                        ),

                        const SizedBox(height: 3),

                        const Text(
                          'DUE ON 10 SEP 2026',
                          style: TextStyle(
                            fontSize: 12,
                            color: DailyColors.gray,
                          ),
                        ),

                        const SizedBox(height: 12),

                        PrimaryButton(
                          label: 'PAY TOTAL AMOUNT',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Payment'),

                                content: const Text(
                                  'Payment flow will be connected to the backend next.',
                                ),

                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },

                                    child: const Text(
                                      'OK',
                                      style: TextStyle(
                                        color: DailyColors.burgundy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NEXT BILLING CYCLE
                  Container(
                    padding: const EdgeInsets.all(10),

                    decoration: BoxDecoration(color: DailyColors.tan),

                    child: const Text(
                      'No payment scheduled for next billing cycle.',
                      style: TextStyle(fontSize: 12, color: DailyColors.gray),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TRANSACTIONS HEADER
                  Row(
                    children: [
                      const Expanded(child: SectionLabel('Transactions')),

                      TextButton(
                        onPressed: () {},

                        child: const Text(
                          'RECENT',
                          style: TextStyle(
                            fontSize: 12,
                            color: DailyColors.burgundy,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // TRANSACTIONS
                  Column(
                    children: tx.asMap().entries.expand((entry) {
                      final t = entry.value;
                      return [
                        Container(
                          decoration: BoxDecoration(
                            color: DailyColors.white,
                            border: Border.all(color: DailyColors.divider),
                          ),
                          child: InkWell(
                            onTap: () {
                              _showReceipt(context, t.$1, t.$2, t.$3);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      NewspaperThumb(title: t.$1, width: 64),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          t.$1,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${t.$2}  â€¢  ${t.$3}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: DailyColors.burgundy,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          _showReceipt(
                                            context,
                                            t.$1,
                                            t.$2,
                                            t.$3,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'RECEIPT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: DailyColors.burgundy,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (entry.key < tx.length - 1)
                          const SizedBox(height: 8),
                      ];
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // ACTIVE SUBSCRIPTIONS
                  const SectionLabel('Active Subscriptions'),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _mini('TOI Daily', '₹550'),

                      const SizedBox(width: 8),

                      _mini('The Hindu', '₹550'),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // DISPUTE
                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: DailyColors.white,
                      border: Border.all(color: DailyColors.divider),
                    ),

                    child: const Row(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          color: DailyColors.burgundy,
                          size: 18,
                        ),

                        SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            'Dispute a Transaction?\n'
                            'Report a billing issue from Service Requests.',
                            style: TextStyle(fontSize: 12, height: 1.4),
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

  // RECEIPT POPUP
  void _showReceipt(
    BuildContext context,
    String newspaper,
    String amount,
    String date,
  ) {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          backgroundColor: DailyColors.cream,

          title: const Text(
            'Payment Receipt',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                'DAILY',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DailyColors.burgundy,
                ),
              ),

              const SizedBox(height: 14),

              const Divider(),

              const SizedBox(height: 8),

              Text(
                'NEWSPAPER\n$newspaper',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 10),

              Text(
                'PAYMENT DATE\n$date',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 10),

              Text(
                'AMOUNT PAID\n$amount',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'STATUS\nPAID',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: DailyColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Divider(),

              const SizedBox(height: 6),

              const Text(
                'Thank you for using DAILY.',
                style: TextStyle(fontSize: 12, color: DailyColors.gray),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'CLOSE',
                style: TextStyle(
                  fontSize: 12,
                  color: DailyColors.burgundy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _mini(String n, String p) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: DailyColors.white,
          border: Border.all(color: DailyColors.divider),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            NewspaperThumb(title: n, width: 30),

            const SizedBox(height: 6),

            Text(
              n,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),

            Text(
              p,
              style: const TextStyle(fontSize: 12, color: DailyColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}


