import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tradeflow/app/linked_arabic_app.dart';
import 'package:tradeflow/core/constants/app_colors.dart';

void main() {
  testWidgets('Arabic onboarding opens the multi-step sign up flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    expect(find.text('ابحث واعثر على وظيفتك التالية'), findsOneWidget);
    expect(find.text('انضم الآن'), findsOneWidget);

    await tester.tap(find.text('انضم الآن'));
    await tester.pumpAndSettle();

    expect(find.text('إنشاء حسابك'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('saved login session opens the signed-in shell', (tester) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('القصص'), findsOneWidget);
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

    await tester.tap(find.text('يوظف').first);
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
    expect(find.text('الوظائف'), findsOneWidget);
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
    expect(find.text('استكشاف كل المحتوى'), findsOneWidget);

    await tester.ensureVisible(find.text('استكشاف كل المحتوى'));
    await tester.pump();
    await tester.tap(find.text('استكشاف كل المحتوى'));
    await tester.pumpAndSettle();

    expect(find.textContaining('كل محتوى'), findsOneWidget);
    expect(find.text('المنشورات'), findsWidgets);
    expect(find.text('الريلز'), findsWidgets);
    expect(find.text('المشاريع'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

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

  testWidgets('projects can be applied to and appear in saved profile content', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'session.signedIn': true});

    await tester.pumpWidget(const LinkedArabicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('مشاريع'));
    await tester.pumpAndSettle();

    expect(find.text('الترتيب: الأحدث'), findsOneWidget);
    expect(find.text('محرك مطابقة مشاريع بالذكاء الاصطناعي'), findsOneWidget);

    await tester.tap(find.text('تقديم').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'جاهز للمساهمة');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'لدي خبرة مناسبة في بناء تطبيقات Flutter وربط النماذج بالخدمات الخلفية.',
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
    await tester.tap(find.text('يوظف').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض الملف · الإعدادات'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('المحفوظات'));
    await tester.tap(find.text('المحفوظات'));
    await tester.pumpAndSettle();

    expect(find.text('محرك مطابقة مشاريع بالذكاء الاصطناعي'), findsWidgets);
  });
}
