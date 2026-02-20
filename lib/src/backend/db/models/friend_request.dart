class FriendRequest {
  final String requesterId;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final DateTime? createdAt;

  const FriendRequest({
    required this.requesterId,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map) => FriendRequest(
    requesterId: map['requester_id']?.toString() ?? '',
    displayName: map['display_name']?.toString(),
    username: map['username']?.toString(),
    avatarUrl: map['avatar_url']?.toString(),
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
  );
}
