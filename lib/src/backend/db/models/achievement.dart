class Achievement {
  final String id;
  final String userId;
  final String title;
  final int points;
  final String? category;
  final DateTime? occurredAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.title,
    this.points = 0,
    this.category,
    this.occurredAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    id: map['id']?.toString() ?? '',
    userId: map['user_id']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    points: (map['points'] as num?)?.toInt() ?? 0,
    category: map['category']?.toString(),
    occurredAt: DateTime.tryParse(map['occurred_at']?.toString() ?? ''),
  );
}
