class Project {
  final String id;
  final String projectName;
  final List<String> tags;
  final String? imageUrl;
  final String? userId;
  final DateTime? createdAt;
  final String? problemStatement;
  final int likes;

  const Project({
    required this.id,
    required this.projectName,
    required this.tags,
    this.imageUrl,
    this.userId,
    this.createdAt,
    this.problemStatement,
    this.likes = 0,
  });

  factory Project.fromMap(Map<String, dynamic> map) => Project(
    id: map['id']?.toString() ?? '',
    projectName: map['project_name']?.toString() ?? '',
    tags: map['tags'] is List
        ? (map['tags'] as List)
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
        : const [],
    imageUrl: map['project_image_url']?.toString(),
    userId: map['user_id']?.toString(),
    createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    problemStatement: map['problem_statement']?.toString(),
    likes: (map['likes'] as num?)?.toInt() ?? 0,
  );
}
