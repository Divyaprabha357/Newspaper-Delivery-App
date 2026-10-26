import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import '../../services/customer_api_service.dart';
import '../../services/session_service.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];
  String _selectedFilter = 'ALL';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = await SessionService.getCustomerId();
    if (id == null) {
      if (mounted) setState(() { loading = false; error = 'Your session has expired.'; });
      return;
    }
    try {
      final response = await CustomerApiService().deliveryHistory(id);
      if (mounted) {
        setState(() {
          items = List<dynamic>.from(response['deliveries'] as List? ?? []);
          loading = false;
        });
      }
    } on CustomerApiException catch (e) {
      if (mounted) setState(() { loading = false; error = e.message; });
    }
  }

  List<dynamic> get _filteredItems {
    return items.where((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final status = (row['item_status'] ?? row['delivery_status'] ?? 'UNKNOWN').toString().toUpperCase();
      final paper = (row['newspaper_name'] ?? '').toString().toLowerCase();
      final date = (row['delivery_date'] ?? '').toString().toLowerCase();

      // Filter by category
      bool matchesCategory = true;
      if (_selectedFilter == 'DELIVERED') {
        matchesCategory = status.contains('DELIVER') && !status.contains('NOT');
      } else if (_selectedFilter == 'DELAYED') {
        matchesCategory = status.contains('DELAY');
      } else if (_selectedFilter == 'MISSED') {
        matchesCategory = status.contains('NOT') || status.contains('MISSED') || status.contains('FAIL');
      }

      if (!matchesCategory) return false;

      // Filter by search query
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        return paper.contains(query) || date.contains(query) || status.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

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
                trailing: IconButton(
                  icon: Icon(_showSearch ? Icons.close : Icons.search, size: 20),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) _searchController.clear();
                    });
                  },
                ),
              ),
            ),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search newspaper, date, status...',
                    hintStyle: const TextStyle(fontSize: 13, color: DailyColors.gray),
                    prefixIcon: const Icon(Icons.search, size: 18, color: DailyColors.gray),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: DailyColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: DailyColors.divider),
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                children: [
                  const Text(
                    'Timeline',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your journey of informed mornings, recorded day by day.',
                    style: TextStyle(fontSize: 14, color: DailyColors.gray),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'DELIVERED', 'DELAYED', 'MISSED']
                          .map(
                            (x) {
                              final isSelected = _selectedFilter == x;
                              return Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedFilter = x),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? DailyColors.burgundy
                                          : DailyColors.white,
                                      border: Border.all(
                                        color: isSelected ? DailyColors.burgundy : DailyColors.divider,
                                      ),
                                    ),
                                    child: Text(
                                      x,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.white
                                            : DailyColors.charcoal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: DailyColors.burgundy)),
                    )
                  else if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Text(error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () {
                            setState(() { loading = true; error = null; });
                            _load();
                          },
                          child: const Text('TRY AGAIN'),
                        ),
                      ]),
                    )
                  else if (items.isEmpty)
                    const Padding(padding: EdgeInsets.all(20), child: Text('No delivery history yet.'))
                  else if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: DailyColors.white,
                        border: Border.all(color: DailyColors.divider),
                      ),
                      child: const Center(
                        child: Text(
                          'No deliveries match the selected filter or search.',
                          style: TextStyle(color: DailyColors.gray, fontSize: 13),
                        ),
                      ),
                    )
                  else Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DailyColors.white,
                      border: Border.all(color: DailyColors.divider),
                    ),
                    child: Column(
                      children: List.generate(filtered.length, (i) {
                        final row = Map<String, dynamic>.from(filtered[i] as Map);
                        final status = (row['item_status'] ?? row['delivery_status'] ?? 'UNKNOWN').toString().toUpperCase();
                        final color = status.contains('DELIVER') && !status.contains('NOT')
                            ? DailyColors.success
                            : DailyColors.warning;
                        final timeStr = row['actual_time'] ?? row['scheduled_time'] ?? '—';
                        return _item(
                          (row['delivery_date'] ?? '—').toString(),
                          (row['newspaper_name'] ?? 'Newspaper').toString(),
                          '$status • $timeStr',
                          color,
                          i == filtered.length - 1,
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
                  fontSize: 12,
                  color: DailyColors.gray,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                paper,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
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
