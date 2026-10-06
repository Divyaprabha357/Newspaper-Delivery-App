import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class NewspaperDetailScreen extends StatelessWidget {
  final String name;
  final String price;

  const NewspaperDetailScreen({
    super.key,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DailyColors.cream,

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Newspaper Details',
                onBack: () => Navigator.pop(context),
                trailing: const Icon(Icons.more_horiz, size: 19),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Newspaper image
                    AspectRatio(
                      aspectRatio: 1.55,
                      child: SvgPicture.asset(
                        'assets/icons/newspaper.svg',
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Newspaper name + Popular badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          color: const Color(0xFFF1D7D0),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 10,
                              color: DailyColors.burgundy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Publication details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DailyColors.white,
                        border: Border.all(color: DailyColors.divider),
                      ),
                      child: Column(
                        children: [
                          _row(
                            Icons.business,
                            'Supplier',
                            'National Daily Editions',
                          ),
                          _row(
                            Icons.local_shipping_outlined,
                            'Delivery',
                            'Daily before 7:30 AM',
                          ),
                          _row(Icons.translate, 'Language', 'English'),
                          _row(
                            Icons.calendar_month_outlined,
                            'Frequency',
                            'Monday – Sunday',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // About
                    const Text(
                      'About the Publication',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'The publication brings national, business, city and world '
                      'news together in a concise daily edition. Content and '
                      'delivery details are shown here so the customer can review '
                      'the subscription before adding it.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: DailyColors.charcoal,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // What's included
                    const Text(
                      'What’s Included',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    ...[
                      'Daily Morning Newspaper',
                      'Sunday Special Edition',
                      'Access to Weekly Review',
                      'English Newspaper Edition',
                    ].map(
                      (x) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check,
                              size: 18,
                              color: DailyColors.oliveDark,
                            ),
                            const SizedBox(width: 6),
                            Text(x, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price + Subscribe
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MONTHLY PRICE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: DailyColors.gray,
                                  letterSpacing: 1,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                price,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: PrimaryButton(
                            label: 'SUBSCRIBE NOW',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Subscribe to $name?'),
                                  content: Text(
                                    'Subscribe for $price and receive this newspaper at your registered delivery address.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('CANCEL'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: DailyColors.burgundy,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('CONFIRM SUBSCRIPTION'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !context.mounted) return;
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Subscription Confirmed'),
                                  content: Text(
                                    '$name has been added to your active subscriptions.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 17, color: DailyColors.burgundy),

          const SizedBox(width: 8),

          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: DailyColors.gray),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
