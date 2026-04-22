class CommunityMember {
  final String memberId; // community_members.id
  final String userId;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final String role;
  final String status;

  const CommunityMember({
    required this.memberId,
    required this.userId,
    this.displayName,
    this.username,
    this.avatarUrl,
    required this.role,
    required this.status,
  });

  String get resolvedName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return '@${username!.trim()}';
    }
    return 'User';
  }

  factory CommunityMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    return CommunityMember(
      memberId: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      displayName: profile['display_name']?.toString(),
      username: profile['username']?.toString(),
      avatarUrl: profile['avatar_url']?.toString(),
      role: map['role']?.toString() ?? 'member',
      status: map['status']?.toString() ?? 'pending',
    );
  }
}
