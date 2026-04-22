import 'package:juniper_journal/src/features/project/utils/eco_points_calculator.dart';

class ImpactEntry {
  final String id;
  final String projectId;
  final String title;
  final String metric;
  final String impactScale;
  final String patternType;
  final String evidenceType;
  final String confidenceScore;
  final double? measurement;
  final String? measurementUnit;
  final double ecoPoints;
  final String? linkedJournalEntryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ImpactEntry({
    required this.id,
    required this.projectId,
    required this.title,
    required this.metric,
    required this.impactScale,
    required this.patternType,
    required this.evidenceType,
    required this.confidenceScore,
    this.measurement,
    this.measurementUnit,
    required this.ecoPoints,
    this.linkedJournalEntryId,
    this.createdAt,
    this.updatedAt,
  });

  factory ImpactEntry.fromMap(Map<String, dynamic> map) => ImpactEntry(
        id: map['id']?.toString() ?? '',
        projectId: map['project_id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        metric: map['metric']?.toString() ?? '',
        impactScale: map['impact_scale']?.toString() ?? '',
        patternType: map['pattern_type']?.toString() ?? '',
        evidenceType: map['evidence_type']?.toString() ?? '',
        confidenceScore: map['confidence_score']?.toString() ?? '',
        measurement: map['measurement'] != null
            ? (map['measurement'] as num).toDouble()
            : null,
        measurementUnit: map['measurement_unit']?.toString(),
        ecoPoints: calculateEcoPoints(
          impactScale: map['impact_scale']?.toString(),
          confidenceScore: map['confidence_score']?.toString(),
          measurement: map['measurement'] != null
              ? (map['measurement'] as num).toDouble()
              : null,
          measurementUnit: map['measurement_unit']?.toString(),
        ),
        linkedJournalEntryId:
            map['linked_journal_entry_id']?.toString(),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
      );
}
