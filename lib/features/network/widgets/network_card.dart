import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/network_person.dart';
import '../../../shared/painters/card_pattern_painter.dart';
import '../../../shared/widgets/app_avatar.dart';

class NetworkCard extends StatelessWidget {
  const NetworkCard({
    super.key,
    required this.person,
    required this.onTap,
    required this.onAction,
    this.loading = false,
  });

  final NetworkPerson person;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.appBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 64,
                  color: context.appSurfaceAlt,
                  child: CustomPaint(
                    painter: CardPatternPainter(color: person.color),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  bottom: -38,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AppAvatar(
                      name: person.name,
                      radius: 39,
                      color: person.color,
                      badge: person.badge,
                      imageUrl: person.avatarUrl,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 46),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 118,
                child: Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 126,
                child: Text(
                  person.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appMuted,
                    fontSize: 12.5,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    person.isCompany
                        ? Icons.business_outlined
                        : Icons.school_outlined,
                    color: context.appMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      person.contextLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 34,
                child: OutlinedButton(
                  onPressed: loading ? null : onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: loading
                        ? AppColors.darkBlue
                        : AppColors.blue,
                    disabledForegroundColor: AppColors.darkBlue,
                    side: BorderSide(
                      color: loading ? AppColors.darkBlue : AppColors.blue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          person.actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
