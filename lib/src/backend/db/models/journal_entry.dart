class JournalEntry {
  final String id;
  final String title;
  final List<dynamic> content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String projectId;
  final String? progress;
  final List<String> tags;
  final String? authorId;
  final String? authorAvatarUrl;
  final String? authorDisplayName;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.projectId,
    this.createdAt,
    this.updatedAt,
    this.progress,
    this.tags = const [],
    this.authorId,
    this.authorAvatarUrl,
    this.authorDisplayName,
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return JournalEntry(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content'] is List ? map['content'] as List<dynamic> : const [],
      projectId: map['project_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
      progress: map['progress']?.toString(),
      tags: map['tags'] is List
          ? List<String>.from((map['tags'] as List).map((t) => t.toString()))
          : const [],
      authorId: map['user_id']?.toString(),
      authorAvatarUrl: profile?['avatar_url']?.toString(),
      authorDisplayName: profile?['display_name']?.toString() ?? profile?['username']?.toString(),
    );
  }
}
