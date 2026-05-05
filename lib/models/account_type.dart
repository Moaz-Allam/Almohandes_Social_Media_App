import 'package:flutter/material.dart';

import 'profile_form.dart';

enum AccountType { engineer, company, craftsman, worker, equipment }

extension AccountTypeInfo on AccountType {
  String get label {
    return switch (this) {
      AccountType.engineer => 'مهندس',
      AccountType.company => 'شركة',
      AccountType.craftsman => 'حرفي',
      AccountType.worker => 'عامل',
      AccountType.equipment => 'آليات',
    };
  }

  String get description {
    return switch (this) {
      AccountType.engineer => 'معماري، مدني، كهرباء...',
      AccountType.company => 'مقاولون وشركات البناء',
      AccountType.craftsman => 'نجار، حداد، صباغ',
      AccountType.worker => 'عمال البناء والتشييد',
      AccountType.equipment => 'شفل، كرين، حدادة...',
    };
  }

  IconData get icon {
    return switch (this) {
      AccountType.engineer => Icons.engineering,
      AccountType.company => Icons.business,
      AccountType.craftsman => Icons.handyman,
      AccountType.worker => Icons.construction,
      AccountType.equipment => Icons.local_shipping_outlined,
    };
  }

  String get specializationTitle {
    return switch (this) {
      AccountType.engineer => 'ما تخصصك؟',
      AccountType.company => 'اختر نوع نشاطك',
      AccountType.craftsman => 'ما حرفتك؟',
      AccountType.worker => 'ما نوع عملك؟',
      AccountType.equipment => 'نوع الآلية؟',
    };
  }

  String get specializationSubtitle {
    return switch (this) {
      AccountType.engineer => 'اختر تخصصك الهندسي',
      AccountType.company => 'اختر نشاط الشركة أو المقاول',
      AccountType.craftsman => 'اختر تخصصك',
      AccountType.worker => 'اختر مجال عملك',
      AccountType.equipment => 'اختر نوع الآلية التي تمتلكها',
    };
  }

  bool get canPostProjects {
    return this == AccountType.engineer || this == AccountType.company;
  }
}

AccountType accountTypeFromProfile(ProfileForm? profile) {
  return accountTypeFromIndustry(profile?.industry) ?? AccountType.engineer;
}

AccountType? accountTypeFromIndustry(String? industry) {
  final value = industry?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final type in AccountType.values) {
    if (type.label == value) {
      return type;
    }
  }
  return null;
}
