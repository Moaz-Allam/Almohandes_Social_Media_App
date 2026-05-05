import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/app_tab.dart';

class LinkedBottomNavigation extends StatelessWidget {
  const LinkedBottomNavigation({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  final AppTab selectedTab;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'الرئيسية',
                selected: selectedTab == AppTab.feed,
                onTap: () => onChanged(AppTab.feed),
              ),
              _NavItem(
                icon: Icons.people_alt,
                label: 'شبكتي',
                selected: selectedTab == AppTab.network,
                badge: '4',
                onTap: () => onChanged(AppTab.network),
              ),
              _NavItem(
                icon: Icons.add_box,
                label: 'نشر',
                selected: selectedTab == AppTab.composer,
                onTap: () => onChanged(AppTab.composer),
              ),
              _NavItem(
                icon: Icons.smart_display,
                label: 'ريلز',
                selected: selectedTab == AppTab.reels,
                onTap: () => onChanged(AppTab.reels),
              ),
              _NavItem(
                icon: Icons.folder_special,
                label: 'مشاريع',
                selected: selectedTab == AppTab.projects,
                onTap: () => onChanged(AppTab.projects),
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
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.black : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              color: selected ? AppColors.blue : Colors.transparent,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: color, size: 26),
                      if (badge != null)
                        PositionedDirectional(
                          end: -8,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
