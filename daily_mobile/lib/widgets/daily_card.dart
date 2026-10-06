import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DailyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const DailyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,

      decoration: BoxDecoration(
        color: AppColors.offWhite,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppColors.border, width: 1),
      ),

      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(12),

      child: card,
    );
  }
}
