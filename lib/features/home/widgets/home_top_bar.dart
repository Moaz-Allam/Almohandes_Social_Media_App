import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/search_pill.dart';
import '../../search/search_screen.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onMenu,
    required this.onMessages,
    this.hint = 'بحث',
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;
  final String hint;

  void _openSearch(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border(bottom: BorderSide(color: context.appBorder)),
        ),
        child: Row(
          children: [
            GestureDetector(
              key: const ValueKey('home-menu-avatar'),
              onTap: onMenu,
              child: const AppAvatar(
                name: 'ريم حسن',
                radius: 20,
                color: AppColors.darkBlue,
                badge: 'مهندسة',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _openSearch(context),
                borderRadius: BorderRadius.circular(4),
                child: SearchPill(hint: hint),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onMessages,
              icon: const Icon(Icons.chat_bubble, color: AppColors.muted),
              tooltip: 'الرسائل',
            ),
          ],
        ),
      ),
    );
  }
}
