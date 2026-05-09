import '../../models/account_type.dart';

String accountTypeToSupabaseRole(AccountType type) {
  return switch (type) {
    AccountType.engineer => 'engineer',
    AccountType.company => 'contractor',
    AccountType.craftsman => 'craftsman',
    AccountType.worker => 'worker',
    AccountType.equipment => 'machinery',
    AccountType.admin => 'admin',
  };
}

AccountType accountTypeFromSupabaseRole(String? role) {
  return switch (role) {
    'engineer' => AccountType.engineer,
    'contractor' || 'company' || 'client' => AccountType.company,
    'craftsman' => AccountType.craftsman,
    'worker' => AccountType.worker,
    'machinery' || 'equipment' => AccountType.equipment,
    'admin' => AccountType.admin,
    _ => AccountType.engineer,
  };
}

String engineerSpecializationToSupabase(String value) {
  return switch (value) {
    'مدني' => 'civil',
    'معماري' => 'architectural',
    'كهرباء' => 'electrical',
    'ميكانيك' => 'mechanical',
    'كيمياء' => 'chemical',
    'بيئي' => 'environmental',
    'نفط' => 'petroleum',
    'حاسوب' => 'computer',
    'مساحة' => 'surveying',
    _ => 'other',
  };
}

String craftsmanSpecializationToSupabase(String value) {
  if (value.contains('لباخ')) return 'plastering';
  if (value.contains('نجار')) return 'carpentry';
  if (value.contains('حداد')) return 'blacksmith';
  if (value.contains('صباغ')) return 'painter';
  if (value.contains('سباك')) return 'plumber';
  if (value.contains('كهربائي')) return 'electrician';
  if (value.contains('تكييف')) return 'hvac';
  if (value.contains('ألمنيوم')) return 'aluminum';
  if (value.contains('طاقة')) return 'solar';
  if (value.contains('كاميرات')) return 'cameras';
  if (value.contains('طابوق')) return 'brick_mason';
  if (value.contains('صب')) return 'concrete_worker';
  if (value.contains('مبلط')) return 'tiling';
  if (value.contains('ميكانيكي')) return 'mechanic';
  return 'other';
}

String machinerySpecializationToSupabase(String value) {
  if (value.contains('شفل')) return 'excavator';
  if (value.contains('كرين')) return 'crane';
  if (value.contains('بلدوزر')) return 'bulldozer';
  if (value.contains('شوكية')) return 'forklift';
  if (value.contains('خلاطة')) return 'concrete_mixer';
  if (value.contains('شاحنة')) return 'truck';
  if (value.contains('صهريج')) return 'tanker';
  if (value.contains('مولدة')) return 'generator';
  if (value.contains('ضاغط')) return 'compressor';
  return 'other';
}

String governorateToSupabase(String value) {
  return switch (value) {
    'بغداد' => 'baghdad',
    'البصرة' => 'basra',
    'نينوى' => 'nineveh',
    'أربيل' => 'erbil',
    'السليمانية' => 'sulaymaniyah',
    'دهوك' => 'duhok',
    'كركوك' => 'kirkuk',
    'ديالى' => 'diyala',
    'الأنبار' => 'anbar',
    'بابل' => 'babylon',
    'كربلاء' => 'karbala',
    'النجف' => 'najaf',
    'واسط' => 'wasit',
    'صلاح الدين' => 'saladin',
    'ذي قار' => 'dhi_qar',
    'ميسان' => 'maysan',
    'المثنى' => 'muthanna',
    'القادسية' => 'qadisiyah',
    _ => 'baghdad',
  };
}

String governorateFromSupabase(String? value) {
  return switch (value) {
    'baghdad' => 'بغداد',
    'basra' => 'البصرة',
    'nineveh' => 'نينوى',
    'erbil' => 'أربيل',
    'sulaymaniyah' => 'السليمانية',
    'duhok' => 'دهوك',
    'kirkuk' => 'كركوك',
    'diyala' => 'ديالى',
    'anbar' => 'الأنبار',
    'babylon' => 'بابل',
    'karbala' => 'كربلاء',
    'najaf' => 'النجف',
    'wasit' => 'واسط',
    'saladin' => 'صلاح الدين',
    'dhi_qar' => 'ذي قار',
    'maysan' => 'ميسان',
    'muthanna' => 'المثنى',
    'qadisiyah' => 'القادسية',
    _ => value ?? 'بغداد',
  };
}
