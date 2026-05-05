import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/painters/card_pattern_painter.dart';
import '../../shared/widgets/app_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.name,
    required this.headline,
    required this.color,
    this.location = 'القاهرة، مصر',
    this.isMe = false,
    this.isConnectionRequest = false,
  });

  const ProfileScreen.me({super.key})
    : name = 'ريم حسن',
      headline = 'مصممة منتجات رقمية',
      color = AppColors.darkBlue,
      location = 'القاهرة، مصر',
      isMe = true,
      isConnectionRequest = false;

  final String name;
  final String headline;
  final Color color;
  final String location;
  final bool isMe;
  final bool isConnectionRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.ink,
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'رجوع',
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHero(
                    name: name,
                    headline: headline,
                    color: color,
                    location: location,
                    isMe: isMe,
                  ),
                  const Divider(
                    height: 10,
                    thickness: 10,
                    color: AppColors.soft,
                  ),
                  _ProfileSection(
                    title: 'النشاط',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMe ? '2,900 متابع' : '398 متابع',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isMe
                              ? 'شاركت مؤخرا منشورا عن تحسين تجربة التسجيل.'
                              : '$name ليس لديه منشورات حديثة',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ستظهر هنا أحدث المنشورات والتفاعلات المهنية.',
                          style: TextStyle(
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 10,
                    thickness: 10,
                    color: AppColors.soft,
                  ),
                  const _ProfileSection(
                    title: 'الخبرة',
                    child: Column(
                      children: [
                        _ExperienceRow(
                          iconColor: AppColors.blue,
                          title: 'مصمم منتجات',
                          company: 'Nile Labs · دوام كامل',
                          date: 'فبراير 2025 - الآن · سنة و4 أشهر',
                          place: 'القاهرة، مصر',
                        ),
                        Divider(height: 28),
                        _ExperienceRow(
                          iconColor: AppColors.darkBlue,
                          title: 'متطوع',
                          company: 'أهلا شباب · دوام جزئي',
                          date: 'أغسطس 2025 - الآن · 10 أشهر',
                          place: 'الإسكندرية، مصر',
                        ),
                        Divider(height: 28),
                        _ExperienceRow(
                          iconColor: AppColors.muted,
                          title: 'باحث تجربة مستخدم',
                          company: 'صناع الحياة · مستقل',
                          date: 'أبريل 2025 - الآن',
                          place: 'عن بعد',
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 10,
                    thickness: 10,
                    color: AppColors.soft,
                  ),
                  const _ProfileSection(
                    title: 'التعليم',
                    child: _ExperienceRow(
                      iconColor: AppColors.border,
                      title: 'جامعة القاهرة',
                      company: 'بكالوريوس نظم معلومات',
                      date: '2023 - 2027',
                      place: 'الدرجة: امتياز',
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatefulWidget {
  const _ProfileHero({
    required this.name,
    required this.headline,
    required this.color,
    required this.location,
    required this.isMe,
  });

  final String name;
  final String headline;
  final Color color;
  final String location;
  final bool isMe;

  @override
  State<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends State<_ProfileHero> {
  bool _connectionPending = false;

  void _requestConnection() {
    setState(() => _connectionPending = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال طلب التواصل إلى ${widget.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 92,
              child: CustomPaint(
                painter: CardPatternPainter(color: widget.color),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: .32),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            PositionedDirectional(
              top: 42,
              start: 18,
              child: AppAvatar(
                name: widget.name,
                radius: 58,
                color: widget.color,
                badge: isMe ? 'متاح' : null,
              ),
            ),
            if (isMe)
              PositionedDirectional(
                top: 18,
                end: 18,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.blue,
                      size: 18,
                    ),
                    tooltip: 'تعديل',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 74),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, height: 1.3),
              ),
              const SizedBox(height: 6),
              Text(
                widget.location,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                isMe ? '2,900 متابع · 1,300 اتصال' : '370 اتصال',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: isMe
                          ? () {}
                          : _connectionPending
                          ? null
                          : _requestConnection,
                      style: FilledButton.styleFrom(
                        backgroundColor: isMe || !_connectionPending
                            ? AppColors.blue
                            : AppColors.soft,
                        disabledBackgroundColor: AppColors.soft,
                        disabledForegroundColor: AppColors.muted,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        isMe
                            ? 'متاح لـ'
                            : _connectionPending
                            ? 'قيد الانتظار'
                            : 'تواصل',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue,
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: AppColors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(isMe ? 'إضافة قسم' : 'متابعة'),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz),
                      tooltip: 'المزيد',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ExperienceRow extends StatelessWidget {
  const _ExperienceRow({
    required this.iconColor,
    required this.title,
    required this.company,
    required this.date,
    required this.place,
  });

  final Color iconColor;
  final String title;
  final String company;
  final String date;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.business_center, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(company, style: const TextStyle(fontSize: 16)),
              Text(date, style: const TextStyle(color: AppColors.muted)),
              Text(place, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
