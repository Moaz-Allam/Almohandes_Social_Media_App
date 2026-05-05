import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/premium_course.dart';

const _sampleVideoUrl =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

const premiumCourses = [
  PremiumCourse(
    id: 'site-management',
    title: 'إدارة المشاريع الإنشائية',
    subtitle: 'خطط العمل، الجداول، المخاطر، وتسليم المواقع باحتراف',
    instructor: 'م. علي الكعبي',
    icon: Icons.account_tree_outlined,
    color: AppColors.blue,
    progress: .72,
    playlists: [
      PremiumPlaylist(
        id: 'planning',
        title: 'تخطيط المشروع',
        description: 'بناء نطاق العمل وتقسيمه إلى مراحل قابلة للمتابعة.',
        videos: [
          PremiumVideo(
            id: 'planning-1',
            title: 'قراءة متطلبات المشروع',
            description: 'كيف تحول الطلبات العامة إلى نطاق هندسي واضح.',
            duration: Duration(minutes: 8, seconds: 20),
            videoUrl: _sampleVideoUrl,
            completed: true,
          ),
          PremiumVideo(
            id: 'planning-2',
            title: 'جدولة الأعمال الحرجة',
            description: 'تحديد المسار الحرج وتوزيع الموارد على الموقع.',
            duration: Duration(minutes: 11, seconds: 5),
            videoUrl: _sampleVideoUrl,
            completed: true,
          ),
        ],
      ),
      PremiumPlaylist(
        id: 'handover',
        title: 'التسليم والمتابعة',
        description: 'قوائم الفحص، التقارير اليومية، وإغلاق الملاحظات.',
        videos: [
          PremiumVideo(
            id: 'handover-1',
            title: 'قائمة فحص الاستلام',
            description: 'نموذج عملي لاستلام الأعمال قبل التسليم النهائي.',
            duration: Duration(minutes: 9, seconds: 40),
            videoUrl: _sampleVideoUrl,
            completed: true,
          ),
          PremiumVideo(
            id: 'handover-2',
            title: 'تقرير تقدم احترافي',
            description: 'طريقة كتابة تقرير مختصر وواضح للمالك والفريق.',
            duration: Duration(minutes: 7, seconds: 55),
            videoUrl: _sampleVideoUrl,
          ),
        ],
      ),
    ],
  ),
  PremiumCourse(
    id: 'bim-basics',
    title: 'BIM للمهندسين والمقاولين',
    subtitle: 'تنسيق النماذج، كشف التعارضات، وربط التصميم بالتنفيذ',
    instructor: 'م. سارة الجبوري',
    icon: Icons.view_in_ar_outlined,
    color: AppColors.darkBlue,
    progress: .38,
    playlists: [
      PremiumPlaylist(
        id: 'modeling',
        title: 'أساسيات النمذجة',
        description: 'بناء نموذج نظيف قابل للتنسيق مع باقي التخصصات.',
        videos: [
          PremiumVideo(
            id: 'modeling-1',
            title: 'تنظيم ملفات النموذج',
            description: 'هيكلة الملفات والطبقات قبل بدء العمل.',
            duration: Duration(minutes: 10, seconds: 15),
            videoUrl: _sampleVideoUrl,
            completed: true,
          ),
          PremiumVideo(
            id: 'modeling-2',
            title: 'إدارة التخصصات',
            description: 'ربط المعماري والمدني والكهرباء داخل نموذج واحد.',
            duration: Duration(minutes: 12, seconds: 30),
            videoUrl: _sampleVideoUrl,
          ),
        ],
      ),
      PremiumPlaylist(
        id: 'clash',
        title: 'كشف التعارضات',
        description: 'قراءة التعارضات وتحويلها إلى مهام قابلة للتنفيذ.',
        videos: [
          PremiumVideo(
            id: 'clash-1',
            title: 'تحليل تقرير التعارض',
            description: 'تمييز التعارض الحقيقي من التنبيه غير المهم.',
            duration: Duration(minutes: 9, seconds: 5),
            videoUrl: _sampleVideoUrl,
          ),
          PremiumVideo(
            id: 'clash-2',
            title: 'اجتماع تنسيق فعال',
            description: 'كيف تخرج من اجتماع BIM بقرارات تنفيذية واضحة.',
            duration: Duration(minutes: 8, seconds: 45),
            videoUrl: _sampleVideoUrl,
          ),
        ],
      ),
    ],
  ),
  PremiumCourse(
    id: 'site-safety',
    title: 'السلامة المهنية في مواقع البناء',
    subtitle: 'إدارة المخاطر اليومية وحماية الفريق والمعدات',
    instructor: 'م. نور الهاشمي',
    icon: Icons.health_and_safety_outlined,
    color: AppColors.black,
    progress: .18,
    playlists: [
      PremiumPlaylist(
        id: 'risk',
        title: 'تقييم المخاطر',
        description: 'رصد المخاطر قبل بدء الأعمال اليومية.',
        videos: [
          PremiumVideo(
            id: 'risk-1',
            title: 'جولة السلامة الصباحية',
            description: 'ما الذي يجب فحصه قبل تشغيل الموقع؟',
            duration: Duration(minutes: 6, seconds: 50),
            videoUrl: _sampleVideoUrl,
            completed: true,
          ),
          PremiumVideo(
            id: 'risk-2',
            title: 'تصنيف المخاطر',
            description: 'ترتيب المخاطر حسب الاحتمالية والتأثير.',
            duration: Duration(minutes: 8, seconds: 10),
            videoUrl: _sampleVideoUrl,
          ),
        ],
      ),
      PremiumPlaylist(
        id: 'equipment',
        title: 'سلامة المعدات',
        description: 'إجراءات تشغيل الرافعات والمعدات الثقيلة داخل الموقع.',
        videos: [
          PremiumVideo(
            id: 'equipment-1',
            title: 'فحص الرافعة قبل التشغيل',
            description: 'قائمة تحقق مختصرة للمشغل والمشرف.',
            duration: Duration(minutes: 7, seconds: 20),
            videoUrl: _sampleVideoUrl,
          ),
          PremiumVideo(
            id: 'equipment-2',
            title: 'منطقة عزل المعدات',
            description: 'تحديد مسارات آمنة للفريق أثناء التشغيل.',
            duration: Duration(minutes: 5, seconds: 45),
            videoUrl: _sampleVideoUrl,
          ),
        ],
      ),
    ],
  ),
];
