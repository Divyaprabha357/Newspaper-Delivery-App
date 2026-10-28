import 'package:flutter/material.dart';

import '../../services/role_api_service.dart';
import '../../services/role_session_service.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/daily_widgets.dart';
import 'partner_models.dart';
import 'partner_widgets.dart';

class PartnerCustomerScreen extends StatefulWidget {
  final RouteCustomer customer;
  final VoidCallback onBack;
  final VoidCallback? onStatusUpdated;
  const PartnerCustomerScreen({
    super.key,
    required this.customer,
    required this.onBack,
    this.onStatusUpdated,
  });

  @override
  State<PartnerCustomerScreen> createState() => _PartnerCustomerScreenState();
}

class _PartnerCustomerScreenState extends State<PartnerCustomerScreen> {
  late bool delivered;
  late List<bool> selected;
  String issue = 'Customer not available';

  @override
  void initState() {
    super.initState();
    delivered = widget.customer.deliveryStatus == 'DELIVERED';
    selected = List<bool>.filled(widget.customer.newspapers.length, delivered);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Text(widget.customer.name, style: AppTextStyles.pageTitle),
      const SizedBox(height: 8),
      Text(
        '${widget.customer.address}\n${widget.customer.area}',
        style: AppTextStyles.body.copyWith(
          color: DailyColors.gray,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 22),
      Text('DELIVERY INSTRUCTIONS', style: AppTextStyles.sectionHeaderAccent),
      const SizedBox(height: 8),
      Text(widget.customer.instructions, style: AppTextStyles.body),
      const SizedBox(height: 25),
      Text("TODAY'S NEWSPAPERS", style: AppTextStyles.sectionHeaderAccent),
      ...widget.customer.newspapers.map(
        (paper) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            delivered ? Icons.check_circle : Icons.circle_outlined,
            color: delivered ? DailyColors.success : DailyColors.gray,
          ),
          title: Text(paper, style: AppTextStyles.bodyBold),
          trailing: Text(widget.customer.time, style: AppTextStyles.caption),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'STATUS: ${delivered ? 'DELIVERED' : (widget.customer.deliveryStatus ?? 'PENDING')}',
        style: AppTextStyles.cardTitle,
      ),
      const SizedBox(height: 28),
      PrimaryButton(label: 'MARK AS DELIVERED', onPressed: _showConfirmation),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: _showIssue,
        style: OutlinedButton.styleFrom(
          foregroundColor: DailyColors.burgundy,
          side: const BorderSide(color: DailyColors.burgundy),
          minimumSize: const Size.fromHeight(48),
          textStyle: AppTextStyles.button.copyWith(color: DailyColors.burgundy),
        ),
        child: const Text('REPORT DELIVERY ISSUE'),
      ),
    ];
    return PartnerPage(
      title: 'Customer #${widget.customer.number}',
      onBack: widget.onBack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
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
              Text(
                "TODAY'S DELIVERY — ${widget.customer.name}",
                style: AppTextStyles.cardTitleLarge,
              ),
              ...widget.customer.newspapers.map((paper) {
                final index = widget.customer.newspapers.indexOf(paper);
                return CheckboxListTile(
                  value: index < selected.length ? selected[index] : false,
                  activeColor: DailyColors.burgundy,
                  onChanged: (value) => setModalState(() {
                    if (index < selected.length) {
                      selected[index] = value ?? false;
                    }
                  }),
                  title: Text(paper, style: AppTextStyles.body),
                );
              }),
              PrimaryButton(
                label: 'CONFIRM DELIVERY',
                onPressed: () async {
                  if (selected.any((value) => value)) {
                    final session = await RoleSessionService.getPartner();
                    final userId = int.tryParse('${session?['user_id']}');
                    final partnerId = int.tryParse('${session?['partner_id']}');
                    final targetId =
                        widget.customer.deliveryId ??
                        widget.customer.assignmentId;
                    if (userId == null || targetId == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This delivery is not connected to the server.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    try {
                      final status = selected.every((value) => value)
                          ? 'DELIVERED'
                          : 'PARTIALLY_DELIVERED';
                      await RoleApiService(
                        authToken: session?['session_token']?.toString(),
                      ).updatePartnerDelivery(
                        userId: userId,
                        partnerId: partnerId,
                        deliveryId: targetId,
                        assignmentId: widget.customer.assignmentId,
                        status: status,
                        items: [
                          for (
                            var index = 0;
                            index < widget.customer.itemIds.length;
                            index++
                          )
                            {
                              'delivery_item_id':
                                  widget.customer.itemIds[index],
                              'status':
                                  selected.length > index && selected[index]
                                  ? 'DELIVERED'
                                  : 'NOT_DELIVERED',
                            },
                        ],
                      );
                    } on RoleApiException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                      return;
                    }
                    if (context.mounted) Navigator.pop(context);
                    setState(() => delivered = true);
                    widget.onStatusUpdated?.call();
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
              Text('DELIVERY ISSUE', style: AppTextStyles.cardTitleLarge),
              RadioGroup<String>(
                groupValue: issue,
                onChanged: (value) {
                  if (value != null) setModalState(() => issue = value);
                },
                child: Column(
                  children:
                      [
                            'Customer not available',
                            'Address inaccessible',
                            'Newspaper damaged',
                            'Other',
                          ]
                          .map(
                            (reason) => RadioListTile<String>(
                              value: reason,
                              activeColor: DailyColors.burgundy,
                              title: Text(reason, style: AppTextStyles.body),
                            ),
                          )
                          .toList(),
                ),
              ),
              PrimaryButton(
                label: 'SUBMIT ISSUE',
                onPressed: () async {
                  final session = await RoleSessionService.getPartner();
                  final userId = int.tryParse('${session?['user_id']}');
                  final partnerId = int.tryParse('${session?['partner_id']}');
                  final targetId =
                      widget.customer.deliveryId ??
                      widget.customer.assignmentId;
                  if (userId == null || targetId == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This delivery is not connected to the server.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  final failureReasonMap = {
                    'Customer not available': 1,
                    'Address inaccessible': 2,
                    'Newspaper damaged': 3,
                    'Other': 6,
                  };
                  try {
                    await RoleApiService(
                      authToken: session?['session_token']?.toString(),
                    ).updatePartnerDelivery(
                      userId: userId,
                      partnerId: partnerId,
                      deliveryId: targetId,
                      assignmentId: widget.customer.assignmentId,
                      status: 'NOT_DELIVERED',
                      failureReasonId: failureReasonMap[issue] ?? 6,
                      remarks: issue,
                    );
                  } on RoleApiException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(error.message)));
                    }
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                  setState(() => delivered = false);
                  widget.onStatusUpdated?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
