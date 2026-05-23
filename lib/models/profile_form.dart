final class ProfileForm {
  const ProfileForm({
    this.id,
    this.avatarUrl,
    this.coverUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.connectionsCount = 0,
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
  final String? coverUrl;
  final int followersCount;
  final int followingCount;
  final int connectionsCount;
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

  ProfileForm copyWith({
    String? id,
    String? avatarUrl,
    String? coverUrl,
    int? followersCount,
    int? followingCount,
    int? connectionsCount,
    int? postsCount,
    int? projectsCount,
    bool? isPremium,
    String? email,
    String? firstName,
    String? lastName,
    String? headline,
    String? location,
    String? industry,
    String? company,
    String? role,
    String? about,
    Set<String>? skills,
    Set<String>? languages,
    bool? openToWork,
    bool? profilePublic,
    bool? jobAlerts,
  }) {
    return ProfileForm(
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      connectionsCount: connectionsCount ?? this.connectionsCount,
      postsCount: postsCount ?? this.postsCount,
      projectsCount: projectsCount ?? this.projectsCount,
      isPremium: isPremium ?? this.isPremium,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      industry: industry ?? this.industry,
      company: company ?? this.company,
      role: role ?? this.role,
      about: about ?? this.about,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      openToWork: openToWork ?? this.openToWork,
      profilePublic: profilePublic ?? this.profilePublic,
      jobAlerts: jobAlerts ?? this.jobAlerts,
    );
  }
}
