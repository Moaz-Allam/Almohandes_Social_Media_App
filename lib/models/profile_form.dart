final class ProfileForm {
  const ProfileForm({
    this.id,
    this.avatarUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.projectsCount = 0,
    this.isPremium = false,
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

  final String? id;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int projectsCount;
  final bool isPremium;
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
