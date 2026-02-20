class UserProfile {
  final String id;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final bool isPublicProfile;

  const UserProfile({
    required this.id,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.isPublicProfile = true,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id']?.toString() ?? '',
    displayName: map['display_name']?.toString(),
    username: map['username']?.toString(),
    avatarUrl: map['avatar_url']?.toString(),
    isPublicProfile: map['is_public_profile'] as bool? ?? true,
  );
}
