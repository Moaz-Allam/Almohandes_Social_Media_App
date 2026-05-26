import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import 'engineer_ai_chat_screen.dart';
import 'models/premium_course.dart';
import 'premium_access_screen.dart';
import 'premium_course_library_screen.dart';
import 'premium_info_screen.dart';
import 'premium_notes_screen.dart';

class PremiumDashboardScreen extends StatefulWidget {
  const PremiumDashboardScreen({
    super.key,
    this.onMenu,
    this.onMessages,
  });

  final VoidCallback? onMenu;
  final VoidCallback? onMessages;

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> {
  late Future<List<PremiumCourse>> _coursesFuture;
  bool _screenProtectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _coursesFuture = Future.value(const <PremiumCourse>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.read(context);
    _coursesFuture = app.repositories.courses.fetchPremiumCourses();
    _syncScreenProtection(app.hasPremiumLibrary);
  }

  @override
  void dispose() {
    if (_screenProtectionEnabled) {
      unawaited(_disableScreenProtection());
    }
    super.dispose();
  }

  void _syncScreenProtection(bool shouldProtect) {
    if (kIsWeb || shouldProtect == _screenProtectionEnabled) {
      return;
    }
    _screenProtectionEnabled = shouldProtect;
    if (shouldProtect) {
      unawaited(_enableScreenProtection());
    } else {
      unawaited(_disableScreenProtection());
    }
  }

  Future<void> _enableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    } catch (_) {
      try {
        await ScreenProtector.protectDataLeakageOff();
        await ScreenProtector.preventScreenshotOff();
      } catch (_) {
        // Ignore cleanup failures on unsupported platforms.
      }
      _screenProtectionEnabled = false;
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.protectDataLeakageOff();
      await ScreenProtector.preventScreenshotOff();
    } catch (_) {
      // Some platforms do not expose screen protection APIs.
    }
  }

  Future<void> _refreshCourses() async {
    setState(() {
      _coursesFuture = AppScope.read(
        context,
      ).repositories.courses.fetchPremiumCourses(forceRefresh: true);
    });
    await _coursesFuture;
  }

  void _openAiChat() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EngineerAiChatScreen()));
  }

  void _openLibrary(
    String title,
    String subtitle,
    String category,
    List<PremiumCourse> courses,
  ) {
    final filtered = [
      for (final course in courses)
        if (course.category == category) course,
    ];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PremiumCourseLibraryScreen(
          title: title,
          subtitle: subtitle,
          courses: filtered,
          emptyTitle: 'لا توجد فيديوهات منشورة بعد',
        ),
      ),
    );
  }

  void _openNotes() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PremiumNotesScreen()));
  }

  void _openLegalRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PremiumInfoScreen(
          title: 'طلب استشارة قانونية',
          subtitle: 'سجل ملخص المشكلة القانونية وخطوات التعامل معها.',
          icon: Icons.phone_in_talk_outlined,
          showRequestForm: true,
          items: [
            'جهز بيانات المشروع والعقد والمراسلات المرتبطة بالنزاع.',
            'اكتب الوقائع بترتيب زمني واضح قبل إرسال الطلب.',
            'لا تشارك مستندات حساسة إلا عند الحاجة وبعد إخفاء البيانات الخاصة.',
          ],
        ),
      ),
    );
  }

  void _openLegalAffairs() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PremiumInfoScreen(
          title: 'الشؤون القانونية',
          subtitle: 'مراجع مختصرة حول حقوق المهندس والقوانين المهنية.',
          icon: Icons.balance_outlined,
          items: [
            'راجع نطاق العمل والمسؤوليات الفنية قبل توقيع أي اتفاق.',
            'احتفظ بمحاضر الاستلام والملاحظات والمراسلات الرسمية.',
            'وثق أوامر التغيير وتكلفة كل بند قبل بدء التنفيذ.',
            'استخدم عقوداً واضحة في الدفعات والجداول الزمنية وآلية فض النزاع.',
          ],
        ),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('المكتبة الهندسية ستتوفر قريباً')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.watch(context);
    _syncScreenProtection(app.hasPremiumLibrary);
    if (!app.hasPremiumLibrary) {
      return const PremiumAccessScreen();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          HomeTopBar(
            onMenu: widget.onMenu ?? () => Navigator.pop(context), 
            onMessages: widget.onMessages ?? () {}, // Provide fallback if null
          ),
          Expanded(
            child: FutureBuilder<List<PremiumCourse>>(
              future: _coursesFuture,
              builder: (context, snapshot) {
                final courses = snapshot.data ?? const <PremiumCourse>[];
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final cards = _cards(courses);

                return RefreshIndicator(
                  onRefresh: _refreshCourses,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    children: [
                      const Text(
                        'مركز المهندس',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'مكتبات فيديو، ملاحظات، شؤون قانونية، ومساعدة إنجي الذكية في مكان واحد.',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
                      ),
                      if (isLoading) ...[
                        const SizedBox(height: 14),
                        const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
                      ],
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 720 ? 2 : 1;
                          final spacing = 16.0;
                          final itemWidth =
                              (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (final card in cards)
                                SizedBox(
                                  width: itemWidth,
                                  child: _DashboardCard(card: card),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_DashboardCardData> _cards(List<PremiumCourse> courses) {
    final counts = <String, int>{};
    for (final course in courses) {
      counts.update(course.category, (value) => value + 1, ifAbsent: () => 1);
    }
    int? count(String category) {
      final value = counts[category] ?? 0;
      return value == 0 ? null : value;
    }

    return [
      _DashboardCardData(
        title: 'المهندسة إنجي',
        subtitle: 'مساعدتك الذكية للاستشارات',
        color: AppColors.blue,
        avatarAsset: 'assets/premium/engee_avatar.jpeg',
        onTap: _openAiChat,
      ),
      _DashboardCardData(
        title: 'محاضرات نظرية',
        subtitle: 'دروس ومفاهيم أساسية',
        icon: Icons.menu_book_outlined,
        color: AppColors.blue,
        badge: count('theoretical'),
        onTap: () => _openLibrary(
          'محاضرات نظرية',
          'دروس ومفاهيم أساسية مرتبة كفيديوهات تعليمية.',
          'theoretical',
          courses,
        ),
      ),
      _DashboardCardData(
        title: 'محاضرات عملية',
        subtitle: 'تطبيقات وأمثلة عملية',
        icon: Icons.build_outlined,
        color: const Color(0xFF28C98B),
        badge: count('practical'),
        onTap: () => _openLibrary(
          'محاضرات عملية',
          'تطبيقات وأمثلة عملية من واقع المشاريع والمواقع.',
          'practical',
          courses,
        ),
      ),
      _DashboardCardData(
        title: 'تدريب وتطوير',
        subtitle: 'برامج تطوير المهارات',
        icon: Icons.school_outlined,
        color: const Color(0xFF9957E8),
        badge: count('training'),
        onTap: () => _openLibrary(
          'تدريب وتطوير',
          'برامج فيديو لتطوير المهارات الهندسية والمهنية.',
          'training',
          courses,
        ),
      ),
      _DashboardCardData(
        title: 'ملاحظاتي',
        subtitle: 'ملاحظاتك الشخصية',
        icon: Icons.description_outlined,
        color: const Color(0xFFFFA51E),
        onTap: _openNotes,
      ),
      _DashboardCardData(
        title: 'طلب استشارة قانونية',
        subtitle: 'خطوات حل النزاعات القانونية',
        icon: Icons.phone_in_talk_outlined,
        color: const Color(0xFFEF4444),
        onTap: _openLegalRequest,
      ),
      _DashboardCardData(
        title: 'الشؤون القانونية',
        subtitle: 'حقوق المهندس والقوانين',
        icon: Icons.balance_outlined,
        color: const Color(0xFFEF4444),
        onTap: _openLegalAffairs,
      ),
      _DashboardCardData(
        title: 'المكتبة الهندسية',
        subtitle: 'قريباً...',
        icon: Icons.library_books_outlined,
        color: Colors.white24,
        locked: true,
        onTap: _showComingSoon,
      ),
    ];
  }
}

final class _DashboardCardData {
  const _DashboardCardData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.icon,
    this.avatarAsset,
    this.badge,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final String? avatarAsset;
  final int? badge;
  final bool locked;
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.card});

  final _DashboardCardData card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: card.onTap,
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                child: _CardIcon(card: card),
              ),
              PositionedDirectional(
                end: 0,
                top: 0,
                child: card.locked
                    ? const Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: Colors.white24,
                      )
                    : card.badge == null
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${card.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.title,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.subtitle,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  const _CardIcon({required this.card});

  final _DashboardCardData card;

  @override
  Widget build(BuildContext context) {
    final avatarAsset = card.avatarAsset;
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: card.color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: avatarAsset == null
          ? Icon(card.icon, color: card.color, size: 28)
          : Image.asset(avatarAsset, fit: BoxFit.cover),
    );
  }
}
