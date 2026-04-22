import 'package:intl/intl.dart';

class DesignChallenge {
  final String id;
  final String communityId;
  final String creatorId;
  final String type; // pattern_change | community_impact | build_and_create
  final String name;
  final String? prompt;
  final String? imageUrl;
  final String? scale;
  final String? difficulty;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final bool isPublished;
  final int budgetMin;
  final int? budgetMax; // null = no restriction
  final List<String> materials;
  final String? externalLink;
  final int requiredJournalEntries;
  final bool measurementRequired;
  final List<String> requiredMetrics;
  final List<String> requiredPatterns;
  final int minGroupMembers;
  final DateTime? createdAt;
  // Computed from join
  final int participantCount;
  final List<String> participantAvatars;

  const DesignChallenge({
    required this.id,
    required this.communityId,
    required this.creatorId,
    required this.type,
    required this.name,
    this.prompt,
    this.imageUrl,
    this.scale,
    this.difficulty,
    this.startsAt,
    this.endsAt,
    this.allDay = false,
    this.isPublished = false,
    this.budgetMin = 0,
    this.budgetMax,
    this.materials = const [],
    this.externalLink,
    this.requiredJournalEntries = 0,
    this.measurementRequired = false,
    this.requiredMetrics = const [],
    this.requiredPatterns = const [],
    this.minGroupMembers = 1,
    this.createdAt,
    this.participantCount = 0,
    this.participantAvatars = const [],
  });

  String get typeLabel {
    switch (type) {
      case 'pattern_change':
        return 'Pattern Change';
      case 'community_impact':
        return 'Community Impact';
      case 'build_and_create':
        return 'Build & Create';
      default:
        return type;
    }
  }

  String get dateRange {
    if (startsAt == null && endsAt == null) return '';
    final fmt = DateFormat('MMM d, yyyy');
    final fmtNoYear = DateFormat('MMM d');
    final s = startsAt;
    final e = endsAt;
    if (s != null && e != null) {
      final sameYear = s.year == e.year;
      return '${fmtNoYear.format(s)} to ${sameYear ? fmtNoYear.format(e) : fmt.format(e)}, ${e.year}';
    }
    if (s != null) return 'From ${fmt.format(s)}';
    if (e != null) return 'Until ${fmt.format(e)}';
    return '';
  }

  bool get isActive {
    final now = DateTime.now();
    final started = startsAt == null || now.isAfter(startsAt!);
    final notEnded = endsAt == null || now.isBefore(endsAt!);
    return isPublished && started && notEnded;
  }

  bool get isPast => endsAt != null && DateTime.now().isAfter(endsAt!);

  factory DesignChallenge.fromMap(Map<String, dynamic> map) {
    // Participant avatars from nested challenge_participants join
    final participantRows =
        map['challenge_participants'] as List<dynamic>? ?? [];
    final avatars = participantRows
        .map((row) {
          final profile = (row as Map<String, dynamic>)['profiles'];
          if (profile == null) return null;
          return (profile as Map<String, dynamic>)['avatar_url']?.toString();
        })
        .whereType<String>()
        .where((url) => url.trim().isNotEmpty)
        .toList();

    return DesignChallenge(
      id: map['id']?.toString() ?? '',
      communityId: map['community_id']?.toString() ?? '',
      creatorId: map['creator_id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'build_and_create',
      name: map['name']?.toString() ?? '',
      prompt: map['prompt']?.toString(),
      imageUrl: map['image_url']?.toString(),
      scale: map['scale']?.toString(),
      difficulty: map['difficulty']?.toString(),
      startsAt: DateTime.tryParse(map['starts_at']?.toString() ?? ''),
      endsAt: DateTime.tryParse(map['ends_at']?.toString() ?? ''),
      allDay: map['all_day'] == true,
      isPublished: map['is_published'] == true,
      budgetMin: (map['budget_min'] as num?)?.toInt() ?? 0,
      budgetMax: (map['budget_max'] as num?)?.toInt(),
      materials: _parseStringList(map['materials']),
      externalLink: map['external_link']?.toString(),
      requiredJournalEntries:
          (map['required_journal_entries'] as num?)?.toInt() ?? 0,
      measurementRequired: map['measurement_required'] == true,
      requiredMetrics: _parseStringList(map['required_metrics']),
      requiredPatterns: _parseStringList(map['required_patterns']),
      minGroupMembers: (map['min_group_members'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      participantCount: participantRows.length,
      participantAvatars: avatars,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
