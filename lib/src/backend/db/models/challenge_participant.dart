class ChallengeParticipant {
  final String id;
  final String challengeId;
  final String userId;
  final String? projectId;
  final bool hasSubmitted;
  final DateTime? submittedAt;
  final DateTime? joinedAt;
  // Resolved from profiles join
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  // Resolved from projects join
  final String? projectName;

  const ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.projectId,
    this.hasSubmitted = false,
    this.submittedAt,
    this.joinedAt,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.projectName,
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

  factory ChallengeParticipant.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    final project = map['projects'] as Map<String, dynamic>? ?? {};
    return ChallengeParticipant(
      id: map['id']?.toString() ?? '',
      challengeId: map['challenge_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      projectId: map['project_id']?.toString(),
      hasSubmitted: map['has_submitted'] == true,
      submittedAt: DateTime.tryParse(map['submitted_at']?.toString() ?? ''),
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? ''),
      displayName: profile['display_name']?.toString(),
      username: profile['username']?.toString(),
      avatarUrl: profile['avatar_url']?.toString(),
      projectName: project['project_name']?.toString(),
    );
  }
}
