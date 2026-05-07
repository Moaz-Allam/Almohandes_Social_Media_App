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
    ]) {
      controller.addListener(notifyListeners);
    }
  }

  static const totalSteps = 5;

  final pageController = PageController();

  int _step = 0;
  AccountType _userType = AccountType.engineer;
  String _specialization = 'مدني';
  String _governorate = 'بغداد';

  final displayName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final otp = TextEditingController();

  int get step => _step;

  double get progress => (_step + 1) / totalSteps;

  bool get isLastStep => _step == totalSteps - 1;

  AccountType get userType => _userType;

  String get specialization => _specialization;

  String get governorate => _governorate;

  List<String> get specializationOptions {
    return switch (_userType) {
      AccountType.engineer => engineerSpecializations,
      AccountType.company => companyActivities,
      AccountType.craftsman => craftsmanSpecializations,
      AccountType.worker => workerSpecializations,
      AccountType.equipment => equipmentTypes,
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
    notifyListeners();
  }

  void setSpecialization(String value) {
    _specialization = value;
    notifyListeners();
  }

  void setGovernorate(String value) {
    _governorate = value;
    notifyListeners();
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
      about: _userType.description,
      skills: {_specialization},
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
