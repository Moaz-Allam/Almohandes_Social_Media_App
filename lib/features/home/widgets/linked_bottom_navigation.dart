import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_tab.dart';

/// Bottom navigation styled after the web dashboard's footer/nav:
/// translucent surface, rounded pill-shaped active indicator, and
/// Lucide-equivalent Material icons.
class LinkedBottomNavigation extends StatelessWidget {
  const LinkedBottomNavigation({
    super.key,
    required this.selectedTab,
    required this.onChanged,
    this.showDashboard = true,
  });

  final AppTab selectedTab;
  final ValueChanged<AppTab> onChanged;

  /// Whether the engineer-only dashboard tab is shown. Non-engineer
  /// accounts have it hidden entirely.
  final bool showDashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(
          top: BorderSide(color: context.appBorder.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.35 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'الرئيسية',
                selected: selectedTab == AppTab.feed,
                onTap: () => onChanged(AppTab.feed),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                activeIcon: Icons.search_rounded,
                label: 'البحث',
                selected: selectedTab == AppTab.search,
                onTap: () => onChanged(AppTab.search),
              ),
              if (showDashboard)
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'لوحة المهندس',
                  selected: selectedTab == AppTab.dashboard,
                  onTap: () => onChanged(AppTab.dashboard),
                ),
              _NavItem(
                icon: Icons.play_circle_outline_rounded,
                activeIcon: Icons.play_circle_rounded,
                label: 'reels',
                selected: selectedTab == AppTab.reels,
                onTap: () => onChanged(AppTab.reels),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'حسابي',
                selected: selectedTab == AppTab.profile,
                onTap: () => onChanged(AppTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.appPrimary : context.appMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: context.appPrimary.withValues(alpha: 0.08),
        highlightColor: context.appPrimary.withValues(alpha: 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? context.appPrimary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
