import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DailyDivider extends StatelessWidget {
  const DailyDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.divider, thickness: 1, height: 1);
  }
}
