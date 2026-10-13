import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import 'supplier_design_system.dart';

class SupplierNewspapersScreen extends StatefulWidget {
  const SupplierNewspapersScreen({super.key});

  @override
  State<SupplierNewspapersScreen> createState() =>
      _SupplierNewspapersScreenState();
}

class _SupplierNewspapersScreenState extends State<SupplierNewspapersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _language = 'All Languages';
  String _status = 'All Status';

  final List<_NewspaperRecord> _newspapers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNewspapers();
  }

  Future<void> _loadNewspapers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await RoleSessionService.getSupplier();
      final userId = int.tryParse('${session?['user_id']}');
      if (userId == null) throw const RoleApiException('No authenticated Supplier session is available.');
      final response = await RoleApiService(
        authToken: session?['session_token']?.toString(),
      ).supplierNewspapers(userId);
      final rows = (response['newspapers'] as List? ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .map((row) => _NewspaperRecord(
                id: '${row['newspaper_id']}',
                name: '${row['newspaper_name'] ?? supplierMissingValue}',
                language: '${row['language'] ?? supplierMissingValue}',
                price: num.tryParse('${row['price_per_delivery']}'),
                status: '${row['availability_status'] ?? 'INACTIVE'}',
                nextAvailable: row['available_from']?.toString(),
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _newspapers
          ..clear()
          ..addAll(rows);
        _loading = false;
      });
    } on RoleApiException catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Unable to load supplier newspapers.'; });
    }
  }

  List<_NewspaperRecord> get _filteredNewspapers {
    final query = _searchController.text.trim().toLowerCase();
    return _newspapers.where((newspaper) {
      final matchesSearch = query.isEmpty ||
          newspaper.name.toLowerCase().contains(query) ||
          newspaper.language.toLowerCase().contains(query);
      final matchesLanguage = _language == 'All Languages' ||
          newspaper.language == _language;
      final matchesStatus =
          _status == 'All Status' || _labelForStatus(newspaper.status) == _status;
      return matchesSearch && matchesLanguage && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _language = 'All Languages';
      _status = 'All Status';
    });
  }

  String _labelForStatus(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Available';
      case 'TEMPORARILY_UNAVAILABLE':
        return 'Temporarily Unavailable';
      default:
        return 'Inactive';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return DailyColors.success;
      case 'TEMPORARILY_UNAVAILABLE':
        return DailyColors.warning;
      default:
        return DailyColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: DailyColors.burgundy));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: DailyColors.gray)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _loadNewspapers, child: const Text('TRY AGAIN')),
      ]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAILY DISTRIBUTION',
            style: TextStyle(
              color: DailyColors.burgundy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Newspapers & Availability',
            style: TextStyle(
              color: DailyColors.charcoal,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          _toolbar(),
          const SizedBox(height: 14),
          _table(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final search = TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search newspapers...',
            prefixIcon: Icon(Icons.search, size: 18),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
        final language = _filterDropdown(
          value: _language,
          items: const [
            'All Languages',
            'English',
            'Hindi',
            'Marathi',
            'Malayalam',
          ],
          onChanged: (value) => setState(() => _language = value!),
        );
        final status = _filterDropdown(
          value: _status,
          items: const [
            'All Status',
            'Available',
            'Temporarily Unavailable',
            'Inactive',
          ],
          onChanged: (value) => setState(() => _status = value!),
        );

        if (compact) {
          return Column(
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: language),
                  const SizedBox(width: 8),
                  Expanded(child: status),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 5, child: search),
            const SizedBox(width: 8),
            SizedBox(width: 165, child: language),
            const SizedBox(width: 8),
            SizedBox(width: 190, child: status),
          ],
        );
      },
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _table() {
    final records = _filteredNewspapers;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      child: records.isEmpty ? _emptyState() : _recordsTable(records),
    );
  }

  Widget _recordsTable(List<_NewspaperRecord> records) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Table(
          columnWidths: const {
            0: FlexColumnWidth(3.6),
            1: FlexColumnWidth(1.8),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.8),
            4: FlexColumnWidth(1.6),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: DailyColors.divider),
          ),
          children: [
            _headerRow(),
            ...records.map(_dataRow),
          ],
        );
      },
    );
  }

  TableRow _headerRow() {
    return const TableRow(
      children: [
        _TableHeaderCell('NEWSPAPER'),
        _TableHeaderCell('LANGUAGE'),
        _TableHeaderCell('PRICE (\u20B9)'),
        _TableHeaderCell('AVAILABILITY'),
        _TableHeaderCell('NEXT AVAILABLE'),
      ],
    );
  }

  TableRow _dataRow(_NewspaperRecord newspaper) {
    final color = _statusColor(newspaper.status);
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              _Thumbnail(name: newspaper.name),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  newspaper.name,
                  style: const TextStyle(
                    color: DailyColors.charcoal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        _cell(Text(newspaper.language)),
        _cell(Text(supplierCurrency(newspaper.price))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              color: color.withValues(alpha: .12),
              child: Text(
                _labelForStatus(newspaper.status),
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        _cell(
          Text(
            newspaper.nextAvailable ?? supplierMissingValue,
            style: const TextStyle(color: DailyColors.gray),
          ),
        ),
      ],
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.newspaper_outlined,
            size: 30,
            color: DailyColors.gray,
          ),
          const SizedBox(height: 10),
          const Text(
            'No newspapers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try changing your search or filters.',
            style: TextStyle(fontSize: 16, color: DailyColors.gray),
          ),
          const SizedBox(height: 9),
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'CLEAR FILTERS',
              style: TextStyle(
                color: DailyColors.burgundy,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewspaperRecord {
  final String id;
  final String name;
  final String language;
  final num? price;
  final String status;
  final String? nextAvailable;

  const _NewspaperRecord({
    required this.id,
    required this.name,
    required this.language,
    required this.price,
    required this.status,
    required this.nextAvailable,
  });
}

class _TableHeaderCell extends StatelessWidget {
  final String label;

  const _TableHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 13, 8, 11),
      child: Text(
        label,
        style: const TextStyle(
          color: DailyColors.gray,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String name;

  const _Thumbnail({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 46,
      decoration: BoxDecoration(
        color: DailyColors.tan,
        border: Border.all(color: DailyColors.divider),
      ),
      alignment: Alignment.center,
      child: Text(
        name
            .split(' ')
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0])
            .join(),
        style: const TextStyle(
          color: DailyColors.burgundy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
