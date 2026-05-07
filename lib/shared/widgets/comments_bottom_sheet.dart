import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_scope.dart';
import 'app_avatar.dart';

Future<void> showLinkedCommentsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const LinkedCommentsSheet(),
  );
}

class LinkedCommentsSheet extends StatelessWidget {
  const LinkedCommentsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .96,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 58,
                height: 5,
                decoration: BoxDecoration(
                  color: context.appText,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'التعليقات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
                  children: const [
                    Icon(
                      Icons.mode_comment_outlined,
                      color: AppColors.muted,
                      size: 44,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد تعليقات بعد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'ستظهر التعليقات هنا بعد إضافتها من Supabase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  border: Border(top: BorderSide(color: context.appBorder)),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      name: name,
                      radius: 20,
                      color: AppColors.darkBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'أضف تعليقا...',
                          filled: true,
                          fillColor: context.appSurfaceAlt,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(26),
                            borderSide: BorderSide(color: context.appBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(26),
                            borderSide: BorderSide(color: context.appBorder),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
