class JournalEntry {
  final String id;
  final String title;
  final List<dynamic> content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String projectId;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.projectId,
    this.createdAt,
    this.updatedAt,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
    id: map['id']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    content: map['content'] is List ? map['content'] as List<dynamic> : const [],
    projectId: map['project_id']?.toString() ?? '',
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
  );
}
