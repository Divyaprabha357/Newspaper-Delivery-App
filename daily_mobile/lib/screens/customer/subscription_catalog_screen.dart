import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'newspaper_detail_screen.dart';

class SubscriptionCatalogScreen extends StatefulWidget {
  const SubscriptionCatalogScreen({super.key});

  @override
  State<SubscriptionCatalogScreen> createState() =>
      _SubscriptionCatalogScreenState();
}

class _SubscriptionCatalogScreenState extends State<SubscriptionCatalogScreen> {
  final activeSubscriptions = const [
    (
      'The Times of India',
      '₹550 / MONTH',
      'English',
      'National Daily Editions',
      'Rahul Patil',
    ),
    (
      'The Hindu',
      '₹550 / MONTH',
      'English',
      'National Daily Editions',
      'Rahul Patil',
    ),
  ];

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
                title: 'My Subscriptions',
                trailing: Text(
                  '${activeSubscriptions.length} ACTIVE',
                  style: const TextStyle(
                    fontSize: 14,
                    color: DailyColors.burgundy,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 90),
                children: [
                  const Text(
                    'Your active newspapers',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap a newspaper to view all publication and delivery details.',
                    style: TextStyle(
                      fontSize: 14,
                      color: DailyColors.gray,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...activeSubscriptions.map(
                    (subscription) => _ActiveSubscriptionCard(
                      name: subscription.$1,
                      price: subscription.$2,
                      language: subscription.$3,
                      supplier: subscription.$4,
                      partner: subscription.$5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DailyColors.burgundy,
        foregroundColor: Colors.white,
        tooltip: 'Add newspaper',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _NewspaperCatalogScreen()),
          );
        },
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'ADD NEW SUBSCRIPTION',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  final String name;
  final String price;
  final String language;
  final String supplier;
  final String partner;

  const _ActiveSubscriptionCard({
    required this.name,
    required this.price,
    required this.language,
    required this.supplier,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: DailyColors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: DailyColors.divider),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewspaperDetailScreen(name: name, price: price),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              NewspaperThumb(title: name, width: 88),
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ACTIVE â€¢ $language',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DailyColors.oliveDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Supplier: $supplier',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DailyColors.gray,
                      ),
                    ),
                    Text(
                      'Partner: $partner â€¢ 7:30 AM',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DailyColors.gray,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        color: DailyColors.burgundy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 26,
                color: DailyColors.burgundy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewspaperCatalogScreen extends StatefulWidget {
  const _NewspaperCatalogScreen();

  @override
  State<_NewspaperCatalogScreen> createState() =>
      _NewspaperCatalogScreenState();
}

class _NewspaperCatalogScreenState extends State<_NewspaperCatalogScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final papers = [
      ('The Times of India', '₹550 / MONTH'),
      ('The Hindu', '₹550 / MONTH'),
      ('Indian Express', '₹500 / MONTH'),
      ('Business Standard', '₹450 / MONTH'),
    ];

    final visiblePapers = papers
        .where((paper) => paper.$1.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: DailyColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 8),
              child: DailyHeader(
                title: 'Newspapers',
                onBack: () => Navigator.pop(context),
                trailing: const Icon(Icons.search, size: 23),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
                children: [
                  TextField(
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search newspapers...',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 22),
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...visiblePapers.map(
                    (paper) => InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewspaperDetailScreen(
                            name: paper.$1,
                            price: paper.$2,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          children: [
                            NewspaperThumb(title: paper.$1, width: 76),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paper.$1,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'English â€¢ National â€¢ Daily',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DailyColors.gray,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    paper.$2,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: DailyColors.burgundy,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 26,
                              color: DailyColors.burgundy,
                            ),
                          ],
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


