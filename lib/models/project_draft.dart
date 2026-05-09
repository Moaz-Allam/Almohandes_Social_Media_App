final class ProjectDraftData {
  const ProjectDraftData({
    required this.title,
    required this.tagline,
    required this.category,
    required this.projectType,
    required this.workMode,
    required this.location,
    required this.fullDescription,
    required this.problem,
    required this.goals,
    required this.audience,
    required this.stage,
    required this.assets,
    required this.requiredSkills,
    required this.preferredSkills,
    required this.techStack,
    required this.seniority,
    required this.years,
    required this.certifications,
    required this.engineersNeeded,
    required this.roles,
    required this.responsibilities,
    required this.currentTeamSize,
    required this.collaborationTools,
    required this.startDate,
    required this.duration,
    required this.weeklyCommitment,
    required this.milestones,
    required this.urgency,
    required this.paidStatus,
    required this.budgetRange,
    required this.paymentModel,
    required this.currency,
    required this.bonus,
    required this.attachmentsCount,
  });

  final String title;
  final String tagline;
  final String category;
  final String projectType;
  final String workMode;
  final String location;
  final String fullDescription;
  final String problem;
  final String goals;
  final String audience;
  final String stage;
  final Set<String> assets;
  final String requiredSkills;
  final String preferredSkills;
  final String techStack;
  final String seniority;
  final String years;
  final String certifications;
  final String engineersNeeded;
  final String roles;
  final String responsibilities;
  final String currentTeamSize;
  final Set<String> collaborationTools;
  final String startDate;
  final String duration;
  final String weeklyCommitment;
  final String milestones;
  final String urgency;
  final String paidStatus;
  final String budgetRange;
  final String paymentModel;
  final String currency;
  final String bonus;
  final int attachmentsCount;

  String get description =>
      fullDescription.trim().isEmpty ? tagline.trim() : fullDescription.trim();

  String get normalizedLocation =>
      location.trim().isEmpty ? 'بغداد' : location.trim();

  List<String> get assetList => assets.toList(growable: false);

  List<String> get requiredSkillList => _splitList(requiredSkills);

  List<String> get preferredSkillList => _splitList(preferredSkills);

  List<String> get techStackList => _splitList(techStack);

  List<String> get certificationList => _splitList(certifications);

  List<String> get roleList => _splitList(roles);

  List<String> get collaborationToolList =>
      collaborationTools.toList(growable: false);

  int get engineersNeededCount {
    final parsed = int.tryParse(engineersNeeded.trim());
    if (parsed == null || parsed <= 0) {
      return 1;
    }
    return parsed;
  }

  int? get yearsExperience {
    final match = RegExp(r'\d+').firstMatch(years);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  num? get budgetMin {
    final numbers = _numbersFromBudget();
    return numbers.isEmpty ? null : numbers.first;
  }

  num? get budgetMax {
    final numbers = _numbersFromBudget();
    if (numbers.length < 2) {
      return null;
    }
    return numbers[1];
  }

  String get normalizedCurrency {
    final value = currency.trim();
    return value.isEmpty ? 'IQD' : value.toUpperCase();
  }

  List<num> _numbersFromBudget() {
    return [
      for (final match in RegExp(r'\d+(?:[.,]\d+)?').allMatches(budgetRange))
        num.parse(match.group(0)!.replaceAll(',', '.')),
    ];
  }
}

List<String> _splitList(String value) {
  return value
      .split(RegExp(r'[,،\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
