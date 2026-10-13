import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';

class ServiceRequestScreen extends StatelessWidget {
  const ServiceRequestScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final requests = [
      ('Change Newspaper', 'Switch to another daily edition.', Icons.sync_alt),
      (
        'Change Address',
        'Update your delivery address.',
        Icons.location_on_outlined,
      ),
      ('Change Delivery Time', 'Modify delivery time slot.', Icons.schedule),
      (
        'Missed Delivery',
        'Report a missed newspaper.',
        Icons.report_problem_outlined,
      ),
      ('Other Request', 'Create a custom request.', Icons.chat_bubble_outline),
    ];
    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Service Requests',
                onBack: () => Navigator.pop(context),
                trailing: const Icon(Icons.info_outline, size: 18),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                children: [
                  const Text(
                    'How can we help?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...requests.map(
                    (r) => InkWell(
                      onTap: () => _dialog(context, r.$1),
                      child: Container(
                        height: 55,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: DailyColors.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7EDEA),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                r.$3,
                                size: 17,
                                color: DailyColors.burgundy,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.$1,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    r.$2,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: DailyColors.gray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: DailyColors.gray,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4DADA),
                      border: Border.all(color: const Color(0xFFE2B4B4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: DailyColors.burgundy,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Need instant help?\nOur customer support team is available for urgent delivery issues. CONTACT SUPPORT →',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: DailyColors.burgundy,
                              fontWeight: FontWeight.w600,
                            ),
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

  void _dialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          'Enter the details for your $title request. Your request will receive a tracking ID after submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: DailyColors.gray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: DailyColors.burgundy,
              foregroundColor: Colors.white,
            ),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}


