import 'package:flutter/widgets.dart';

import '../models/profile_form.dart';

final class SignupController extends ChangeNotifier {
  SignupController() {
    for (final controller in [firstName, lastName, headline, location]) {
      controller.addListener(notifyListeners);
    }
  }

  static const totalSteps = 6;

  final pageController = PageController();

  final email = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController(text: 'ريم');
  final lastName = TextEditingController(text: 'حسن');
  final headline = TextEditingController(text: 'مصممة منتجات رقمية');
  final location = TextEditingController(text: 'القاهرة، مصر');
  final industry = TextEditingController(text: 'تكنولوجيا المعلومات والخدمات');
  final company = TextEditingController(text: 'Nile Labs');
  final role = TextEditingController(text: 'Product Designer');
  final experience = TextEditingController(
    text:
        'أقود تصميم تطبيقات B2B، وأعمل مع فرق المنتج والهندسة على تحسين رحلة المستخدم.',
  );
  final school = TextEditingController(text: 'جامعة القاهرة');
  final degree = TextEditingController(text: 'بكالوريوس نظم معلومات');
  final about = TextEditingController(
    text:
        'أبني منتجات سهلة الاستخدام، وأهتم بالبحث، قياس التجربة، وتصميم الأنظمة.',
  );
  final website = TextEditingController(text: 'portfolio.example.com');

  int _step = 0;
  bool _openToWork = true;
  bool _profilePublic = true;
  bool _jobAlerts = true;

  final Set<String> _skills = {'تصميم واجهات', 'Figma', 'بحث المستخدم'};
  final Set<String> _languages = {'العربية', 'الإنجليزية'};

  int get step => _step;

  double get progress => (_step + 1) / totalSteps;

  bool get openToWork => _openToWork;

  bool get profilePublic => _profilePublic;

  bool get jobAlerts => _jobAlerts;

  Set<String> get skills => Set.unmodifiable(_skills);

  Set<String> get languages => Set.unmodifiable(_languages);

  bool get isLastStep => _step == totalSteps - 1;

  String get currentStepLabel => 'الخطوة ${_step + 1} من $totalSteps';

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

  void setOpenToWork(bool value) {
    _openToWork = value;
    notifyListeners();
  }

  void setProfilePublic(bool value) {
    _profilePublic = value;
    notifyListeners();
  }

  void setJobAlerts(bool value) {
    _jobAlerts = value;
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

  void toggleLanguage(String value) {
    if (_languages.contains(value)) {
      _languages.remove(value);
    } else {
      _languages.add(value);
    }
    notifyListeners();
  }

  ProfileForm toProfile() {
    return ProfileForm(
      email: email.text,
      firstName: firstName.text,
      lastName: lastName.text,
      headline: headline.text,
      location: location.text,
      industry: industry.text,
      company: company.text,
      role: role.text,
      about: about.text,
      skills: Set.unmodifiable(_skills),
      languages: Set.unmodifiable(_languages),
      openToWork: _openToWork,
      profilePublic: _profilePublic,
      jobAlerts: _jobAlerts,
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
    email.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    headline.dispose();
    location.dispose();
    industry.dispose();
    company.dispose();
    role.dispose();
    experience.dispose();
    school.dispose();
    degree.dispose();
    about.dispose();
    website.dispose();
    super.dispose();
  }
}
