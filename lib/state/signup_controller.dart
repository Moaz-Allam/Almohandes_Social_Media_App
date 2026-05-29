import 'package:flutter/material.dart';

import '../core/data/countries.dart';
import '../models/account_type.dart';
import '../models/profile_form.dart';

// `iraqiGovernorates` now lives next to the governorate slug mappers (single
// source of truth). Re-exported here so existing signup consumers keep their
// import unchanged.
export '../data/mappers/supabase_enum_mapper.dart' show iraqiGovernorates;

/// Holds state for the multi-screen signup wizard.
///
/// Flow: phone → OTP → password → name → account type → specialization →
/// governorate → bio/skills → submit. Each screen reads/writes the
/// controller's fields and pushes the next screen on its own. The
/// controller itself is just a ChangeNotifier — there is no PageView
/// driving navigation anymore.
final class SignupController extends ChangeNotifier {
  SignupController() {
    for (final controller in [
      firstName,
      lastName,
      phoneInput,
      password,
      confirmPassword,
      about,
      customSkill,
    ]) {
      controller.addListener(notifyListeners);
    }
  }

  Country _country = defaultCountry;
  AccountType _userType = AccountType.engineer;
  String _specialization = 'مدني';
  String _governorate = 'بغداد';
  final Set<String> _skills = {'مدني'};

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  // Local part of the phone, without the country dial code.
  final phoneInput = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final about = TextEditingController();
  final customSkill = TextEditingController();

  Country get country => _country;

  /// Full E.164 phone, e.g. "+9647712345678". Always recomputed from the
  /// current country dial code + the local digits the user has typed.
  String get fullPhone {
    final digits = phoneInput.text.trim();
    if (digits.isEmpty) {
      return '';
    }
    final normalized = digits.startsWith('0') ? digits.substring(1) : digits;
    return '${_country.dialCode}$normalized';
  }

  AccountType get userType => _userType;

  String get specialization => _specialization;

  String get governorate => _governorate;

  Set<String> get skills => Set.unmodifiable(_skills);

  String get fullName {
    final f = firstName.text.trim();
    final l = lastName.text.trim();
    if (f.isEmpty && l.isEmpty) {
      return '';
    }
    if (l.isEmpty) {
      return f;
    }
    if (f.isEmpty) {
      return l;
    }
    return '$f $l';
  }

  String get effectiveAbout {
    final value = about.text.trim();
    return value.isEmpty ? _userType.description : value;
  }

  Set<String> get effectiveSkills {
    if (_skills.isEmpty) {
      return {_specialization};
    }
    return Set.unmodifiable(_skills);
  }

  List<String> get suggestedSkills {
    return {
      _specialization,
      ...specializationOptions,
      ..._skills,
    }.toList(growable: false);
  }

  List<String> get specializationOptions {
    return switch (_userType) {
      AccountType.engineer => engineerSpecializations,
      AccountType.company => companyActivities,
      AccountType.craftsman => craftsmanSpecializations,
      AccountType.worker => workerSpecializations,
      AccountType.equipment => equipmentTypes,
      AccountType.admin => engineerSpecializations,
    };
  }

  bool get hasValidPhoneNumber {
    final value = phoneInput.text.trim();
    return value.length >= 7 && RegExp(r'^\d+$').hasMatch(value);
  }

  bool get hasMatchingPasswords {
    return password.text.length >= 6 && password.text == confirmPassword.text;
  }

  /// Used by the legacy phone-validation widget test. Accepts the same
  /// local + E.164 patterns the wizard always supported (Iraq +964, Egypt
  /// +20). Anything else falls through to the country-picker entry path.
  static bool isSupportedPhoneNumber(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll('-', '');
    return RegExp(r'^(?:\+964|00964|0)7[3-9]\d{8}$').hasMatch(normalized) ||
        RegExp(r'^(?:\+20|0020|0)1[0125]\d{8}$').hasMatch(normalized);
  }

  void setCountry(Country value) {
    if (_country.code == value.code) {
      return;
    }
    _country = value;
    notifyListeners();
  }

  void setUserType(AccountType value) {
    if (_userType == value) {
      return;
    }
    _userType = value;
    _specialization = specializationOptions.first;
    _skills
      ..clear()
      ..add(_specialization);
    notifyListeners();
  }

  void setSpecialization(String value) {
    final previous = _specialization;
    _specialization = value;
    if (_skills.isEmpty || _skills.remove(previous)) {
      _skills.add(value);
    } else {
      _skills.add(value);
    }
    notifyListeners();
  }

  void setGovernorate(String value) {
    _governorate = value;
    notifyListeners();
  }

  void toggleSkill(String value) {
    if (_skills.contains(value)) {
      if (_skills.length > 1) {
        _skills.remove(value);
      }
    } else {
      _skills.add(value);
    }
    notifyListeners();
  }

  void addCustomSkill() {
    final values = customSkill.text
        .split(RegExp(r'[,،]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    var changed = false;
    for (final value in values) {
      changed = _skills.add(value) || changed;
    }
    customSkill.clear();
    if (changed) {
      notifyListeners();
    }
  }

  ProfileForm toProfile() {
    return ProfileForm(
      email: '',
      firstName: firstName.text.trim(),
      lastName: lastName.text.trim(),
      headline: '${_userType.label} · $_specialization',
      location: _governorate,
      industry: _userType.label,
      company: _userType == AccountType.company ? fullName : '',
      role: _specialization,
      about: effectiveAbout,
      skills: effectiveSkills,
      languages: const {},
      openToWork: _userType != AccountType.company,
      profilePublic: true,
      jobAlerts: false,
    );
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phoneInput.dispose();
    password.dispose();
    confirmPassword.dispose();
    about.dispose();
    customSkill.dispose();
    super.dispose();
  }
}

const engineerSpecializations = [
  'مدني',
  'معماري',
  'كهرباء',
  'ميكانيك',
  'مساحة',
  'حاسوب',
  'بيئي',
  'كيمياء',
  'نفط',
  'أخرى',
];

const companyActivities = ['مقاول', 'شركة بناء', 'أخرى'];

const craftsmanSpecializations = [
  'مبيضجي',
  'لباخ',
  'مبلط',
  'صباغ',
  'ميكانيكي',
  'فني تكييف وتبريد',
  'فني ألمنيوم',
  'فني طاقة شمسية',
  'فني تركيب كاميرات',
  'بناء طابوق',
  'كهربائي',
  'سباك',
  'نجار',
  'حداد',
  'أخرى',
];

const workerSpecializations = [
  'عامل بناء',
  'عامل تشييد',
  'عامل حفر',
  'عامل صب',
  'عامل تحميل',
  'عامل تسليح',
  'عامل طابوق',
  'عامل تنظيف موقع',
  'أخرى',
];

const equipmentTypes = [
  'شفل (حفارة)',
  'كرين (رافعة)',
  'دحالة (رول)',
  'بلدوزر',
  'شوكية',
  'تريلة',
  'خلاطة كونكريت',
  'شاحنة نقل',
  'صهريج',
  'مولدة كهرباء',
  'ضاغط هواء',
  'أخرى',
];

