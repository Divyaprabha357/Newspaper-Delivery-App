import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'partner_models.dart';
import 'partner_widgets.dart';

class PartnerCustomerScreen extends StatefulWidget {
  final RouteCustomer customer;
  final VoidCallback onBack;
  const PartnerCustomerScreen({super.key, required this.customer, required this.onBack});

  @override
  State<PartnerCustomerScreen> createState() => _PartnerCustomerScreenState();
}

class _PartnerCustomerScreenState extends State<PartnerCustomerScreen> {
  bool delivered = false;
  final selected = <bool>[false, false];
  String issue = 'Customer not available';

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Text(widget.customer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('${widget.customer.address}\n${widget.customer.area}', style: const TextStyle(color: DailyColors.gray, height: 1.5)),
      const SizedBox(height: 22),
      const Text('DELIVERY INSTRUCTIONS', style: TextStyle(fontSize: 14, letterSpacing: 1.3, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(widget.customer.instructions),
      const SizedBox(height: 25),
      const Text("TODAY'S NEWSPAPERS", style: TextStyle(fontSize: 14, letterSpacing: 1.3, color: DailyColors.burgundy, fontWeight: FontWeight.bold)),
      ...widget.customer.newspapers.map((paper) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(delivered ? Icons.check_circle : Icons.circle_outlined, color: delivered ? DailyColors.success : DailyColors.gray), title: Text(paper), trailing: Text(widget.customer.time, style: const TextStyle(fontSize: 12, color: DailyColors.gray)))),
      const SizedBox(height: 18),
      Text('STATUS: ${delivered ? 'DELIVERED' : 'NOT DELIVERED'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 28),
      PrimaryButton(label: 'MARK AS DELIVERED', onPressed: _showConfirmation),
      const SizedBox(height: 10),
      OutlinedButton(onPressed: _showIssue, style: OutlinedButton.styleFrom(foregroundColor: DailyColors.burgundy, side: const BorderSide(color: DailyColors.burgundy), minimumSize: const Size.fromHeight(48)), child: const Text('REPORT DELIVERY ISSUE')),
    ];
    return PartnerPage(
      title: 'Customer #${widget.customer.number}',
      onBack: widget.onBack,
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 22, 24, 35), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
    );
  }

  void _showConfirmation() {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("TODAY'S DELIVERY — ${widget.customer.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...widget.customer.newspapers.map((paper) => CheckboxListTile(
                value: selected[widget.customer.newspapers.indexOf(paper)],
                activeColor: DailyColors.burgundy,
                onChanged: (value) => setModalState(() => selected[widget.customer.newspapers.indexOf(paper)] = value ?? false),
                title: Text(paper),
              )),
              PrimaryButton(
                label: 'CONFIRM DELIVERY',
                onPressed: () async {
                  if (selected.any((value) => value)) {
                    final session = await RoleSessionService.getPartner();
                    final userId = int.tryParse('${session?['user_id']}');
                    if (userId == null || widget.customer.deliveryId == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This delivery is not connected to the server.')));
                      }
                      return;
                    }
                    try {
                      await RoleApiService(
                        authToken: session?['session_token']?.toString(),
                      ).updatePartnerDelivery(
                        userId: userId,
                        deliveryId: widget.customer.deliveryId!,
                        status: selected.every((value) => value) ? 'DELIVERED' : 'PARTIALLY_DELIVERED',
                        items: [
                          for (var index = 0; index < widget.customer.itemIds.length; index++)
                            {
                              'delivery_item_id': widget.customer.itemIds[index],
                              'status': selected.length > index && selected[index] ? 'DELIVERED' : 'NOT_DELIVERED',
                            },
                        ],
                      );
                    } on RoleApiException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                      return;
                    }
                    Navigator.pop(context);
                    setState(() => delivered = true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIssue() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DELIVERY ISSUE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...['Customer not available', 'Address inaccessible', 'Newspaper damaged', 'Other'].map((reason) => RadioListTile<String>(
                value: reason,
                groupValue: issue,
                activeColor: DailyColors.burgundy,
                onChanged: (value) => setModalState(() => issue = value!),
                title: Text(reason),
              )),
              PrimaryButton(label: 'SUBMIT ISSUE', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
