import '../models/account_type.dart';
import '../models/profile_form.dart';
import 'package:flutter/material.dart';

final class SignupController extends ChangeNotifier {
  SignupController() {
    for (final controller in [
      displayName,
      email,
      phone,
      password,
      confirmPassword,
      otp,
      about,
      customSkill,
    ]) {
      controller.addListener(notifyListeners);
    }
  }

  static const totalSteps = 6;

  final pageController = PageController();

  int _step = 0;
  AccountType _userType = AccountType.engineer;
  String _specialization = 'مدني';
  String _governorate = 'بغداد';
  final Set<String> _skills = {'مدني'};

  final displayName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final otp = TextEditingController();
  final about = TextEditingController();
  final customSkill = TextEditingController();

  int get step => _step;

  double get progress => (_step + 1) / totalSteps;

  bool get isLastStep => _step == totalSteps - 1;

  AccountType get userType => _userType;

  String get specialization => _specialization;

  String get governorate => _governorate;

  Set<String> get skills => Set.unmodifiable(_skills);

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

  bool get hasValidIraqiPhone => isValidIraqiPhone(phone.text);

  bool get hasValidOtp => otp.text.trim() == '123456';

  bool get hasMatchingPasswords {
    return password.text.isNotEmpty && password.text == confirmPassword.text;
  }

  static bool isValidIraqiPhone(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll('-', '');
    return RegExp(r'^(?:\+964|00964|0)7[3-9]\d{8}$').hasMatch(normalized);
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

  void nextStep() {
    if (isLastStep) {
      return;
    }
    _step += 1;
    _animateToCurrentStep();
  }

  void previousStep() {
    if (_step == 0) {
      return;
    }
    _step -= 1;
    _animateToCurrentStep();
  }

  ProfileForm toProfile() {
    final parts = displayName.text.trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty ? '' : parts.first;
    final last = parts.length <= 1 ? '' : parts.skip(1).join(' ');

    return ProfileForm(
      email: email.text,
      firstName: first,
      lastName: last,
      headline: '${_userType.label} · $_specialization',
      location: _governorate,
      industry: _userType.label,
      company: _userType == AccountType.company ? displayName.text : '',
      role: _specialization,
      about: effectiveAbout,
      skills: effectiveSkills,
      languages: const {},
      openToWork: _userType != AccountType.company,
      profilePublic: true,
      jobAlerts: false,
    );
  }

  void _animateToCurrentStep() {
    notifyListeners();
    pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    displayName.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    otp.dispose();
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

const iraqiGovernorates = [
  'بغداد',
  'البصرة',
  'نينوى',
  'أربيل',
  'السليمانية',
  'دهوك',
  'كركوك',
  'ديالى',
  'الأنبار',
  'بابل',
  'كربلاء',
  'النجف',
  'واسط',
  'صلاح الدين',
  'ذي قار',
  'ميسان',
  'المثنى',
  'القادسية',
];
