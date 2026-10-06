import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class DailyLogo extends StatelessWidget {
  final double fontSize;

  const DailyLogo({super.key, this.fontSize = 42});

  @override
  Widget build(BuildContext context) {
    return Text('DAILY', style: AppTextStyles.logo(fontSize: fontSize));
  }
}
