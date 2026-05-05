final class ProfileForm {
  const ProfileForm({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.headline,
    required this.location,
    required this.industry,
    required this.company,
    required this.role,
    required this.about,
    required this.skills,
    required this.languages,
    required this.openToWork,
    required this.profilePublic,
    required this.jobAlerts,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String headline;
  final String location;
  final String industry;
  final String company;
  final String role;
  final String about;
  final Set<String> skills;
  final Set<String> languages;
  final bool openToWork;
  final bool profilePublic;
  final bool jobAlerts;

  String get fullName => '$firstName $lastName'.trim();
}
