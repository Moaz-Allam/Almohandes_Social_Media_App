import 'package:flutter/widgets.dart';

import '../models/profile_form.dart';

enum SignupAccountType { engineer, company }

extension SignupAccountTypeLabel on SignupAccountType {
  String get label {
    return switch (this) {
      SignupAccountType.engineer => 'مهندس',
      SignupAccountType.company => 'شركة',
    };
  }
}

final class SignupController extends ChangeNotifier {
  SignupController() {
    for (final controller in [fullName, companyName, specialization, country]) {
      controller.addListener(notifyListeners);
    }
  }

  static const totalSteps = 3;

  final pageController = PageController();

  SignupAccountType _accountType = SignupAccountType.engineer;
  int _step = 0;

  final fullName = TextEditingController(text: 'ريم حسن');
  final email = TextEditingController();
  final password = TextEditingController();
  final specialization = TextEditingController(text: 'Frontend');
  String experienceLevel = 'Student';
  final github = TextEditingController();
  final linkedIn = TextEditingController();
  final portfolio = TextEditingController();
  final bio = TextEditingController();
  bool resumeUploaded = false;

  final companyName = TextEditingController(text: 'Nile Labs');
  final workEmail = TextEditingController();
  final industry = TextEditingController(text: 'Software');
  String companySize = '1-10';
  final country = TextEditingController(text: 'Egypt');
  final website = TextEditingController();
  final companyLinkedIn = TextEditingController();
  bool logoUploaded = false;
  final shortDescription = TextEditingController();

  final Set<String> _skills = {'React', 'Python', 'Docker'};

  SignupAccountType get accountType => _accountType;

  int get step => _step;

  double get progress => (_step + 1) / totalSteps;

  bool get isLastStep => _step == totalSteps - 1;

  String get currentStepLabel => 'الخطوة ${_step + 1} من $totalSteps';

  Set<String> get skills => Set.unmodifiable(_skills);

  void setAccountType(SignupAccountType value) {
    if (_accountType == value) {
      return;
    }
    _accountType = value;
    notifyListeners();
  }

  void setSpecialization(String value) {
    specialization.text = value;
    notifyListeners();
  }

  void setExperienceLevel(String value) {
    experienceLevel = value;
    notifyListeners();
  }

  void setCompanySize(String value) {
    companySize = value;
    notifyListeners();
  }

  void setResumeUploaded(bool value) {
    resumeUploaded = value;
    notifyListeners();
  }

  void setLogoUploaded(bool value) {
    logoUploaded = value;
    notifyListeners();
  }

  void toggleSkill(String value) {
    if (_skills.contains(value)) {
      _skills.remove(value);
    } else {
      _skills.add(value);
    }
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
    if (_accountType == SignupAccountType.company) {
      return ProfileForm(
        email: workEmail.text,
        firstName: companyName.text,
        lastName: '',
        headline: 'شركة تنشئ مشاريع هندسية',
        location: country.text,
        industry: industry.text,
        company: companyName.text,
        role: 'Company',
        about: shortDescription.text,
        skills: const {},
        languages: const {},
        openToWork: false,
        profilePublic: true,
        jobAlerts: false,
      );
    }

    final parts = fullName.text.trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty ? '' : parts.first;
    final last = parts.length <= 1 ? '' : parts.skip(1).join(' ');

    return ProfileForm(
      email: email.text,
      firstName: first,
      lastName: last,
      headline: '${specialization.text} · $experienceLevel',
      location: 'منصة المهندس',
      industry: 'Engineering',
      company: '',
      role: specialization.text,
      about: bio.text,
      skills: Set.unmodifiable(_skills),
      languages: const {},
      openToWork: true,
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
    fullName.dispose();
    email.dispose();
    password.dispose();
    specialization.dispose();
    github.dispose();
    linkedIn.dispose();
    portfolio.dispose();
    bio.dispose();
    companyName.dispose();
    workEmail.dispose();
    industry.dispose();
    country.dispose();
    website.dispose();
    companyLinkedIn.dispose();
    shortDescription.dispose();
    super.dispose();
  }
}
