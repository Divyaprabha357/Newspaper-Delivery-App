import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class DailyHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;

  const DailyHeader({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DailyColors.divider)),
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (onBack != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left, size: 28),
            )
          else
            const SizedBox(width: 28),
          Expanded(
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headerTitle,
            ),
          ),
          trailing ?? const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class DailyBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const DailyBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 68,
      backgroundColor: DailyColors.cream,
      indicatorColor: Colors.transparent,
      selectedIndex: selectedIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Subscriptions',
        ),
        NavigationDestination(
          icon: Icon(Icons.credit_card_outlined),
          selectedIcon: Icon(Icons.credit_card),
          label: 'Payments',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class Rule extends StatelessWidget {
  const Rule({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: DailyColors.divider);
}

class StatusDot extends StatelessWidget {
  final Color color;
  const StatusDot(this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class NewspaperThumb extends StatelessWidget {
  final String title;
  final double width;
  const NewspaperThumb({super.key, required this.title, this.width = 54});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.35,
      decoration: BoxDecoration(
        color: DailyColors.white,
        border: Border.all(color: DailyColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset('assets/icons/newspaper.svg', fit: BoxFit.cover),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: DailyColors.white.withValues(alpha: .9),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.metadata.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: DailyColors.charcoal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DailyColors.burgundy,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(label, style: AppTextStyles.buttonSmall),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTextStyles.sectionHeader);
}
