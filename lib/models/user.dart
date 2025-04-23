class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final List<String> favoriteQuoteIds;
  final bool isDarkMode;
  final bool notificationsEnabled;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.favoriteQuoteIds = const [],
    this.isDarkMode = false,
    this.notificationsEnabled = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      favoriteQuoteIds: List<String>.from(json['favoriteQuoteIds'] ?? []),
      isDarkMode: json['isDarkMode'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'favoriteQuoteIds': favoriteQuoteIds,
      'isDarkMode': isDarkMode,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    List<String>? favoriteQuoteIds,
    bool? isDarkMode,
    bool? notificationsEnabled,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      favoriteQuoteIds: favoriteQuoteIds ?? this.favoriteQuoteIds,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
