import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juniper_journal/src/backend/db/models/impact_entry.dart';
import 'package:juniper_journal/src/backend/db/models/journal_entry.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/project/utils/eco_points_calculator.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/shared/widgets/pill_selector.dart';
import 'package:juniper_journal/src/shared/widgets/top_snack_bar.dart';

// ── Option lists ──────────────────────────────────────────────────────────────

const _metrics = [
  'Biological Growth',
  'Energy',
  'Education',
  'Waste',
  'Water',
];

const _scales = [
  'Seed (Very Small)',
  'Sapling (Small)',
  'Grove (Moderate)',
  'Forest (Large)',
  'Watershed (Very Large)',
];

const _evidenceTypes = [
  'Photo',
  'Measurement',
  'Calculation Estimate',
];

const _confidenceScores = ['Low', 'Medium', 'High'];

/// Valid metric → pattern → measurement unit combinations.
/// Patterns and units cascade from this map only.
const _combinations = {
  'Energy': {
    'Reduction': ['kWh'],
    'Substitution': ['kWh'],
    'Behavior Change': ['people', 'units'],
  },
  'Waste': {
    'Reduction': ['kg', 'units'],
    'Substitution': ['kg', 'units'],
    'Behavior Change': ['people', 'units'],
    'Capacity Building': ['people'],
  },
  'Water': {
    'Reduction': ['kg'],
    'Substitution': ['kg'],
    'Behavior Change': ['people', 'kg'],
    'Regeneration': ['sq.ft', 'kg'],
  },
  'Biological Growth': {
    'Regeneration': ['sq.ft', 'units'],
    'Behavior Change': ['people'],
    'Capacity Building': ['people'],
  },
  'Education': {
    'Capacity Building': ['people'],
    'Behavior Change': ['people'],
    'Substitution': ['people'],
  },
};

// ── Screen ────────────────────────────────────────────────────────────────────

class ImpactEntryFormScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final String? initialTitle;
  final ImpactEntry? existing;
  final bool readOnly;

  const ImpactEntryFormScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.initialTitle,
    this.existing,
    this.readOnly = false,
  });

  @override
  State<ImpactEntryFormScreen> createState() => _ImpactEntryFormScreenState();
}

class _ImpactEntryFormScreenState extends State<ImpactEntryFormScreen> {
  final _repo = ProjectsRepo();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _measurementCtrl;

  String? _metric;
  String? _patternType;
  String? _impactScale;
  String? _evidenceType;
  String? _confidenceScore;
  String? _measurementUnit;
  String? _linkedJournalEntryId;

  List<JournalEntry> _journalEntries = const [];
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  List<String> get _validPatterns =>
      _metric == null ? [] : List<String>.from(_combinations[_metric]!.keys);

  List<String> get _validUnits =>
      (_metric == null || _patternType == null)
          ? []
          : List<String>.from(
              (_combinations[_metric]?[_patternType]) ?? const []);

  double get _ecoPoints => calculateEcoPoints(
        impactScale: _impactScale,
        confidenceScore: _confidenceScore,
        measurement: double.tryParse(_measurementCtrl.text),
        measurementUnit: _measurementUnit,
      );

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(
        text: e?.title ?? widget.initialTitle ?? '');
    _titleCtrl.addListener(() => setState(() {}));
    _measurementCtrl =
        TextEditingController(text: e?.measurement?.toString() ?? '');
    _measurementCtrl.addListener(() => setState(() {}));

    _metric = e?.metric;
    _patternType = e?.patternType;
    _impactScale = e?.impactScale;
    _evidenceType = e?.evidenceType;
    _confidenceScore = e?.confidenceScore;
    _measurementUnit = e?.measurementUnit;
    _linkedJournalEntryId = e?.linkedJournalEntryId;

    _loadJournalEntries();
  }

  Future<void> _loadJournalEntries() async {
    final entries =
        await _repo.getJournalEntries(projectId: widget.projectId);
    if (!mounted) return;
    setState(() {
      _journalEntries = entries ?? const [];
      // Default to most recent entry if none pre-selected
      if (_linkedJournalEntryId == null && _journalEntries.isNotEmpty) {
        _linkedJournalEntryId = _journalEntries.first.id;
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _measurementCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _missingFields.isEmpty;

  List<String> get _missingFields {
    final missing = <String>[];
    if (_titleCtrl.text.trim().isEmpty) missing.add('Title');
    if (_metric == null) missing.add('Metric');
    if (_patternType == null) missing.add('Pattern Type');
    if (_impactScale == null) missing.add('Impact Scale');
    if (_evidenceType == null) missing.add('Evidence Type');
    if (_confidenceScore == null) missing.add('Confidence Score');
    if (_linkedJournalEntryId == null) missing.add('Link to Journal Log');
    return missing;
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSaving) return;
    setState(() => _isSaving = true);

    final measurement = double.tryParse(_measurementCtrl.text.trim());
    final pts = _ecoPoints;

    bool ok;
    if (_isEdit) {
      ok = await _repo.updateImpactEntry(
        entryId: widget.existing!.id,
        title: _titleCtrl.text.trim(),
        metric: _metric!,
        impactScale: _impactScale!,
        patternType: _patternType!,
        evidenceType: _evidenceType!,
        confidenceScore: _confidenceScore!,
        measurement: measurement,
        measurementUnit:
            measurement != null ? _measurementUnit : null,
        ecoPoints: pts,
        linkedJournalEntryId: _linkedJournalEntryId,
      );
    } else {
      final created = await _repo.createImpactEntry(
        projectId: widget.projectId,
        title: _titleCtrl.text.trim(),
        metric: _metric!,
        impactScale: _impactScale!,
        patternType: _patternType!,
        evidenceType: _evidenceType!,
        confidenceScore: _confidenceScore!,
        measurement: measurement,
        measurementUnit:
            measurement != null ? _measurementUnit : null,
        ecoPoints: pts,
        linkedJournalEntryId: _linkedJournalEntryId,
      );
      ok = created != null;
    }

    // Add metric as tag to linked journal entry
    if (ok && _linkedJournalEntryId != null) {
      await _repo.addTagToJournalEntry(
        journalEntryId: _linkedJournalEntryId!,
        tag: _metric!,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      showTopSnackBar(context, 'Failed to save impact entry', isError: true);
      return;
    }
    Navigator.of(context).pop();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              size: 18, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.readOnly
            ? Text(
                _titleCtrl.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              )
            : TextField(
                controller: _titleCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
        actions: widget.readOnly
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      'Read Only',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ]
            : null,
        shape: const Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.6)),
      ),
      body: AbsorbPointer(
        absorbing: widget.readOnly,
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Metric ──────────────────────────────────────────────────────
            _label('Metric'),
            const SizedBox(height: 6),
            PillSelector(
              value: _metric,
              placeholder: 'Select metric',
              items: _metrics,
              onChanged: (v) => setState(() {
                _metric = v;
                // Cascade: clear pattern if no longer valid for new metric
                if (_patternType != null &&
                    !(_combinations[v]?.containsKey(_patternType) ?? false)) {
                  _patternType = null;
                  _measurementUnit = null;
                } else if (_measurementUnit != null && _patternType != null) {
                  // Clear unit if no longer valid for metric+pattern combo
                  if (!(_combinations[v]?[_patternType]
                          ?.contains(_measurementUnit) ??
                      false)) {
                    _measurementUnit = null;
                  }
                }
              }),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 24),

            // ── Pattern + EcoPoints circle ───────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Pattern Type'),
                      const SizedBox(height: 6),
                      // Disabled (empty list) until metric is chosen
                      PillSelector(
                        value: _patternType,
                        placeholder:
                            _metric == null ? 'Select metric first' : 'Select',
                        items: _validPatterns,
                        onChanged: (v) => setState(() {
                          _patternType = v;
                          // Cascade: clear unit if no longer valid
                          if (_measurementUnit != null &&
                              !(_combinations[_metric]?[v]
                                      ?.contains(_measurementUnit) ??
                                  false)) {
                            _measurementUnit = null;
                          }
                          // Auto-select unit when only one option
                          final units =
                              _combinations[_metric]?[v] ?? const [];
                          if (units.length == 1) {
                            _measurementUnit = units.first;
                          }
                        }),
                      ),
                      const SizedBox(height: 20),
                      _label('Impact Scale'),
                      const SizedBox(height: 6),
                      // Disabled until pattern is chosen
                      PillSelector(
                        value: _impactScale,
                        placeholder: _patternType == null
                            ? 'Select pattern first'
                            : 'Select',
                        items: _patternType == null ? [] : _scales,
                        onChanged: (v) => setState(() => _impactScale = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _EcoPointsCircle(
                  metric: _metric,
                  ecoPoints: _ecoPoints,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Measurement ─────────────────────────────────────────────────
            _label('Measurement (Optional)'),
            const SizedBox(height: 6),
            // Locked until pattern is chosen (unit list drives valid units)
            AbsorbPointer(
              absorbing: _patternType == null,
              child: Opacity(
                opacity: _patternType == null ? 0.4 : 1.0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _measurementCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PillSelector(
                        value: _measurementUnit,
                        placeholder: 'Unit',
                        items: _validUnits,
                        onChanged: (v) =>
                            setState(() => _measurementUnit = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Confidence + Evidence ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Confidence Score'),
                      const SizedBox(height: 6),
                      PillSelector(
                        value: _confidenceScore,
                        placeholder: 'Select',
                        items: _confidenceScores,
                        onChanged: (v) => setState(() => _confidenceScore = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Evidence Type'),
                      const SizedBox(height: 6),
                      PillSelector(
                        value: _evidenceType,
                        placeholder: 'Select',
                        items: _evidenceTypes,
                        onChanged: (v) => setState(() => _evidenceType = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Link to Journal ──────────────────────────────────────────────
            _label('Link to Journal Log'),
            const SizedBox(height: 6),
            if (_journalEntries.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.orange.shade50,
                ),
                child: const Text(
                  'No journal entries yet — create one first.',
                  style: TextStyle(fontSize: 13, color: Colors.deepOrange),
                ),
              )
            else
              PillSelector(
                value: _journalEntries
                    .where((e) => e.id == _linkedJournalEntryId)
                    .map((e) => e.title.isNotEmpty ? e.title : 'Untitled Entry')
                    .firstOrNull,
                placeholder: 'None',
                items: _journalEntries
                    .map((e) => e.title.isNotEmpty ? e.title : 'Untitled Entry')
                    .toList(),
                onChanged: (title) {
                  final entry = _journalEntries.where((e) =>
                      (e.title.isNotEmpty ? e.title : 'Untitled Entry') ==
                      title).firstOrNull;
                  setState(() => _linkedJournalEntryId = entry?.id);
                },
              ),
            const SizedBox(height: 24),

            if (!widget.readOnly)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _canSubmit && !_isSaving ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'SAVE' : 'SUBMIT',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );
}

// ── EcoPoints circle ──────────────────────────────────────────────────────────

class _EcoPointsCircle extends StatelessWidget {
  const _EcoPointsCircle({required this.metric, required this.ecoPoints});
  final String? metric;
  final double ecoPoints;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              metric ?? '—',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              ecoPoints.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'EcoPoints',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

