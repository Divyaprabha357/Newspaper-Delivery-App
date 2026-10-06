import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      (
        'Delivery confirmed',
        'The Hindu arrived at 7:05 AM.',
        'TODAY',
        Icons.check_circle_outline,
        DailyColors.success,
      ),
      (
        'Delayed delivery',
        'First post: 10th oct',
        'YESTERDAY',
        Icons.access_time,
        DailyColors.warning,
      ),
      (
        'Payment received',
        '₹550 paid for The Hindu',
        'TODAY',
        Icons.credit_card,
        DailyColors.olive,
      ),
      (
        'Missed delivery',
        'Your newspaper was not delivered.',
        '5 SEP',
        Icons.warning_amber_outlined,
        DailyColors.warning,
      ),
      (
        'Special offer',
        'Get 20% off annual subscriptions',
        '5 SEP',
        Icons.local_offer_outlined,
        DailyColors.burgundy,
      ),
      (
        'Newspaper update',
        'The Times of India has a new edition',
        '2 SEP',
        Icons.article_outlined,
        DailyColors.gray,
      ),
      (
        'Terms update',
        'The Times of India has a new edition',
        '2 SEP',
        Icons.description_outlined,
        DailyColors.gray,
      ),
    ];

    return Scaffold(
      backgroundColor: DailyColors.cream,

      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------
            // HEADER
            // --------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Notifications',
                onBack: () => Navigator.pop(context),
                trailing: const Icon(Icons.search, size: 19),
              ),
            ),

            // --------------------------------
            // NOTIFICATIONS
            // --------------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                children: [
                  // --------------------------------
                  // FILTERS
                  // --------------------------------

                  Row(
                    children: ['ALL', 'IMPORTANT']
                        .map(
                          (x) => Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: x == 'ALL'
                                    ? DailyColors.burgundy
                                    : DailyColors.white,

                                border: Border.all(color: DailyColors.divider),
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

                  const SizedBox(height: 8),

                  // --------------------------------
                  // NOTIFICATION LIST
                  // --------------------------------
                  Container(
                    decoration: BoxDecoration(
                      color: DailyColors.white,
                      border: Border.all(color: DailyColors.divider),
                    ),

                    child: Column(
                      children: notifications.map((notification) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),

                          // ICON
                          leading: Container(
                            width: 31,
                            height: 31,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F0E9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notification.$4,
                              size: 16,
                              color: notification.$5,
                            ),
                          ),

                          // TITLE
                          title: Text(
                            notification.$1,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // DESCRIPTION
                          subtitle: Text(
                            notification.$2,
                            style: const TextStyle(
                              fontSize: 8,
                              color: DailyColors.gray,
                            ),
                          ),

                          // DATE
                          trailing: Text(
                            notification.$3,
                            style: const TextStyle(
                              fontSize: 7,
                              color: DailyColors.gray,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --------------------------------
                  // MARK ALL AS READ
                  // --------------------------------
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'MARK ALL AS READ →',
                        style: TextStyle(
                          fontSize: 8,
                          color: DailyColors.burgundy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
