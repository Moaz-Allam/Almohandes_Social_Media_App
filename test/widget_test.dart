import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tradeflow/app/linked_arabic_app.dart';
import 'package:tradeflow/core/constants/app_colors.dart';
import 'package:tradeflow/models/account_type.dart';

void main() {
  test('account type permissions match network and project rules', () {
    expect(AccountType.engineer.canPostProjects, isTrue);
    expect(AccountType.company.canPostProjects, isTrue);
    expect(AccountType.craftsman.canPostProjects, isFalse);
    expect(AccountType.worker.canPostProjects, isFalse);
    expect(AccountType.equipment.canPostProjects, isFalse);
    expect(accountTypeFromIndustry('شركة'), AccountType.company);
  });

  testWidgets('Arabic onboarding opens the multi-step sign up flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    expect(find.text('انضم إلى مشاريع هندسية حقيقية'), findsOneWidget);
    expect(find.text('انضم الآن'), findsOneWidget);
    expect(find.text('المتابعة بواسطة Apple'), findsNothing);

    await tester.tap(find.text('انضم الآن'));
    await tester.pumpAndSettle();

    expect(find.text('أساسيات الحساب'), findsOneWidget);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('07'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'reem@example.com');
    await tester.enterText(find.byType(TextField).at(2), '07712345678');
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.ensureVisible(find.text('متابعة'));
    await tester.pump();
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();

    expect(find.text('تأكيد رقم الهاتف'), findsOneWidget);
    expect(find.text('رمز التحقق OTP'), findsOneWidget);
  });

  testWidgets('saved login session opens the signed-in shell', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('القصص'), findsOneWidget);
  });

  testWidgets('settings toggles dark mode immediately', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-menu-avatar')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.text('الوضع الداكن'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('الإعدادات'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('الإعدادات'))).brightness,
      Brightness.dark,
    );
    expect(find.text('التطبيق يستخدم ألوانا داكنة'), findsOneWidget);
  });

  testWidgets('post like toggles primary color and reaction count', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    const likeKey = ValueKey('post-like-action-أحمد منصور');
    final likeAction = find.byKey(likeKey);

    expect(find.text('77'), findsOneWidget);
    expect(
      find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.thumb_up_alt_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(likeAction);
    await tester.pump();

    final likedIcon = tester.widget<Icon>(
      find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.thumb_up_alt),
      ),
    );
    expect(find.text('78'), findsOneWidget);
    expect(likedIcon.color, AppColors.blue);

    await tester.tap(likeAction);
    await tester.pump();

    final unlikedIcon = tester.widget<Icon>(
      find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.thumb_up_alt_outlined),
      ),
    );
    expect(find.text('77'), findsOneWidget);
    expect(unlikedIcon.color, AppColors.muted);
  });

  testWidgets('reels tab and simplified drawer notifications are visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ريلز'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ناتالي منصور'), findsOneWidget);
    expect(find.text('18K'), findsOneWidget);

    expect(find.byType(LinearProgressIndicator), findsWidgets);

    await tester.tap(find.byIcon(Icons.mode_comment_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('الأكثر صلة'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(PageView), const Offset(0, -520));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ريم حسن'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-menu-avatar')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('آخر الإشعارات'), findsOneWidget);
    expect(find.text('مجتمع مصممي المنتجات'), findsNothing);

    await tester.tap(find.text('عرض كل الإشعارات'));
    await tester.pumpAndSettle();

    expect(
      find.text('ناتاليا شوستاك و 2,486 آخرون تفاعلوا مع منشورك'),
      findsOneWidget,
    );
  });

  testWidgets('search and chat detail screens are reachable', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('بحث'));
    await tester.pumpAndSettle();

    expect(find.text('الأشخاص'), findsOneWidget);
    expect(find.text('المشاريع'), findsOneWidget);
    expect(find.text('المنشورات'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chat_bubble));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أندرو مارتن'));
    await tester.pumpAndSettle();

    expect(find.text('اكتب رسالة...'), findsOneWidget);
  });

  testWidgets('network invitations and profiles are reachable', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('شبكتي'));
    await tester.pumpAndSettle();

    expect(find.text('إدارة شبكتي'), findsNothing);

    await tester.tap(find.text('الدعوات'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsWidgets);
    expect(find.byIcon(Icons.close), findsWidgets);

    await tester.tap(find.text('سلمى فتحي').first);
    await tester.pumpAndSettle();

    expect(find.text('تواصل'), findsOneWidget);
    expect(find.text('متابعة'), findsOneWidget);
    expect(find.text('متاح لـ'), findsNothing);
    expect(find.text('إضافة قسم'), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('المنشورات'), findsOneWidget);
    expect(find.text('نبذة'), findsOneWidget);
    expect(find.text('المشاريع'), findsOneWidget);
    expect(find.byTooltip('شبكة'), findsOneWidget);
    expect(find.text('استكشاف كل المحتوى'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-post-card-0')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('profile-post-card-0')));
    await tester.pumpAndSettle();

    expect(find.text('المنشور'), findsOneWidget);
    expect(find.text('التعليقات'), findsOneWidget);
    expect(find.text('إعجاب'), findsOneWidget);
    expect(find.text('تعليق'), findsOneWidget);
    expect(find.text('إعادة نشر'), findsOneWidget);
    expect(find.text('إرسال'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('المشاريع'));
    await tester.pump();
    await tester.tap(find.text('المشاريع'));
    await tester.pumpAndSettle();

    expect(find.textContaining('مشروع تعاوني نشره'), findsOneWidget);

    await tester.ensureVisible(find.text('تواصل'));
    await tester.pump();
    await tester.tap(find.text('تواصل'));
    await tester.pumpAndSettle();

    expect(find.text('قيد الانتظار'), findsOneWidget);
    expect(find.text('الخبرة'), findsOneWidget);
  });

  testWidgets('stories comments and repost confirmation work', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('القصص'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('story-viewer')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('تعليق').first);
    await tester.pump();
    await tester.tap(find.text('تعليق').first);
    await tester.pumpAndSettle();

    expect(find.text('الأكثر صلة'), findsOneWidget);
    expect(find.text('أضف تعليقا...'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إعادة نشر').first);
    await tester.pumpAndSettle();

    expect(find.text('تأكيد إعادة النشر'), findsOneWidget);
  });

  testWidgets('send post opens contact picker and chat', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('إرسال').first);
    await tester.pump();
    await tester.tap(find.text('إرسال').first);
    await tester.pumpAndSettle();

    expect(find.text('إرسال إلى'), findsOneWidget);

    await tester.tap(find.text('أندرو مارتن'));
    await tester.pumpAndSettle();

    expect(find.text('اكتب رسالة...'), findsOneWidget);
  });

  testWidgets('premium entry opens courses dashboard and playlists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-menu-avatar')).first);
    await tester.pumpAndSettle();

    expect(find.text('الوصول إلى Premium'), findsOneWidget);

    await tester.tap(find.text('الوصول إلى Premium'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('تم تفعيل Premium بنجاح'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('لوحة Premium'), findsOneWidget);
    expect(find.text('مكتبة الدورات'), findsOneWidget);
    expect(find.text('إدارة المشاريع الإنشائية'), findsOneWidget);

    await tester.tap(find.text('إدارة المشاريع الإنشائية'));
    await tester.pumpAndSettle();

    expect(find.text('قوائم التشغيل'), findsOneWidget);
    expect(find.text('تخطيط المشروع'), findsOneWidget);
    expect(find.text('قراءة متطلبات المشروع'), findsOneWidget);
  });

  testWidgets('composer project flow is reachable', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('نشر'));
    await tester.pumpAndSettle();

    expect(find.text('إضافة صورة'), findsOneWidget);
    expect(find.text('إضافة ريل'), findsOneWidget);
    expect(find.text('إضافة مشروع'), findsOneWidget);
    expect(find.text('تصوير فيديو'), findsNothing);

    await tester.tap(find.text('إضافة مشروع'));
    await tester.pumpAndSettle();

    expect(find.text('مشاركة مشروع'), findsOneWidget);
    expect(find.text('1. أساسيات المشروع'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'منصة فرص');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'تجربة تساعد الباحثين عن عمل',
    );
    await tester.tap(find.text('التالي').last);
    await tester.pumpAndSettle();

    expect(find.text('2. نظرة عامة على المشروع'), findsOneWidget);
  });

  testWidgets(
    'projects can be applied to and appear in saved profile content',
    (tester) async {
      SharedPreferences.setMockInitialValues({'session.signedIn': true});

      await tester.pumpWidget(const LinkedArabicApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('مشاريع'));
      await tester.pumpAndSettle();

      expect(find.text('الترتيب: الأحدث'), findsOneWidget);
      expect(find.text('تنفيذ هيكل مدرسة في بغداد'), findsOneWidget);

      await tester.tap(find.text('تقديم').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'جاهز للمساهمة');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'لدي خبرة مناسبة في متابعة تنفيذ المواقع وتنسيق الفريق حتى التسليم.',
      );
      await tester.tap(find.text('رفع ملفات للتقديم'));
      await tester.pump();
      await tester.tap(find.text('إرسال التقديم'));
      await tester.pumpAndSettle();

      expect(find.text('تم إرسال طلبك بنجاح'), findsOneWidget);

      await tester.tap(find.text('العودة إلى المشاريع'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('الرئيسية'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-menu-avatar')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('عرض الملف · الإعدادات'));
      await tester.pumpAndSettle();

      expect(find.text('المنشورات'), findsOneWidget);
      expect(find.text('نبذة'), findsOneWidget);
      expect(find.text('المحفوظات'), findsOneWidget);
      expect(find.text('الأعمال'), findsNothing);
      expect(find.text('البرامج والتطبيقات'), findsNothing);
      expect(find.byTooltip('شبكة'), findsOneWidget);

      await tester.ensureVisible(find.text('المحفوظات'));
      await tester.tap(find.text('المحفوظات'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('شبكة'), findsNothing);
      expect(find.text('تنفيذ هيكل مدرسة في بغداد'), findsWidgets);
    },
  );
}
