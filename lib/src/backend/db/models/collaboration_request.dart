class CollaborationRequest {
  final String id;
  final String projectId;
  final String projectName;
  final String invitedBy;
  final String? inviterDisplayName;
  final String? inviterUsername;
  final String? inviterAvatarUrl;
  final DateTime? createdAt;

  const CollaborationRequest({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.invitedBy,
    this.inviterDisplayName,
    this.inviterUsername,
    this.inviterAvatarUrl,
    this.createdAt,
  });

  String get resolvedInviterName {
    if (inviterDisplayName != null && inviterDisplayName!.trim().isNotEmpty) {
      return inviterDisplayName!.trim();
    }
    if (inviterUsername != null && inviterUsername!.trim().isNotEmpty) {
      return '@${inviterUsername!.trim()}';
    }
    return 'Someone';
  }
}
