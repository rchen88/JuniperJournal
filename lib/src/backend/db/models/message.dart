class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id']?.toString() ?? '',
    conversationId: map['conversation_id']?.toString() ?? '',
    senderId: map['sender_id']?.toString() ?? '',
    content: map['content']?.toString() ?? '',
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'].toString())
        : DateTime.now(),
    readAt: map['read_at'] != null
        ? DateTime.parse(map['read_at'].toString())
        : null,
  );
}
