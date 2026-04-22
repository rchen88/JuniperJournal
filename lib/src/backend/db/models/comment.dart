class Comment {
  final String id;
  final String projectId;
  final String userId;
  final String? authorDisplayName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final DateTime? createdAt;

  const Comment({
    required this.id,
    required this.projectId,
    required this.userId,
    this.authorDisplayName,
    this.authorUsername,
    this.authorAvatarUrl,
    required this.content,
    this.createdAt,
  });

  String get resolvedAuthorName {
    if (authorDisplayName != null && authorDisplayName!.trim().isNotEmpty) {
      return authorDisplayName!.trim();
    }
    if (authorUsername != null && authorUsername!.trim().isNotEmpty) {
      return '@${authorUsername!.trim()}';
    }
    return 'User';
  }
}
