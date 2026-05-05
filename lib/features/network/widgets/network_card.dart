import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/network_person.dart';
import '../../../shared/painters/card_pattern_painter.dart';
import '../../../shared/widgets/app_avatar.dart';

class NetworkCard extends StatelessWidget {
  const NetworkCard({super.key, required this.person, required this.onTap});

  final NetworkPerson person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
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
                  color: const Color(0xFFB8CCCF),
                  child: CustomPaint(
                    painter: CardPatternPainter(color: person.color),
                    child: const SizedBox.expand(),
                  ),
                ),
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
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
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, color: AppColors.muted, size: 18),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'جامعة القاهرة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
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
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'تواصل',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
