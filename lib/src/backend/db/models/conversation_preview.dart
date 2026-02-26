class ConversationPreview {
  final String conversationId;
  final String otherUserId;
  final String? otherDisplayName;
  final String? otherUsername;
  final String? otherAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime? myDeletedAt;

  const ConversationPreview({
    required this.conversationId,
    required this.otherUserId,
    this.otherDisplayName,
    this.otherUsername,
    this.otherAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.myDeletedAt,
  });

  factory ConversationPreview.fromMap(Map<String, dynamic> map) =>
      ConversationPreview(
        conversationId: map['conversation_id']?.toString() ?? '',
        otherUserId: map['other_user_id']?.toString() ?? '',
        otherDisplayName: map['other_display_name']?.toString(),
        otherUsername: map['other_username']?.toString(),
        otherAvatarUrl: map['other_avatar_url']?.toString(),
        lastMessage: map['last_message']?.toString(),
        lastMessageAt: map['last_message_at'] != null
            ? DateTime.parse(map['last_message_at'].toString())
            : null,
        unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
        myDeletedAt: map['my_deleted_at'] != null
            ? DateTime.parse(map['my_deleted_at'].toString())
            : null,
      );
}
